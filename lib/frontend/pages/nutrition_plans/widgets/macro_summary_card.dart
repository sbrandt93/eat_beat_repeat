import 'dart:math' show pi;

import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Anzeigemodus der Makro-Zusammenfassungs-Karte.
enum MacroViewMode {
  /// Plan-Modus: geplante Werte vs. Tagesziel.
  plan,

  /// Action-Modus: gegessene Werte vs. geplante Werte.
  execute,
}

extension _MacroViewModeX on MacroViewMode {
  MacroViewMode get next =>
      this == MacroViewMode.plan ? MacroViewMode.execute : MacroViewMode.plan;

  String get tooltip =>
      this == MacroViewMode.plan ? 'Plan-Modus' : 'Action-Modus';

  IconData get icon =>
      this == MacroViewMode.plan ? LucideIcons.clipboard : LucideIcons.utensils;
}

/// Dreischichtige Zusammenfassungs-Card für Makronährwerte eines Tages.
///
/// Zeigt Tagesziel (targets), geplante Mahlzeiten (plannedMacros) und
/// abgehakte Mahlzeiten (checkedMacros) in drei Ebenen an.
class MacroSummaryCard extends StatefulWidget {
  /// Tägliche Makro-Ziele aus dem Plan.
  final MacroNutrients targets;

  /// Makros aller geplanten Mahlzeiten des Tages (verblasst dargestellt).
  final MacroNutrients plannedMacros;

  /// Makros nur der abgehakten (gegessenen) Mahlzeiten (deutlich dargestellt).
  final MacroNutrients checkedMacros;

  /// Verbrannte Kalorien (Platzhalter, wird später befüllt).
  final double burnedCalories;

  /// Aktuell angezeigter Tag — wird für die Erkennung eines Datum-Wechsels benötigt.
  final DateTime selectedDate;

  const MacroSummaryCard({
    super.key,
    required this.targets,
    required this.plannedMacros,
    required this.checkedMacros,
    required this.burnedCalories,
    required this.selectedDate,
  });

  @override
  State<MacroSummaryCard> createState() => _MacroSummaryCardState();
}

