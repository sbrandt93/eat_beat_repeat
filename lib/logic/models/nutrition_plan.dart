import 'package:eat_beat_repeat/logic/interfaces/i_soft_deletable.dart';
import 'package:eat_beat_repeat/logic/models/day_override.dart';
import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:eat_beat_repeat/logic/models/recurring_meal_template.dart';
import 'package:eat_beat_repeat/logic/utils/wrapper.dart';
import 'package:uuid/uuid.dart';

class NutritionPlan implements ISoftDeletable<NutritionPlan> {
  @override
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime startDate;
  final DateTime? endDate;
  final List<RecurringMealTemplate> recurringMeals;
  final Map<String, DayOverride> dayOverrides;
  final MacroNutrients dailyMacroTargets;
  @override
  final DateTime? deletedAt;

  NutritionPlan._({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.startDate,
    required this.endDate,
    required this.recurringMeals,
    required this.dayOverrides,
    required this.dailyMacroTargets,
    required this.deletedAt,
  });

  factory NutritionPlan({
    required String name,
    required DateTime startDate,
    DateTime? endDate,
    List<RecurringMealTemplate>? recurringMeals,
    Map<String, DayOverride>? dayOverrides,
    required MacroNutrients dailyMacroTargets,
  }) {
    return NutritionPlan._(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now(),
      startDate: startDate,
      endDate: endDate,
      recurringMeals: recurringMeals ?? [],
      dayOverrides: dayOverrides ?? {},
      dailyMacroTargets: dailyMacroTargets,
      deletedAt: null,
    );
  }

  @override
  NutritionPlan copyWith({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    List<RecurringMealTemplate>? recurringMeals,
    Map<String, DayOverride>? dayOverrides,
    MacroNutrients? dailyMacroTargets,
    Wrapper<DateTime?>? deletedAt,
  }) {
    return NutritionPlan._(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      recurringMeals: recurringMeals ?? this.recurringMeals,
      dayOverrides: dayOverrides ?? this.dayOverrides,
      dailyMacroTargets: dailyMacroTargets ?? this.dailyMacroTargets,
      deletedAt: deletedAt != null ? deletedAt.value : this.deletedAt,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'recurringMeals': recurringMeals.map((rm) => rm.toJson()).toList(),
      'dayOverrides': dayOverrides.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'dailyMacroTargets': dailyMacroTargets.toJson(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  // JSON deserialization
  factory NutritionPlan.fromJson(Map<String, dynamic> json) {
    return NutritionPlan._(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      recurringMeals: (json['recurringMeals'] as List)
          .map((rm) => RecurringMealTemplate.fromJson(rm))
          .toList(),
      dayOverrides: (json['dayOverrides'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, DayOverride.fromJson(value)),
      ),
      dailyMacroTargets: MacroNutrients.fromJson(json['dailyMacroTargets']),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'])
          : null,
    );
  }
}
