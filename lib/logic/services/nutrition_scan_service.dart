import 'dart:io';

import 'package:eat_beat_repeat/logic/models/scanned_nutrients.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// On-device nutrition label scanner — works on all platforms:
/// - Android / iOS  → Google ML Kit (fully offline, no API key)
/// - Windows        → Windows.Media.Ocr WinRT via PowerShell (built into Windows 10+)
///
/// Usage:
/// ```dart
/// final service = NutritionScanService();
/// final result = await service.scanFromGallery();
/// service.dispose();
/// ```
class NutritionScanService {
  final ImagePicker _picker = ImagePicker();

  /// True on Android and iOS where ML Kit is available.
  static bool get _useMlKit =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  // ML Kit recognizer is only created on mobile — null on desktop.
  late final TextRecognizer? _mlKitRecognizer = _useMlKit
      ? TextRecognizer(script: TextRecognitionScript.latin)
      : null;

  /// Opens the device camera (mobile only), runs OCR and returns nutrients.
  /// Returns `null` when the user cancels.
  Future<ScannedNutrients?> scanFromCamera() => _scan(ImageSource.camera);

  /// Opens the gallery / file picker, runs OCR and returns nutrients.
  /// Returns `null` when the user cancels.
  Future<ScannedNutrients?> scanFromGallery() => _scan(ImageSource.gallery);

  Future<ScannedNutrients?> _scan(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 90);
    if (file == null) return null;

    final String rawText;
    if (_useMlKit) {
      final inputImage = InputImage.fromFilePath(file.path);
      final recognized = await _mlKitRecognizer!.processImage(inputImage);
      rawText = recognized.text;
    } else if (Platform.isWindows) {
      rawText = await _scanViaWindowsOcr(file.path);
    } else {
      throw UnsupportedError('OCR ist auf dieser Plattform nicht verfügbar.');
    }

