import 'package:eat_beat_repeat/logic/models/meal_entry.dart';

class DayOverride {
  final String dateKey;
  final List<String> hiddenRecurringMealTemplateIds;
  final List<MealEntry> additionalMeals;

  DayOverride._({
    required this.dateKey,
    required this.hiddenRecurringMealTemplateIds,
    required this.additionalMeals,
  });

  factory DayOverride({
    required String dateKey,
    List<String>? hiddenRecurringMealTemplateIds,
    List<MealEntry>? additionalMeals,
  }) {
    return DayOverride._(
      dateKey: dateKey,
      hiddenRecurringMealTemplateIds: hiddenRecurringMealTemplateIds ?? [],
      additionalMeals: additionalMeals ?? [],
    );
  }

  DayOverride copyWith({
    List<String>? hiddenRecurringMealTemplateIds,
    List<MealEntry>? additionalMeals,
  }) {
    return DayOverride._(
      dateKey: dateKey,
      hiddenRecurringMealTemplateIds:
          hiddenRecurringMealTemplateIds ?? this.hiddenRecurringMealTemplateIds,
      additionalMeals: additionalMeals ?? this.additionalMeals,
    );
  }

  @override
  String toString() {
    return 'DayOverride(dateKey: $dateKey, hiddenRecurringMealTemplateIds: $hiddenRecurringMealTemplateIds, additionalMeals: $additionalMeals)';
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'hiddenRecurringMealTemplateIds': hiddenRecurringMealTemplateIds,
      'additionalMeals': additionalMeals
          .map((meal) => (meal as dynamic).toJson())
          .toList(),
    };
  }

  // JSON deserialization
  static DayOverride fromJson(Map<String, dynamic> json) {
    return DayOverride._(
      dateKey: json['dateKey'],
      hiddenRecurringMealTemplateIds: List<String>.from(
        json['hiddenRecurringMealTemplateIds'],
      ),
      additionalMeals: (json['additionalMeals'] as List)
          .map(
            (mealJson) => MealEntry.fromJson(mealJson),
          )
          .toList(),
    );
  }
}
