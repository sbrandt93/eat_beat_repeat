import 'package:eat_beat_repeat/logic/models/scanned_nutrients.dart';
import 'package:eat_beat_repeat/logic/services/nutrition_scan_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

bool get _hasMobileCamera =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

class NutritionScanButton extends StatefulWidget {
  final void Function(ScannedNutrients nutrients) onResult;

  const NutritionScanButton({super.key, required this.onResult});

  @override
  State<NutritionScanButton> createState() => _NutritionScanButtonState();
}

class _NutritionScanButtonState extends State<NutritionScanButton> {
  bool _isLoading = false;

  Future<void> _startScan() async {
    String? barcode;
    if (_hasMobileCamera) {
      barcode = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const _BarcodeScannerPage()),
      );
    } else {
      barcode = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const _DesktopBarcodeScanPage()),
      );
    }

    if (barcode == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final result = await NutritionScanService().lookupBarcode(barcode);
      if (!mounted) return;

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produkt nicht gefunden. Bitte manuell eintragen.'),
          ),
        );
      } else {
        widget.onResult(result);
        final found = [
          if (result.calories != null) 'kcal',
          if (result.protein != null) 'Protein',
          if (result.carbs != null) 'Kohlenhydrate',
          if (result.fat != null) 'Fett',
          if (result.name != null) 'Name',
          if (result.brand != null) 'Marke',
        ];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gefunden: ${found.join(', ')}'),
            backgroundColor: Colors.teal,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Abrufen: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _startScan,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.qr_code_scanner_outlined),
      label: Text(_isLoading ? 'Wird geladen...' : 'Barcode scannen'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

class _BarcodeScannerPage extends StatefulWidget {
  const _BarcodeScannerPage();

  @override
  State<_BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage> {
  bool _detected = false;

  void _onDetect(BarcodeCapture capture) {
    if (_detected) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null) return;
    _detected = true;
    Navigator.of(context).pop(barcode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode scannen'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}

// ── Desktop / Web: image-based barcode scan ──────────────────────────────────

class _DesktopBarcodeScanPage extends StatefulWidget {
  const _DesktopBarcodeScanPage();

  @override
  State<_DesktopBarcodeScanPage> createState() =>
      _DesktopBarcodeScanPageState();
}

// analyzeImage is only supported on Android, iOS, macOS — not Windows/Linux.
bool get _supportsImageScan =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

class _DesktopBarcodeScanPageState extends State<_DesktopBarcodeScanPage> {
  bool _loading = false;
  String? _hint;
  final _manualCtrl = TextEditingController();

  @override
  void dispose() {
    _manualCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndScan() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    setState(() {
      _loading = true;
      _hint = null;
    });

    try {
      final controller = MobileScannerController();
      final capture = await controller.analyzeImage(picked.path);
      controller.dispose();
      final barcode = capture?.barcodes.firstOrNull?.rawValue;
      if (!mounted) return;
      if (barcode != null) {
        Navigator.of(context).pop(barcode);
      } else {
        setState(() {
          _loading = false;
          _hint = 'Kein Barcode im Bild gefunden. Bitte manuell eingeben.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hint = 'Bildanalyse nicht verfügbar. Bitte manuell eingeben.';
      });
    }
  }

  void _submitManual() {
    final code = _manualCtrl.text.trim();
    if (code.isNotEmpty) Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode eingeben'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner_outlined,
              size: 64,
              color: Colors.teal,
            ),
            const SizedBox(height: 24),
            if (_supportsImageScan) ...[
              const Text(
                'Foto mit Barcode auswählen',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loading ? null : _pickAndScan,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_library_outlined),
                label: Text(_loading ? 'Analysiere…' : 'Foto auswählen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
              if (_hint != null) ...[
                const SizedBox(height: 8),
                Text(
                  _hint!,
                  style: const TextStyle(color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('oder manuell'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Barcode-Nummer eingeben…',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _submitManual(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitManual,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
