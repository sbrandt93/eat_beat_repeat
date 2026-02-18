import 'package:eat_beat_repeat/frontend/pages/nutrition_plans/nutrition_plan_detail_page.dart';
import 'package:eat_beat_repeat/logic/models/nutrition_plan.dart';
import 'package:eat_beat_repeat/logic/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Widget für die Datumsnavigation in der Plandetailansicht.
///
/// Zeigt das aktuelle Datum mit Vor/Zurück-Navigation und Quick-Buttons
/// für häufig verwendete Daten (Heute, Morgen).
class DateNavigator extends ConsumerWidget {
  final DateTime selectedDate;
  final NutritionPlan plan;

  const DateNavigator({
    super.key,
    required this.selectedDate,
    required this.plan,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Navigation Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.chevronLeft),
                onPressed: () => _changeDate(ref, -1),
              ),
              GestureDetector(
                onTap: () => _selectDate(context, ref),
                child: Column(
                  children: [
                    Text(
                      _getWeekdayName(selectedDate),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      formatDateTime(selectedDate),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.chevronRight),
                onPressed: () => _changeDate(ref, 1),
              ),
            ],
          ),

          // Quick-Navigation Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                QuickDateButton(
                  label: 'Heute',
                  isSelected: _isToday(selectedDate),
                  onTap: () => ref.read(selectedDateProvider.notifier).state =
                      DateTime.now(),
                ),
                const SizedBox(width: 8),
                QuickDateButton(
                  label: 'Morgen',
                  isSelected: _isTomorrow(selectedDate),
                  onTap: () => ref.read(selectedDateProvider.notifier).state =
                      DateTime.now().add(const Duration(days: 1)),
                ),
                const SizedBox(width: 8),
                QuickDateButton(
                  label: 'Diese Woche',
                  isSelected: false,
                  onTap: () => _showWeekPicker(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _changeDate(WidgetRef ref, int days) {
    ref.read(selectedDateProvider.notifier).state = selectedDate.add(
      Duration(days: days),
    );
  }

  Future<void> _selectDate(BuildContext context, WidgetRef ref) async {
    // Ensure initialDate is within valid range
    final firstDate = plan.startDate.isBefore(DateTime(2020))
        ? DateTime(2020)
        : plan.startDate;
    final lastDate = plan.endDate ?? DateTime(2030);
    DateTime initialDate = selectedDate;
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    }
    if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      ref.read(selectedDateProvider.notifier).state = picked;
    }
  }

  void _showWeekPicker(BuildContext context, WidgetRef ref) {
    // TODO: Implement week view
  }

  String _getWeekdayName(DateTime date) {
    const weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return weekdays[date.weekday - 1];
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }
}

/// Schnellauswahl-Button für häufig verwendete Daten.
class QuickDateButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const QuickDateButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected ? Colors.teal : Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onPressed: onTap,
    );
  }
}
