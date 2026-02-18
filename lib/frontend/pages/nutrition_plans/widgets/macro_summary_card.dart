import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:flutter/material.dart';

/// Zusammenfassungs-Card für Makronährwerte eines Tages.
///
/// Zeigt Kalorien prominent mit Fortschrittsbalken und
/// die drei Makros (Protein, Carbs, Fett) mit individuellen Fortschrittsanzeigen.
class MacroSummaryCard extends StatelessWidget {
  final MacroNutrients dayMacros;
  final MacroNutrients targets;

  const MacroSummaryCard({
    super.key,
    required this.dayMacros,
    required this.targets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
          // Kalorien-Anzeige (groß)
          CalorieDisplay(
            current: dayMacros.calories,
            target: targets.calories,
          ),
          const SizedBox(height: 16),

          // Makro-Balken
          Row(
            children: [
              Expanded(
                child: MacroProgressBar(
                  label: 'Protein',
                  current: dayMacros.protein,
                  target: targets.protein,
                  color: Colors.red.shade400,
                  unit: 'g',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MacroProgressBar(
                  label: 'Carbs',
                  current: dayMacros.carbs,
                  target: targets.carbs,
                  color: Colors.blue.shade400,
                  unit: 'g',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MacroProgressBar(
                  label: 'Fett',
                  current: dayMacros.fat,
                  target: targets.fat,
                  color: Colors.amber.shade600,
                  unit: 'g',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Große Kalorienanzeige mit Fortschrittsbalken.
class CalorieDisplay extends StatelessWidget {
  final double current;
  final double target;

  const CalorieDisplay({
    super.key,
    required this.current,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = target > 0 ? (current / target).clamp(0.0, 1.5) : 0.0;
    final remaining = target - current;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              current.toStringAsFixed(0),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '/ ${target.toStringAsFixed(0)} kcal',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage.toDouble(),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(
              percentage > 1 ? Colors.orange : Colors.teal,
            ),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          remaining > 0
              ? '${remaining.toStringAsFixed(0)} kcal übrig'
              : '${(-remaining).toStringAsFixed(0)} kcal über Ziel',
          style: TextStyle(
            fontSize: 12,
            color: remaining > 0 ? Colors.grey.shade600 : Colors.orange,
          ),
        ),
      ],
    );
  }
}

/// Fortschrittsbalken für einen einzelnen Makronährwert.
class MacroProgressBar extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;
  final String unit;

  const MacroProgressBar({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          '${current.toStringAsFixed(1)}$unit',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: percentage.toDouble(),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '/ ${target.toStringAsFixed(0)}$unit',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}
