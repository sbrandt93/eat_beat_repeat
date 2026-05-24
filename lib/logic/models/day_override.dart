import 'package:eat_beat_repeat/logic/models/meal_entry.dart';

class DayOverride {
  final String dateKey;
  final List<String> hiddenRecurringMealTemplateIds;
  final List<MealEntry> additionalMeals;
  final List<String> checkedMealIds;
  final double burnedCalories;

  DayOverride._({
    required this.dateKey,
    required this.hiddenRecurringMealTemplateIds,
    required this.additionalMeals,
    required this.checkedMealIds,
    required this.burnedCalories,
  });

  factory DayOverride({
    required String dateKey,
    List<String>? hiddenRecurringMealTemplateIds,
    List<MealEntry>? additionalMeals,
    List<String>? checkedMealIds,
    double burnedCalories = 0.0,
  }) {
    return DayOverride._(
      dateKey: dateKey,
      hiddenRecurringMealTemplateIds: hiddenRecurringMealTemplateIds ?? [],
      additionalMeals: additionalMeals ?? [],
      checkedMealIds: checkedMealIds ?? [],
      burnedCalories: burnedCalories,
    );
  }

  DayOverride copyWith({
    List<String>? hiddenRecurringMealTemplateIds,
    List<MealEntry>? additionalMeals,
    List<String>? checkedMealIds,
    double? burnedCalories,
  }) {
    return DayOverride._(
      dateKey: dateKey,
      hiddenRecurringMealTemplateIds:
          hiddenRecurringMealTemplateIds ?? this.hiddenRecurringMealTemplateIds,
      additionalMeals: additionalMeals ?? this.additionalMeals,
      checkedMealIds: checkedMealIds ?? this.checkedMealIds,
      burnedCalories: burnedCalories ?? this.burnedCalories,
    );
  }

  @override
  String toString() {
    return 'DayOverride(dateKey: $dateKey, hiddenRecurringMealTemplateIds: $hiddenRecurringMealTemplateIds, additionalMeals: $additionalMeals, checkedMealIds: $checkedMealIds, burnedCalories: $burnedCalories)';
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'hiddenRecurringMealTemplateIds': hiddenRecurringMealTemplateIds,
      'additionalMeals': additionalMeals
          .map((meal) => (meal as dynamic).toJson())
          .toList(),
      'checkedMealIds': checkedMealIds,
      'burnedCalories': burnedCalories,
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
      checkedMealIds: List<String>.from(json['checkedMealIds'] ?? []),
      burnedCalories: (json['burnedCalories'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