    debugPrint('[OCR] raw text:\n$rawText');
    return _parseLabel(rawText);
  }

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  ScannedNutrients _parseLabel(String rawText) {
    // Normalize: remove German thousands-separators (digit.digit.digit),
    // then convert decimal commas to dots, lowercase, trim lines.
    // e.g. "1.354 kJ" → "1354 kJ", "14,2 g" → "14.2 g"
    final normalized = rawText
        .replaceAllMapped(
          RegExp(r'(\d)\.(\d{3})(?!\d)'),
          (m) => '${m[1]}${m[2]}',
        )
        .replaceAll(',', '.')
        .toLowerCase();

    final lines = normalized
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    double? calories, protein, carbs, fat;

    // ── Calories: scan all lines for "X kcal", "X kj / Y", or "X / Y" ──
    final kcalRe = RegExp(r'(\d+\.?\d*)\s*kcal');
    // "745.6 kj/ 179.9" — number + kj text + / + number (second = kcal)
    final kjSlashRe = RegExp(r'(\d+\.?\d*)\s*kj\s*/\s*(\d+\.?\d*)');
    // "1527/360" — pure slash, smaller number is kcal
    final pureSlashRe = RegExp(r'^(\d+\.?\d*)\s*/\s*(\d+\.?\d*)$');
    for (int i = 0; i < lines.length; i++) {
      if (calories != null) break;
      final line = lines[i];
      // "179.9 kcal" or "320 kcal"
      final km = kcalRe.firstMatch(line);
      if (km != null) {
        calories = double.tryParse(km.group(1)!);
        break;
      }
      // "745.6 kj/ 179.9" → take second number as kcal
      final kjm = kjSlashRe.firstMatch(line);
      if (kjm != null) {
        calories = double.tryParse(kjm.group(2)!);
        break;
      }
      // "{number}" on this line + "kcal" on next line → that number is kcal
      if (i + 1 < lines.length && lines[i + 1] == 'kcal') {
        final nm = RegExp(r'(\d+\.?\d*)$').firstMatch(line);
        if (nm != null) {
          calories = double.tryParse(nm.group(1)!);
          break;
        }
      }
      // "1527/360" — pure slash, take smaller as kcal
      final pm = pureSlashRe.firstMatch(line);
      if (pm != null) {
        final a = double.tryParse(pm.group(1)!) ?? 0;
        final b = double.tryParse(pm.group(2)!) ?? 0;
        if (a > 0 && b > 0 && a != b) {
          final candidate = b < a ? b : a;
          if (candidate < 1200) {
            calories = candidate;
            break;
          }
        }
      }
    }

    // ── Strategy 2: inline / lookahead scan ──
    // Only run when serving-size comes AFTER the first keyword (Case A / inline).
    // For Case B (serving-size before keywords, e.g. Teigwaren), skip this
    // strategy so the split-table parser handles it correctly.
    final firstKwIdx = lines.indexWhere(_isNutrientKeyword);
    final servingSizeIdx = lines.indexWhere(_isServingSizeLine);
    final caseB =
        servingSizeIdx != -1 && firstKwIdx != -1 && servingSizeIdx < firstKwIdx;

    if (!caseB) {
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (_isSubRow(line) || _isServingSizeLine(line)) continue;

        double? findValue(int startIdx) {
          for (int j = startIdx; j < lines.length && j <= startIdx + 6; j++) {
            if (j != startIdx) {
              if (_isNutrientKeyword(lines[j]) && !_isSubRow(lines[j])) break;
              if (_isServingSizeLine(lines[j])) break;
            }
            final v = _gramsIn(lines[j]);
            if (v != null) return v;
          }
          return null;
        }

        if (protein == null && _isProteinKeyword(line)) {
          protein = findValue(i);
        }
        if (carbs == null && _isCarbsKeyword(line)) {
          carbs = findValue(i);
        }
        if (fat == null && _isFatKeyword(line)) {
          fat = findValue(i);
        }
      }
    }

    // ── Fallback: split-table (keyword block then value block) ──
    if (protein == null || carbs == null || fat == null) {
      _parseSplitTable(lines, (p, c, f) {
        protein ??= p;
        carbs ??= c;
        fat ??= f;
      });
    }

    // ── Positional EU-order fallback ──
    // Last resort: find all gram values after the serving-size line and
    // assign them in EU label order (Energy → Fat → ges.FS → Carbs → Sugar → Fibre → Protein).
    if (protein == null || carbs == null || fat == null) {
      _parseByEuOrder(lines, (p, c, f) {
        protein ??= p;
        carbs ??= c;
        fat ??= f;
      });
    }

    // ── Calories fallback: kJ ÷ 4.184 ──
    if (calories == null) {
      final kjRe = RegExp(r'(\d+\.?\d*)\s*kj');
      for (final line in lines) {
        final m = kjRe.firstMatch(line);
        if (m != null) {
          final kj = double.tryParse(m.group(1)!);
          if (kj != null) {
            calories = double.parse((kj / 4.184).toStringAsFixed(1));
            break;
          }
        }
      }
    }

    return ScannedNutrients(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }

  // ---------------------------------------------------------------------------
  // Split-table parser
  // ---------------------------------------------------------------------------

  /// Handles tables where the label column and value column are printed
  /// as two separate vertical blocks by the OCR engine.
  ///
  /// Algorithm:
  ///   1. Scan lines until we find a recognisable nutrient keyword → that marks
  ///      the start of the "keyword block".
  ///   2. Collect all keyword lines (fat, carbs, protein, Brennwert, davon…).
  ///   3. The "value block" starts at the first purely-numeric/gram line after
  ///      the keyword block header row (e.g. "pro 100g").
  ///   4. Zip keyword index → value index.
  void _parseSplitTable(
    List<String> lines,
    void Function(double? protein, double? carbs, double? fat) onResult,
  ) {
    // ── Find the serving-size divider (e.g. "pro 100g") ──
    // Keywords are before it; values are after it.
    // If serving-size comes AFTER keywords (or is missing), use keyword-block end.
    int servingIdx = -1;
    int kwStart = -1;
    for (int i = 0; i < lines.length; i++) {
      if (kwStart == -1 && _isNutrientKeyword(lines[i])) kwStart = i;
      if (_isServingSizeLine(lines[i])) {
        servingIdx = i;
        // If serving-size line was found BEFORE the keyword block, keep searching
        if (kwStart == -1) continue;
        break;
      }
    }
    if (kwStart == -1) return;

    // Case A: serving-size is between keyword block and value block (normal)
    // Case B: serving-size is BEFORE keyword block, keywords and values are mixed after
    // Case C: no serving-size line found — estimate keyword block end

    final int kwEnd;
    final int valStart;

    if (servingIdx != -1 && servingIdx > kwStart) {
      // Case A: keywords before serving-size, values after
      kwEnd = servingIdx;
      valStart = servingIdx + 1;
    } else if (servingIdx != -1 && servingIdx < kwStart) {
      // Case B: serving-size before keywords — scan for keyword block end
      // then values follow
      int end = kwStart;
      for (int i = kwStart; i < lines.length; i++) {
        if (_isIngredientLine(lines[i])) break;
        if (_isNutrientKeyword(lines[i]) || _isSubRow(lines[i])) {
          end = i + 1;
        } else if (_standaloneValue(lines[i]) != null) {
          // First value line after keywords → that's the value start
          break;
        }
      }
      kwEnd = end;
      valStart = end;
    } else {
      // Case C: no serving-size — find where keyword block ends (last nutrient kw)
      int end = kwStart;
      for (int i = kwStart; i < lines.length; i++) {
        if (_isIngredientLine(lines[i])) break;
        if (_isNutrientKeyword(lines[i]) || _isSubRow(lines[i])) end = i + 1;
      }
      kwEnd = end;
      valStart = end;
    }

    // ── Build ordered keyword list (kwStart … kwEnd) ──
    debugPrint(
      '[SplitTable] kwStart=$kwStart kwEnd=$kwEnd servingIdx=$servingIdx',
    );
    for (int i = kwStart; i < kwEnd; i++) {
      debugPrint('[SplitTable] kw[$i]: "${lines[i]}"');
    }
    final kwLines = <_NutrientRow>[];
    bool lastWasSub = false;
    for (int i = kwStart; i < kwEnd; i++) {
      final l = lines[i];
      final lNext = i + 1 < kwEnd ? lines[i + 1] : '';
      if (_isIngredientLine(l)) break;
      if (_isEnergyKeyword(l)) {
        kwLines.add(_NutrientRow.energy);
        lastWasSub = false;
      } else if (_isSubRow(l) &&
          (l.contains('fetts') || lNext.contains('fetts'))) {
        // "davon ges. Fettsäuren" — mark as fatSub so the mapper can use it
        // as a fat proxy when no explicit Fett row is present.
        kwLines.add(_NutrientRow.fatSub);
        lastWasSub = true;
      } else if (_isSubRow(l)) {
        // If this sub-row is the continuation of a previous sub-row (e.g. "davon:"
        // followed by "- zucker"), don't add a second slot — they're one logical row.
        if (!lastWasSub) kwLines.add(_NutrientRow.sub);
        lastWasSub = true;
      } else if (l.contains('fetts')) {
        // Continuation of a split "davon ges. / Fettsäuren" line — no extra slot.
        if (!lastWasSub) kwLines.add(_NutrientRow.fatSub);
        lastWasSub = false;
      } else if (_isFatKeyword(l)) {
        kwLines.add(_NutrientRow.fat);
        lastWasSub = false;
      } else if (_isCarbsKeyword(l)) {
        kwLines.add(_NutrientRow.carbs);
        lastWasSub = false;
      } else if (_isProteinKeyword(l)) {
        kwLines.add(_NutrientRow.protein);
        lastWasSub = false;
      } else if (_isNutrientKeyword(l)) {
        kwLines.add(_NutrientRow.other); // salz, ballaststoffe, etc.
        lastWasSub = false;
      } else {
        lastWasSub = false;
      }
    }

    if (kwLines.isEmpty) return;

    debugPrint('[SplitTable] kwLines: $kwLines');

    // ── Build value list (valStart … until ingredients/end) ──
    final valLines = <double>[];
    bool seenPercent = false;
    for (int i = valStart; i < lines.length; i++) {
      final l = lines[i];
      if (_isIngredientLine(l)) break;
      if (_isServingSizeLine(l) && i != servingIdx) break;
      // Once we see a percent-sign line, the RDA column has started — stop.
      if (l.contains('%')) {
        seenPercent = true;
        break;
      }
      if (seenPercent) break;
      final v = _standaloneValue(l);
      // Only start collecting once we get first value (avoid stray header lines)
      if (v != null) {
        valLines.add(v);
      }
    }

    if (valLines.isEmpty) return;

    debugPrint('[SplitTable] valLines: $valLines');

    // ── Zip keyword rows → value rows ──
    int valIdx = 0;
    double? p, c, f;
    double? lastMainVal;

    // How many fat/fatSub/carbs/protein rows remain after position kwIdx?
    int remainingMainAfter(int kwIdx) {
      int count = 0;
      for (int k = kwIdx + 1; k < kwLines.length; k++) {
        final r = kwLines[k];
        if (r == _NutrientRow.fat ||
            r == _NutrientRow.fatSub ||
            r == _NutrientRow.carbs ||
            r == _NutrientRow.protein)
          count++;
      }
      return count;
    }

    for (int kwIdx = 0; kwIdx < kwLines.length; kwIdx++) {
      if (valIdx >= valLines.length) break;
      final kw = kwLines[kwIdx];
      switch (kw) {
        case _NutrientRow.energy:
          final v1 = valLines[valIdx];
          if (v1 < 50) {
            // Energy was before the value block (Case B) → consume no slot
          } else {
            final hasV2 = valIdx + 1 < valLines.length;
            valIdx += (v1 > 400 && hasV2) ? 2 : 1;
          }
        case _NutrientRow.fatSub:
          // "davon ges. Fettsäuren" sub-row.
          // If no fat value seen yet → use this value as a fat proxy.
          // Otherwise consume only if plausible AND enough values remain.
          // Special case: if fsVal > fat, ges.FS cannot exceed Fett → OCR missed the
          // real Fett value. Null out fat so we don't report ges.FS as fat.
          // Do NOT consume the fatSub slot (fat row already consumed ges.FS's position).
          final fsVal = valLines[valIdx];
          if (f == null && lastMainVal == null) {
            f = fsVal;
            lastMainVal = fsVal;
            valIdx++;
          } else if (f != null && fsVal > f!) {
            // Impossible: ges.FS > Fett → fat was actually ges.FS (OCR missed Fett).
            // Discard the mis-assigned fat and reset; carbs will get the correct slot.
            f = null;
            lastMainVal = null;
          } else if (lastMainVal != null && fsVal <= lastMainVal!) {
            final remMain = remainingMainAfter(kwIdx);
            final remVals = valLines.length - valIdx - 1;
            if (remVals > remMain) valIdx++;
          }
        case _NutrientRow.fat:
          if (f == null) {
            f = valLines[valIdx];
            lastMainVal = f;
          }
          valIdx++;
        case _NutrientRow.carbs:
          if (c == null) {
            c = valLines[valIdx];
            lastMainVal = c;
          }
          valIdx++;
        case _NutrientRow.protein:
          if (p == null) {
            p = valLines[valIdx];
            lastMainVal = p;
          }
          valIdx++;
        case _NutrientRow.sub:
          // Consume only if plausible (≤ last main) AND enough values remain.
          final subVal = valLines[valIdx];
          if (lastMainVal != null && subVal <= lastMainVal!) {
            final remMain = remainingMainAfter(kwIdx);
            final remVals = valLines.length - valIdx - 1;
            if (remVals > remMain) valIdx++;
          }
        case _NutrientRow.other:
          break;
      }
    }

    debugPrint('[SplitTable] result: p=$p, c=$c, f=$f');
    onResult(p, c, f);
  }

  // ---------------------------------------------------------------------------
  // EU-order positional fallback
  // ---------------------------------------------------------------------------

  /// Last-resort parser: collects all gram values in order after the serving-size
  /// line and assigns them by EU label position:
  /// Energy (1-2 slots) → Fat → ges.FS → Carbs → Sugar → Fibre → Protein → Salt
  void _parseByEuOrder(
    List<String> lines,
    void Function(double? protein, double? carbs, double? fat) onResult,
  ) {
    int startIdx = -1;
    for (int i = 0; i < lines.length; i++) {
      if (_isServingSizeLine(lines[i])) {
        startIdx = i + 1;
        break;
      }
    }
    if (startIdx == -1) return;

    final vals = <double>[];
    for (int i = startIdx; i < lines.length; i++) {
      final l = lines[i];
      if (_isIngredientLine(l)) break;
      if (l.contains('%')) break;
      // Use _standaloneValue (strict) to only accept genuine gram lines
      final v = _standaloneValue(l);
      if (v != null) vals.add(v);
    }

    if (vals.length < 3) return; // not enough values to do anything useful

    int idx = 0;

    // Skip energy: 1 or 2 slots (if first value >50, it's energy-related)
    if (idx < vals.length && vals[idx] > 50) idx++;
    if (idx < vals.length && vals[idx] > 50) idx++;

    final double? f = idx < vals.length ? vals[idx++] : null;

    // Skip ges. Fettsäuren only if the next value is clearly a sub-value
    // (much smaller than fat, i.e. <= fat). If it's larger, it's carbs, not ges.FS.
    if (f != null && idx < vals.length && vals[idx] <= f) idx++;

    final double? c = idx < vals.length ? vals[idx++] : null;

    // Skip Zucker only if the next value is <= carbs
    if (c != null && idx < vals.length && vals[idx] <= c) idx++;

    // Skip Ballaststoffe (typically <= carbs, and smaller than carbs)
    if (c != null && idx < vals.length && vals[idx] < (c / 2)) idx++;

    final double? p = idx < vals.length ? vals[idx++] : null;

    onResult(p, c, f);
  }

  // ---------------------------------------------------------------------------
  // Keyword classifiers
  // ---------------------------------------------------------------------------

  bool _isProteinKeyword(String line) =>
      line.contains('eiwei') || line.contains('protein');

  bool _isCarbsKeyword(String line) =>
      line.contains('kohlenhydrat') ||
      line.contains('carbohydrat') ||
      line.contains('carbs');

  bool _isFatKeyword(String line) =>
      line.contains('fett') &&
      !line.contains('fetts') && // fettsäure / fetts„ure / fettsaure
      !line.contains('fatty');

  bool _isEnergyKeyword(String line) =>
      line.contains('brennwert') ||
      line.contains('energie') ||
      line.contains('energy');

  bool _isNutrientKeyword(String line) =>
      _isEnergyKeyword(line) ||
      _isFatKeyword(line) ||
      _isCarbsKeyword(line) ||
      _isProteinKeyword(line) ||
      line.contains('salz') ||
      line.contains('ballaststoff') ||
      line.contains('fibre') ||
      line.contains('fiber');

  bool _isSubRow(String line) =>
      line.startsWith('davon') ||
      line.startsWith('- ') ||
      line.startsWith('of which') ||
      line.startsWith('thereof');

  bool _isServingSizeLine(String line) =>
      RegExp(r'(?:pro|per|je)\s+\d').hasMatch(line) ||
      // Standalone "100g" / "100 g" (with or without "pro")
      RegExp(r'^(?:pro\s+)?1[o0][o0]\s*g$').hasMatch(line) ||
      // OCR artifacts: "1009" = "100g", "1oog" = "100g"
      RegExp(r'^1[o0]{1,2}[g9]$').hasMatch(line) ||
      line == 'pro 100g' ||
      line == 'je 100 g' ||
      line == 'per 100g';

  bool _isIngredientLine(String line) =>
      line.startsWith('zutat') ||
      line.startsWith('ingredient') ||
      line.startsWith('mindestens') ||
      line.startsWith('netto') ||
      line.startsWith('referenzmenge') ||
      line.startsWith('* referenz') ||
      line.startsWith('erwachsenen');

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns value if [line] looks like a standalone nutrient value row,
  /// e.g. "14.2 g", "0.38 g", "60.1", "11.0g", "1.354 kj", "320 kcal".
  /// Returns null for lines that are clearly keywords or serving headers.
  double? _standaloneValue(String line) {
    // Must not look like a keyword
    if (_isNutrientKeyword(line)) return null;
    // Strip trailing percent / reference amounts and leading spaces
    final clean = line.replaceAll(RegExp(r'\d+\s*%.*$'), '').trim();
    // Accept "14.2 g", "0.38 g", "14.2", "11.0g", "11.og" (OCR o→0 or trailing o).
    // Require either a decimal point OR a gram unit to distinguish macro values
    // from bare integer RDA-% values like "2" or "20".
    final gMatch = RegExp(r'^(\d+\.?\d*[oO]?)\s*[gGoO]?$').firstMatch(clean);
    if (gMatch != null) {
      final raw = gMatch.group(1)!;
      final numStr = raw.replaceAll(RegExp(r'[oO]$'), '0');
      final hasDecimal = numStr.contains('.');
      final hasGUnit = clean.length > raw.length; // unit character present
      // Only accept if it has a decimal point or a gram unit
      if (hasDecimal || hasGUnit) return double.tryParse(numStr);
    }
    // Accept "320 kcal" energy lines
    final kcalMatch = RegExp(r'^(\d+\.?\d*)\s*kcal$').firstMatch(clean);
    if (kcalMatch != null) return double.tryParse(kcalMatch.group(1)!);
    // Accept "1.354 kj" energy lines
    final kjMatch = RegExp(r'^(\d+\.?\d*)\s*kj$').firstMatch(clean);
    if (kjMatch != null) return double.tryParse(kjMatch.group(1)!);
    // "745.6 kj/ 179.9" — number + kj text + slash + number → second is kcal
    final kjSlash = RegExp(
      r'(\d+\.?\d*)\s*kj\s*/\s*(\d+\.?\d*)',
    ).firstMatch(clean);
    if (kjSlash != null) return double.tryParse(kjSlash.group(2)!);
    // "1527/360" — pure slash, take smaller as kcal
    final slashM = RegExp(r'^(\d+\.?\d*)\s*/\s*(\d+\.?\d*)$').firstMatch(clean);
    if (slashM != null) {
      final a = double.tryParse(slashM.group(1)!) ?? 0;
      final b = double.tryParse(slashM.group(2)!) ?? 0;
      if (a > 0 && b > 0 && a != b) return b < a ? b : a;
    }
    return null;
  }

  /// First "X g" / "X gramm" in [text]; falls back to the first standalone number.
  /// Strips "pro/per/je Xg" serving-size markers first to avoid false positives.
  /// Never returns energy values (kcal / kJ).
  double? _gramsIn(String text) {
    // Reject lines that are clearly energy values, not gram amounts
    if (text.contains('kcal') || text.contains('kj')) return null;
    final cleaned = text.replaceAll(
      RegExp(r'(?:pro|per|je)\s+\d+\.?\d*\s*g\b', caseSensitive: false),
      '',
    );
    // Match "14.2 g", "11.0g", "11.og" (OCR o→0)
    final gMatch = RegExp(
      r'(\d+\.?\d*[oO]?)\s*g(?:ramm)?\b',
      caseSensitive: false,
    ).firstMatch(cleaned);
    if (gMatch != null) {
      final numStr = gMatch.group(1)!.replaceAll(RegExp(r'[oO]$'), '0');
      return double.tryParse(numStr);
    }
    final numMatch = RegExp(r'(\d+\.?\d*)').firstMatch(cleaned);
    return numMatch != null ? double.tryParse(numMatch.group(1)!) : null;
  }

  /// Windows OCR via PowerShell + Windows.Media.Ocr WinRT (built into Windows 10+).
  /// Windows OCR: compiles a tiny C# helper on the fly via csc.exe,
  /// which supports WinRT async/await natively. Requires Windows 10 SDK.
  Future<String> _scanViaWindowsOcr(String imagePath) async {
    final absPath = File(imagePath).absolute.path;

    // PowerShell script: finds Windows.winmd, compiles C# OCR helper, runs it.
    const script = r'''
param([string]$imagePath)

$winmd = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\UnionMetadata" `
    -Filter "Windows.winmd" -Recurse -EA 0 |
    Sort-Object { try { [version]$_.Directory.Name } catch { [version]"0.0" } } -Descending |
    Select-Object -First 1 -ExpandProperty FullName
if (-not $winmd) { Write-Error "Windows 10 SDK (UnionMetadata) not found"; exit 1 }

$rd  = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319"
$csc = "$rd\csc.exe"
$ts  = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$cs  = "$env:TEMP\ebr_ocr_$ts.cs"
$exe = "$env:TEMP\ebr_ocr_$ts.exe"

Set-Content $cs @'
using System; using System.Linq; using System.Threading.Tasks;
using Windows.Media.Ocr; using Windows.Storage;
using Windows.Graphics.Imaging; using Windows.Globalization;
class Program {
    static void Main(string[] a) {
        try { Console.Write(Run(a[0]).GetAwaiter().GetResult()); }
        catch (Exception ex) { Console.Error.WriteLine(ex.Message); Environment.Exit(1); }
    }
    static async Task<string> Run(string p) {
        var file = await StorageFile.GetFileFromPathAsync(System.IO.Path.GetFullPath(p));
        var stream = await file.OpenAsync(FileAccessMode.Read);
        var dec = await BitmapDecoder.CreateAsync(stream);
        var bmp = await dec.GetSoftwareBitmapAsync();
        var eng = OcrEngine.TryCreateFromUserProfileLanguages();
        if (eng == null) foreach (var t in new[]{"de-DE","de","en-US","en"}) {
            eng = OcrEngine.TryCreateFromLanguage(new Language(t)); if (eng!=null) break;
        }
        if (eng == null) throw new Exception("No OCR language pack installed");
        var result = await eng.RecognizeAsync(bmp);
        return string.Join("\n", result.Lines.Select(l => l.Text));
    }
}
'@ -Encoding UTF8

$compileOut = & $csc /nologo /t:exe /out:$exe `
    "/r:$rd\System.Runtime.WindowsRuntime.dll" `
    "/r:$rd\System.Runtime.dll" `
    "/r:$winmd" $cs 2>&1
Remove-Item $cs -EA 0
if ($LASTEXITCODE -ne 0) { Write-Error "OCR compile failed: $compileOut"; exit 1 }
try { & $exe $imagePath } finally { Remove-Item $exe -EA 0 }
''';

    final ts = DateTime.now().millisecondsSinceEpoch;
    final scriptFile = File('${Directory.systemTemp.path}\\ebr_ocr_$ts.ps1');
    await scriptFile.writeAsString(script);

    try {
      final result = await Process.run(
        'powershell',
        [
          '-NonInteractive',
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-File',
          scriptFile.path,
          '-imagePath',
          absPath,
        ],
      );
      if (result.exitCode != 0) {
        throw Exception('Windows OCR Fehler: ${result.stderr}');
      }
      return result.stdout.toString().trim();
    } finally {
      try {
        await scriptFile.delete();
      } catch (_) {}
    }
  }

  /// Release ML Kit resources (no-op on desktop). Call when done.
  void dispose() => _mlKitRecognizer?.close();
}

/// Nutrient row type used for positional mapping in [NutritionScanService._parseSplitTable].
/// [fatSub] = "davon ges. Fettsäuren" — used as fat proxy when no explicit fat row exists.
enum _NutrientRow { energy, fat, fatSub, carbs, protein, sub, other }
