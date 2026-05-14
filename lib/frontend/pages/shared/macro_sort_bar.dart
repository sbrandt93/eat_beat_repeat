import 'package:flutter/material.dart';

enum MacroSortField { calories, protein, carbs, fat }

class MacroSortCriteria {
  final MacroSortField field;
  final bool descending;

  const MacroSortCriteria(this.field, {required this.descending});
}

/// A compact sort bar with chips for multi-column sort.
///
/// Tap a chip:
///   • Inactive  → appended as lowest priority (new tiebreaker).
///     **First tap = priority 1 (primary), second tap = priority 2, etc.**
///   • Active ↓  → changes to ascending ↑.
///   • Active ↑  → removes the criterion.
///
/// Tap the × button to reset all criteria at once.
class MacroSortBar extends StatelessWidget {
  final List<MacroSortCriteria> sortCriteria;

  /// Called when a chip is tapped.
  final void Function(MacroSortField) onToggle;

  /// Called when the reset button is tapped.
  final VoidCallback onReset;

  const MacroSortBar({
    super.key,
    required this.sortCriteria,
    required this.onToggle,
    required this.onReset,
  });

  static String _label(MacroSortField field) => switch (field) {
    MacroSortField.calories => 'kcal',
    MacroSortField.protein => 'P',
    MacroSortField.carbs => 'K',
    MacroSortField.fat => 'F',
  };

  @override
  Widget build(BuildContext context) {
    final hasActive = sortCriteria.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Icon(Icons.sort, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(
            child: Wrap(
              spacing: 6,
              children: MacroSortField.values.map((field) {
                final idx = sortCriteria.indexWhere((c) => c.field == field);
                final isActive = idx != -1;
                final isDesc = isActive && sortCriteria[idx].descending;
                // Priority label: 1 = primary (most important)
                final priority = isActive ? idx + 1 : null;

                return ActionChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (priority != null)
                        Text(
                          '$priority ',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.teal.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      Text(
                        _label(field),
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive
                              ? Colors.teal.shade800
                              : Colors.grey.shade700,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 2),
                        Icon(
                          isDesc ? Icons.arrow_downward : Icons.arrow_upward,
                          size: 12,
                          color: Colors.teal.shade700,
                        ),
                      ],
                    ],
                  ),
                  backgroundColor: isActive
                      ? Colors.teal.shade50
                      : Colors.grey.shade100,
                  side: BorderSide(
                    color: isActive
                        ? Colors.teal.shade300
                        : Colors.grey.shade300,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 0,
                  ),
                  onPressed: () => onToggle(field),
                );
              }).toList(),
            ),
          ),
          if (hasActive)
            IconButton(
              icon: Icon(Icons.clear, size: 16, color: Colors.grey.shade600),
              tooltip: 'Sortierung zurücksetzen',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              onPressed: onReset,
            ),
        ],
      ),
    );
  }
}