class _MacroSummaryCardState extends State<MacroSummaryCard>
    with TickerProviderStateMixin {
  // Ein Controller steuert alle Zähler-Animationen gleichzeitig
  late final AnimationController _macroCtrl;
  late final CurvedAnimation _macroAnim;

  // Startwerte für die Count-up-Animation
  double _fromCalories = 0;
  double _fromProtein = 0;
  double _fromCarbs = 0;
  double _fromFat = 0;

  // Feuerwerk-Controller: je einer pro Makro-Ziel
  late final AnimationController _fwKcal;
  late final AnimationController _fwProtein;
  late final AnimationController _fwCarbs;
  late final AnimationController _fwFat;

  /// Aktueller Anzeigemodus (Planen / Ausführen / Voll).
  MacroViewMode _viewMode = MacroViewMode.execute;

  @override
  void initState() {
    super.initState();
    _fromCalories = widget.checkedMacros.calories;
    _fromProtein = widget.checkedMacros.protein;
    _fromCarbs = widget.checkedMacros.carbs;
    _fromFat = widget.checkedMacros.fat;

    _macroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _macroAnim = CurvedAnimation(parent: _macroCtrl, curve: Curves.easeInOut);
    _macroCtrl.value = 1.0; // erster Build ohne Animation

    const fwDuration = Duration(milliseconds: 1200);
    _fwKcal = AnimationController(vsync: this, duration: fwDuration);
    _fwProtein = AnimationController(vsync: this, duration: fwDuration);
    _fwCarbs = AnimationController(vsync: this, duration: fwDuration);
    _fwFat = AnimationController(vsync: this, duration: fwDuration);
  }

  @override
  void didUpdateWidget(MacroSummaryCard old) {
    super.didUpdateWidget(old);

    // Datum gewechselt → sofort auf neuen Wert snappen (keine Animation, kein Feuerwerk)
    if (old.selectedDate != widget.selectedDate) {
      _macroCtrl.stop();
      _fwKcal.stop();
      _fwProtein.stop();
      _fwCarbs.stop();
      _fwFat.stop();
      _fromCalories = widget.checkedMacros.calories;
      _fromProtein = widget.checkedMacros.protein;
      _fromCarbs = widget.checkedMacros.carbs;
      _fromFat = widget.checkedMacros.fat;
      _macroCtrl.value = 1.0;
      return;
    }

    final oldC = old.checkedMacros;
    final newC = widget.checkedMacros;
    final tgt = widget.targets;

    if (oldC.calories != newC.calories ||
        oldC.protein != newC.protein ||
        oldC.carbs != newC.carbs ||
        oldC.fat != newC.fat) {
      // Aktuellen Anzeigewert als neuen "Von"-Wert sichern (unterbricht laufende Animation)
      final t = _macroAnim.value;
      _fromCalories = _fromCalories + t * (oldC.calories - _fromCalories);
      _fromProtein = _fromProtein + t * (oldC.protein - _fromProtein);
      _fromCarbs = _fromCarbs + t * (oldC.carbs - _fromCarbs);
      _fromFat = _fromFat + t * (oldC.fat - _fromFat);

      _macroCtrl.forward(from: 0);

      // Feuerwerk nur wenn Ziel neu erreicht (war darunter, ist jetzt drüber)
      if (oldC.calories < tgt.calories && newC.calories >= tgt.calories) {
        _fwKcal.forward(from: 0);
      }
      if (oldC.protein < tgt.protein && newC.protein >= tgt.protein) {
        _fwProtein.forward(from: 0);
      }
      if (oldC.carbs < tgt.carbs && newC.carbs >= tgt.carbs) {
        _fwCarbs.forward(from: 0);
      }
      if (oldC.fat < tgt.fat && newC.fat >= tgt.fat) {
        _fwFat.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _macroCtrl.dispose();
    _fwKcal.dispose();
    _fwProtein.dispose();
    _fwCarbs.dispose();
    _fwFat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _macroAnim,
      builder: (context, _) {
        final t = _macroAnim.value;
        final dispCalories =
            _fromCalories + t * (widget.checkedMacros.calories - _fromCalories);
        final dispProtein =
            _fromProtein + t * (widget.checkedMacros.protein - _fromProtein);
        final dispCarbs =
            _fromCarbs + t * (widget.checkedMacros.carbs - _fromCarbs);
        final dispFat = _fromFat + t * (widget.checkedMacros.fat - _fromFat);

        final netCalories = dispCalories - widget.burnedCalories;
        final plannedFrac = widget.targets.calories > 0
            ? (widget.plannedMacros.calories / widget.targets.calories).clamp(
                0.0,
                1.5,
              )
            : 0.0;
        final checkedFrac = widget.targets.calories > 0
            ? (dispCalories / widget.targets.calories).clamp(0.0, 1.5)
            : 0.0;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _VionProgressWidget(
                    plannedFrac: plannedFrac,
                    checkedFrac: checkedFrac,
                    displayCalories: dispCalories,
                    plannedCalories: widget.plannedMacros.calories,
                    targetCalories: widget.targets.calories,
                    fireworkCtrl: _fwKcal,
                    viewMode: _viewMode,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Modus-Umschalter
                        Align(
                          alignment: Alignment.centerRight,
                          child: Tooltip(
                            message: _viewMode.tooltip,
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => setState(
                                  () => _viewMode = _viewMode.next,
                                ),
                                child: Icon(
                                  _viewMode.icon,
                                  size: 16,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _TriLayerMacroBar(
                          label: 'Protein',
                          target: widget.targets.protein,
                          planned: widget.plannedMacros.protein,
                          displayChecked: dispProtein,
                          color: Colors.red.shade400,
                          fireworkCtrl: _fwProtein,
                          viewMode: _viewMode,
                        ),
                        const SizedBox(height: 9),
                        _TriLayerMacroBar(
                          label: 'Carbs',
                          target: widget.targets.carbs,
                          planned: widget.plannedMacros.carbs,
                          displayChecked: dispCarbs,
                          color: Colors.blue.shade400,
                          fireworkCtrl: _fwCarbs,
                          viewMode: _viewMode,
                        ),
                        const SizedBox(height: 9),
                        _TriLayerMacroBar(
                          label: 'Fett',
                          target: widget.targets.fat,
                          planned: widget.plannedMacros.fat,
                          displayChecked: dispFat,
                          color: Colors.amber.shade600,
                          fireworkCtrl: _fwFat,
                          viewMode: _viewMode,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatChip(
                    icon: LucideIcons.flame,
                    iconColor: Colors.orange.shade400,
                    label: 'Verbrannt',
                    value: '${widget.burnedCalories.toStringAsFixed(0)} kcal',
                    valueColor: Colors.grey.shade700,
                  ),
                  Container(height: 32, width: 1, color: Colors.grey.shade200),
                  _StatChip(
                    icon: LucideIcons.activity,
                    iconColor: netCalories <= 0 ? Colors.green : Colors.teal,
                    label: 'Bilanz',
                    value:
                        '${netCalories >= 0 ? '+' : ''}${netCalories.toStringAsFixed(0)} kcal',
                    valueColor: netCalories < 0 ? Colors.green : Colors.black87,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Vion Progress Widget
// ---------------------------------------------------------------------------

class _VionProgressWidget extends StatelessWidget {
  final double plannedFrac;
  final double checkedFrac;
  final double displayCalories;
  final double plannedCalories;
  final double targetCalories;
  final AnimationController fireworkCtrl;
  final MacroViewMode viewMode;

  const _VionProgressWidget({
    required this.plannedFrac,
    required this.checkedFrac,
    required this.displayCalories,
    required this.plannedCalories,
    required this.targetCalories,
    required this.fireworkCtrl,
    required this.viewMode,
  });

  @override
  Widget build(BuildContext context) {
    final goalReached = targetCalories > 0 && displayCalories >= targetCalories;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(110, 110),
                painter: _RingProgressPainter(
                  plannedFrac: plannedFrac,
                  checkedFrac: checkedFrac,
                ),
              ),
              // Kein ClipOval → ganzes Bild (inkl. Mähne) sichtbar
              Image.asset(
                goalReached
                    ? 'assets/vion/vion_cool.png'
                    : 'assets/vion/vion_basic.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Kcal-Anzeige mit Feuerwerk-Overlay
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  viewMode == MacroViewMode.plan
                      ? plannedCalories.toStringAsFixed(0)
                      : displayCalories.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: viewMode == MacroViewMode.plan
                        ? const Color(0xFF00897B).withOpacity(0.45)
                        : const Color(0xFF00897B),
                    letterSpacing: -0.5,
                  ),
                ),
                if (viewMode == MacroViewMode.plan)
                  Text(
                    '/ ${targetCalories.toStringAsFixed(0)} kcal',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  )
                else if (viewMode == MacroViewMode.execute)
                  Text(
                    '/ ${plannedCalories.toStringAsFixed(0)} kcal',
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFF00897B).withOpacity(0.45),
                    ),
                  )
                else
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 11),
                      children: [
                        TextSpan(
                          text: '/ ${plannedCalories.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: const Color(0xFF00897B).withOpacity(0.45),
                          ),
                        ),
                        TextSpan(
                          text: ' / ${targetCalories.toStringAsFixed(0)} kcal',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Center(child: _FireworkOverlay(ctrl: fireworkCtrl)),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Progress Ring Painter (dreischichtiger Kreisbogen)
// ---------------------------------------------------------------------------

/// Drei konzentrische Kreisbogen-Ebenen: grau (Ziel) / teal-hell (geplant) /
/// teal-solid (gegessen). Läuft ab 12-Uhr im Uhrzeigersinn.
class _RingProgressPainter extends CustomPainter {
  final double plannedFrac;
  final double checkedFrac;

  const _RingProgressPainter({
    required this.plannedFrac,
    required this.checkedFrac,
  });

  static const double _strokeW = 9.0;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - _strokeW / 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    // Ebene 1: grauer Hintergrund (= 100 % Tagesziel)
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi,
      false,
      Paint()
        ..color = Colors.grey.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeW
        ..strokeCap = StrokeCap.round,
    );

    // Ebene 2: geplante Mahlzeiten (verblasst teal)
    if (plannedFrac > 0) {
      canvas.drawArc(
        rect,
        -pi / 2,
        2 * pi * plannedFrac.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = Colors.teal.withOpacity(0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeW
          ..strokeCap = StrokeCap.round,
      );
    }

    // Ebene 3: abgehakte Mahlzeiten (solid teal)
    if (checkedFrac > 0) {
      canvas.drawArc(
        rect,
        -pi / 2,
        2 * pi * checkedFrac.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = Colors.teal
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeW
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingProgressPainter old) =>
      old.plannedFrac != plannedFrac || old.checkedFrac != checkedFrac;
}

// ---------------------------------------------------------------------------
// Dreischichtiger Makro-Balken (mit Count-up & Feuerwerk)
// ---------------------------------------------------------------------------

class _TriLayerMacroBar extends StatelessWidget {
  final String label;
  final double target;
  final double planned;
  final double displayChecked; // animated value passed from parent
  final Color color;
  final AnimationController fireworkCtrl;
  final MacroViewMode viewMode;

  const _TriLayerMacroBar({
    required this.label,
    required this.target,
    required this.planned,
    required this.displayChecked,
    required this.color,
    required this.fireworkCtrl,
    required this.viewMode,
  });

  @override
  Widget build(BuildContext context) {
    final plannedFrac = target > 0 ? (planned / target).clamp(0.0, 1.0) : 0.0;
    final checkedFrac = target > 0
        ? (displayChecked / target).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label-Zeile mit Feuerwerk-Overlay
        Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    children: switch (viewMode) {
                      MacroViewMode.plan => [
                        TextSpan(
                          text: '${planned.toStringAsFixed(0)}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        TextSpan(
                          text: '/${target.toStringAsFixed(0)}g',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                      MacroViewMode.execute => [
                        TextSpan(
                          text: '${displayChecked.toStringAsFixed(0)}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        TextSpan(
                          text: '/${planned.toStringAsFixed(0)}g',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    },
                  ),
                ),
              ],
            ),
            // Feuerwerk startet an der Wert-Anzeige (rechts)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(child: _FireworkOverlay(ctrl: fireworkCtrl)),
            ),
          ],
        ),
        const SizedBox(height: 3),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final plannedWidth = plannedFrac * width;
            final checkedWidth = checkedFrac * width;

            return SizedBox(
              height: 8,
              child: Stack(
                children: [
                  // Hintergrund (= Tagesziel)
                  Container(
                    width: width,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Ebene 2: geplante Mahlzeiten (verblasst)
                  Container(
                    width: plannedWidth,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.28),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Ebene 3: abgehakte Mahlzeiten (voll)
                  Container(
                    width: checkedWidth,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Feuerwerk-Overlay: Sterne steigen raketenartig nach oben
// ---------------------------------------------------------------------------

/// 5 Sterne in unterschiedlichen Größen starten vom gleichen Ursprungspunkt,
/// fliegen leicht gefächert nach oben und verblassen dabei.
class _FireworkOverlay extends StatelessWidget {
  final AnimationController ctrl;

  const _FireworkOverlay({required this.ctrl});

  // (Start-X px, max. Höhe px, horizontale Flugweite px, Icon-Größe, Startverzögerung 0..1)
  static const _specs = [
    (0.0, 42.0, 0.0, 16.0, 0.00), // Mitte — gerade nach oben
    (-9.0, 34.0, -14.0, 11.0, 0.07), // links — fliegt nach links oben
    (8.0, 38.0, 13.0, 13.0, 0.04), // rechts — fliegt nach rechts oben
    (-4.0, 24.0, -8.0, 10.0, 0.12), // nah links — leicht links oben
    (5.0, 30.0, 9.0, 12.0, 0.09), // nah rechts — leicht rechts oben
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        if (ctrl.isDismissed) return const SizedBox.shrink();
        // SizedBox(0,0) → OverflowBox gibt Raum für die Sterne ohne das Layout zu stören
        return SizedBox(
          width: 0,
          height: 0,
          child: OverflowBox(
            maxWidth: 60,
            maxHeight: 80,
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: 60,
              height: 80,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  for (final s in _specs)
                    _buildParticle(s.$1, s.$2, s.$3, s.$4, s.$5),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticle(
    double startX,
    double maxDy,
    double maxDxVel,
    double size,
    double delay,
  ) {
    final raw = ctrl.value;
    final t = delay >= 1.0
        ? raw
        : ((raw - delay) / (1.0 - delay)).clamp(0.0, 1.0);
    if (t == 0.0) return const SizedBox.shrink();

    final yMove = maxDy * t;
    final xMove = maxDxVel * t; // horizontale Flugbewegung
    // Fade-in (0→0.35), voll (0.35→0.70), Fade-out (0.70→1.0)
    final opacity = t < 0.35
        ? (t / 0.35)
        : t < 0.70
        ? 1.0
        : ((1.0 - t) / 0.30);

    return Positioned(
      bottom: yMove,
      left:
          30.0 +
          startX +
          xMove -
          size / 2, // 30 = halbe Breite des 60px-Containers
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Icon(Icons.star_rounded, color: Colors.amber, size: size),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat-Chip (Verbrannt / Bilanz)
// ---------------------------------------------------------------------------

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
