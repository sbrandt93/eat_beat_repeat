import 'package:eat_beat_repeat/logic/models/meal_entry.dart';
import 'package:eat_beat_repeat/logic/models/recurrence_rule.dart';
import 'package:uuid/uuid.dart';

class RecurringMealTemplate {
  final String id;
  final MealEntry mealEntry;
  final RecurrenceRule rule;

  /// First date (inclusive) this meal applies to.
  final DateTime startDate;

  /// First date (exclusive) this meal no longer applies to. Null = no end.
  final DateTime? endDate;

  RecurringMealTemplate._({
    required this.id,
    required this.mealEntry,
    required this.rule,
    required this.startDate,
    this.endDate,
  });

  factory RecurringMealTemplate({
    required MealEntry mealEntry,
    required RecurrenceRule rule,
    required DateTime startDate,
    DateTime? endDate,
  }) {
    return RecurringMealTemplate._(
      id: const Uuid().v4(),
      mealEntry: mealEntry,
      rule: rule,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Returns true if this template applies on [date].
  ///
  /// Checks startDate (inclusive) and endDate (exclusive) in addition to
  /// the recurrence rule.
  bool appliesToDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    if (d.isBefore(start)) return false;
    if (endDate != null) {
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (!d.isBefore(end)) return false;
    }
    return rule.appliesToDate(date);
  }

  RecurringMealTemplate copyWith({
    MealEntry? mealEntry,
    RecurrenceRule? rule,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
  }) {
    return RecurringMealTemplate._(
      id: id,
      mealEntry: mealEntry ?? this.mealEntry,
      rule: rule ?? this.rule,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mealEntry': mealEntry.toJson(),
      'rule': rule.toJson(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }

  // JSON deserialization
  static RecurringMealTemplate fromJson(Map<String, dynamic> json) {
    return RecurringMealTemplate._(
      id: json['id'],
      mealEntry: MealEntry.fromJson(json['mealEntry']),
      rule: RecurrenceRule.fromJson(json['rule']),
      // Backward compatibility: if startDate missing, default to epoch
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime(2000),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    );
  }

  @override
  String toString() {
    return 'RecurringMealTemplate(id: $id, mealEntry: $mealEntry, rule: $rule, '
        'startDate: $startDate, endDate: $endDate)';
  }
}
