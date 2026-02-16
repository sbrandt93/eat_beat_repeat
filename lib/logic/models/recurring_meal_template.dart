import 'package:eat_beat_repeat/logic/models/meal_entry.dart';
import 'package:eat_beat_repeat/logic/models/recurrence_rule.dart';
import 'package:uuid/uuid.dart';

class RecurringMealTemplate {
  final String id;
  final MealEntry mealEntry;
  final RecurrenceRule rule;

  RecurringMealTemplate._({
    required this.id,
    required this.mealEntry,
    required this.rule,
  });

  factory RecurringMealTemplate({
    required MealEntry mealEntry,
    required RecurrenceRule rule,
  }) {
    return RecurringMealTemplate._(
      id: const Uuid().v4(),
      mealEntry: mealEntry,
      rule: rule,
    );
  }

  // appliesToDate() (delegated)
  bool appliesToDate(DateTime date) {
    return rule.appliesToDate(date);
  }

  RecurringMealTemplate copyWith({
    MealEntry? mealEntry,
    RecurrenceRule? rule,
  }) {
    return RecurringMealTemplate._(
      id: id,
      mealEntry: mealEntry ?? this.mealEntry,
      rule: rule ?? this.rule,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mealEntry': mealEntry.toJson(),
      'rule': rule.toJson(),
    };
  }

  // JSON deserialization
  static RecurringMealTemplate fromJson(Map<String, dynamic> json) {
    return RecurringMealTemplate._(
      id: json['id'],
      mealEntry: MealEntry.fromJson(json['mealEntry']),
      rule: RecurrenceRule.fromJson(json['rule']),
    );
  }

  @override
  String toString() {
    return 'RecurringMealTemplate(id: $id, mealEntry: $mealEntry, rule: $rule)';
  }
}
