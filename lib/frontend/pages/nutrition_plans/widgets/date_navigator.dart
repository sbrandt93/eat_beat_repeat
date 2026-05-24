import 'package:eat_beat_repeat/frontend/pages/nutrition_plans/nutrition_plan_detail_page.dart';
import 'package:eat_beat_repeat/logic/models/nutrition_plan.dart';
import 'package:eat_beat_repeat/logic/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kompakte Datumsnavigation in der Plandetailansicht.
///
/// Zeigt Vor/Zurück-Pfeile, einen Heute-Chip und das aktuelle Datum
/// (antippen öffnet den Datepicker).
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
    final isToday = _isToday(selectedDate);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          // Zurück-Pfeil
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft),
            iconSize: 20,
            onPressed: () => _changeDate(ref, -1),
          ),

          // Heute-Chip (nur sichtbar wenn nicht heute)
          if (!isToday)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ActionChip(
                label: const Text('Heute', style: TextStyle(fontSize: 11)),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.teal.shade50,
                labelStyle: const TextStyle(color: Colors.teal),
                onPressed: () => ref.read(selectedDateProvider.notifier).state =
                    DateTime.now(),
              ),
            ),

          // Datum (antippen = Datepicker)
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(context, ref),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isToday ? 'Heute' : _getWeekdayName(selectedDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: isToday ? Colors.teal : Colors.grey.shade500,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    formatDateTime(selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Vor-Pfeil
          IconButton(
            icon: const Icon(LucideIcons.chevronRight),
            iconSize: 20,
            onPressed: () => _changeDate(ref, 1),
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
    final firstDate = plan.startDate.isBefore(DateTime(2020))
        ? DateTime(2020)
        : plan.startDate;
    final lastDate = plan.endDate ?? DateTime(2030);
    DateTime initialDate = selectedDate;
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

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
}
