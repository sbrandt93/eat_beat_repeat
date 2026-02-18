import 'package:eat_beat_repeat/logic/models/day_override.dart';
import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:eat_beat_repeat/logic/models/meal_entry.dart';
import 'package:eat_beat_repeat/logic/models/nutrition_plan.dart';
import 'package:eat_beat_repeat/logic/models/recipe.dart';
import 'package:eat_beat_repeat/logic/models/recurring_meal_template.dart';
import 'package:eat_beat_repeat/logic/services/macro_service.dart';

/// Service für NutritionPlan-bezogene Berechnungen und Abfragen.
///
/// Dieser Service ist zustandslos und wird mit den benötigten Maps initialisiert.
/// Er kapselt die gesamte Logik für:
/// - Ermittlung von Meals für einen bestimmten Tag
/// - Berechnung von Makronährwerten pro Tag
/// - Aggregationen über mehrere Tage
class NutritionPlanService {
  final MacroService _macroService;
  final Map<String, Recipe> recipeMap;

  NutritionPlanService({
    required Map<String, FoodData> foodDataMap,
    required this.recipeMap,
  }) : _macroService = MacroService(foodDataMap: foodDataMap);

  // -----------------------------------------------------------------------
  // HELPER
  // -----------------------------------------------------------------------

  /// Erzeugt einen konsistenten dateKey aus einem DateTime.
  String dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // -----------------------------------------------------------------------
  // MEALS FÜR EINEN TAG
  // -----------------------------------------------------------------------

  /// Gibt alle MealEntries für einen bestimmten Tag zurück.
  ///
  /// Berücksichtigt:
  /// - Recurring meals die laut RecurrenceRule an diesem Tag aktiv sind
  /// - Versteckte Templates via DayOverride.hiddenRecurringMealTemplateIds
  /// - Zusätzliche Meals via DayOverride.additionalMeals
  List<MealEntry> getMealsForDay(NutritionPlan plan, DateTime date) {
    final key = dateKey(date);
    final override = plan.dayOverrides[key];
    final hiddenIds = override?.hiddenRecurringMealTemplateIds ?? [];

    // Recurring meals die an diesem Tag gelten und nicht versteckt sind
    final recurringMeals = plan.recurringMeals
        .where(
          (template) =>
              template.appliesToDate(date) && !hiddenIds.contains(template.id),
        )
        .map((template) => template.mealEntry)
        .toList();

    // Zusätzliche Meals aus dem Override
    final additionalMeals = override?.additionalMeals ?? [];

    return [...recurringMeals, ...additionalMeals];
  }

  // -----------------------------------------------------------------------
  // MAKRO-BERECHNUNG FÜR EINEN MEAL ENTRY
  // -----------------------------------------------------------------------

  /// Berechnet die Makros für einen einzelnen MealEntry.
  ///
  /// Verwendet Pattern Matching für FoodEntry vs RecipeEntry.
  MacroNutrients calculateMacrosForMealEntry(MealEntry entry) {
    return switch (entry) {
      FoodEntry food => _macroService.calculateMacrosForFoodEntry(food),
      RecipeEntry recipe => _calculateMacrosForRecipeEntry(recipe),
    };
  }

  /// Berechnet die Makros für einen RecipeEntry (skaliert nach servings).
  MacroNutrients _calculateMacrosForRecipeEntry(RecipeEntry entry) {
    final recipe = recipeMap[entry.recipeId];
    if (recipe == null) {
      return MacroNutrients.zero();
    }

    // Berechne Makros für das gesamte Rezept
    final totalRecipeMacros = _macroService.calculateMacrosForRecipe(recipe);

    // Skaliere nach Portionen (1.0 = ganzes Rezept)
    return totalRecipeMacros.scale(entry.servings);
  }

  // -----------------------------------------------------------------------
  // MAKRO-BERECHNUNG FÜR EINEN TAG
  // -----------------------------------------------------------------------

  /// Berechnet die Summe aller Makronährwerte für einen Tag.
  MacroNutrients calculateMacrosForDay(NutritionPlan plan, DateTime date) {
    final meals = getMealsForDay(plan, date);

    return meals.fold(
      MacroNutrients.zero(),
      (sum, meal) => sum + calculateMacrosForMealEntry(meal),
    );
  }

  // -----------------------------------------------------------------------
  // MAKRO-BERECHNUNG FÜR MEHRERE TAGE
  // -----------------------------------------------------------------------

  /// Berechnet die Makros für jeden Tag in einem Zeitraum.
  ///
  /// Gibt eine Map zurück mit dateKey -> MacroNutrients.
  Map<String, MacroNutrients> calculateMacrosForDateRange(
    NutritionPlan plan,
    DateTime startDate,
    DateTime endDate,
  ) {
    final result = <String, MacroNutrients>{};

    var current = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (!current.isAfter(end)) {
      result[dateKey(current)] = calculateMacrosForDay(plan, current);
      current = current.add(const Duration(days: 1));
    }

    return result;
  }

  /// Berechnet die Summe aller Makros über einen Zeitraum.
  MacroNutrients calculateTotalMacrosForDateRange(
    NutritionPlan plan,
    DateTime startDate,
    DateTime endDate,
  ) {
    final dailyMacros = calculateMacrosForDateRange(plan, startDate, endDate);

    return dailyMacros.values.fold(
      MacroNutrients.zero(),
      (sum, macros) => sum + macros,
    );
  }

  /// Berechnet den Durchschnitt der Makros über einen Zeitraum.
  MacroNutrients calculateAverageMacrosForDateRange(
    NutritionPlan plan,
    DateTime startDate,
    DateTime endDate,
  ) {
    final dailyMacros = calculateMacrosForDateRange(plan, startDate, endDate);
    final dayCount = dailyMacros.length;

    if (dayCount == 0) {
      return MacroNutrients.zero();
    }

    final total = dailyMacros.values.fold(
      MacroNutrients.zero(),
      (sum, macros) => sum + macros,
    );

    return total.scale(1.0 / dayCount);
  }

  // -----------------------------------------------------------------------
  // ANALYSE & VERGLEICH MIT ZIELEN
  // -----------------------------------------------------------------------

  /// Vergleicht die tatsächlichen Makros eines Tages mit den Zielen.
  ///
  /// Gibt die Differenz zurück (positiv = über dem Ziel, negativ = unter dem Ziel).
  MacroNutrients calculateDifferenceToTarget(
    NutritionPlan plan,
    DateTime date,
  ) {
    final actual = calculateMacrosForDay(plan, date);
    final target = plan.dailyMacroTargets;

    return MacroNutrients(
      calories: actual.calories - target.calories,
      protein: actual.protein - target.protein,
      carbs: actual.carbs - target.carbs,
      fat: actual.fat - target.fat,
      sugar: actual.sugar - target.sugar,
    );
  }

  /// Berechnet den prozentualen Erfüllungsgrad der Ziele für einen Tag.
  ///
  /// 100 = exakt auf Ziel, >100 = über Ziel, <100 = unter Ziel.
  Map<String, double> calculateTargetPercentages(
    NutritionPlan plan,
    DateTime date,
  ) {
    final actual = calculateMacrosForDay(plan, date);
    final target = plan.dailyMacroTargets;

    double percentage(double actual, double target) {
      if (target == 0) return actual == 0 ? 100 : double.infinity;
      return (actual / target) * 100;
    }

    return {
      'calories': percentage(actual.calories, target.calories),
      'protein': percentage(actual.protein, target.protein),
      'carbs': percentage(actual.carbs, target.carbs),
      'fat': percentage(actual.fat, target.fat),
      'sugar': percentage(actual.sugar, target.sugar),
    };
  }

  // -----------------------------------------------------------------------
  // PLAN MUTATIONS (Pure functions returning new plan)
  // -----------------------------------------------------------------------

  /// Fügt ein RecurringMealTemplate zum Plan hinzu.
  ///
  /// Gibt einen neuen Plan mit dem hinzugefügten Template zurück.
  NutritionPlan addRecurringMeal(
    NutritionPlan plan,
    RecurringMealTemplate template,
  ) {
    return plan.copyWith(
      recurringMeals: [...plan.recurringMeals, template],
    );
  }

  /// Entfernt ein RecurringMealTemplate aus dem Plan.
  ///
  /// Sucht anhand der mealEntry.id und gibt den aktualisierten Plan zurück.
  /// Gibt null zurück, wenn das Meal nicht gefunden wurde.
  NutritionPlan? removeRecurringMeal(
    NutritionPlan plan,
    String mealEntryId,
  ) {
    final templateIndex = plan.recurringMeals.indexWhere(
      (t) => t.mealEntry.id == mealEntryId,
    );

    if (templateIndex == -1) {
      return null;
    }

    final updatedMeals = List<RecurringMealTemplate>.from(plan.recurringMeals)
      ..removeAt(templateIndex);

    return plan.copyWith(recurringMeals: updatedMeals);
  }

  /// Fügt ein zusätzliches Meal für einen bestimmten Tag hinzu.
  ///
  /// Erstellt oder aktualisiert das DayOverride für diesen Tag.
  NutritionPlan addAdditionalMealToDay(
    NutritionPlan plan,
    DateTime date,
    MealEntry meal,
  ) {
    final key = dateKey(date);
    final existingOverride = plan.dayOverrides[key];

    final newOverride = DayOverride(
      dateKey: key,
      hiddenRecurringMealTemplateIds:
          existingOverride?.hiddenRecurringMealTemplateIds ?? [],
      additionalMeals: [...?existingOverride?.additionalMeals, meal],
    );

    return plan.copyWith(
      dayOverrides: {...plan.dayOverrides, key: newOverride},
    );
  }

  /// Entfernt ein zusätzliches Meal von einem bestimmten Tag.
  ///
  /// Gibt null zurück, wenn das Meal nicht in additionalMeals gefunden wurde.
  NutritionPlan? removeAdditionalMealFromDay(
    NutritionPlan plan,
    DateTime date,
    String mealId,
  ) {
    final key = dateKey(date);
    final existingOverride = plan.dayOverrides[key];

    if (existingOverride == null) {
      return null;
    }

    final updatedMeals = existingOverride.additionalMeals
        .where((m) => m.id != mealId)
        .toList();

    // Wenn keine Änderung, war das Meal nicht in additionalMeals
    if (updatedMeals.length == existingOverride.additionalMeals.length) {
      return null;
    }

    final newOverride = existingOverride.copyWith(
      additionalMeals: updatedMeals,
    );

    return plan.copyWith(
      dayOverrides: {...plan.dayOverrides, key: newOverride},
    );
  }

  /// Blendet ein wiederkehrendes Meal für einen bestimmten Tag aus.
  ///
  /// Fügt die Template-ID zu hiddenRecurringMealTemplateIds hinzu.
  NutritionPlan hideMealForDay(
    NutritionPlan plan,
    DateTime date,
    String mealEntryId,
  ) {
    // Finde das Template mit dieser mealEntry.id
    final template = plan.recurringMeals.firstWhere(
      (t) => t.mealEntry.id == mealEntryId,
      orElse: () => plan.recurringMeals.first,
    );

    final key = dateKey(date);
    final existingOverride = plan.dayOverrides[key];

    final hiddenIds = [
      ...?existingOverride?.hiddenRecurringMealTemplateIds,
      template.id,
    ];

    final newOverride = DayOverride(
      dateKey: key,
      hiddenRecurringMealTemplateIds: hiddenIds,
      additionalMeals: existingOverride?.additionalMeals ?? [],
    );

    return plan.copyWith(
      dayOverrides: {...plan.dayOverrides, key: newOverride},
    );
  }

  /// Entfernt ein Meal aus dem Plan (recurring oder additional).
  ///
  /// Versucht zuerst, es als recurring meal zu entfernen.
  /// Falls nicht gefunden, versucht es als additional meal für den Tag.
  /// Gibt den aktualisierten Plan oder null zurück.
  ({NutritionPlan plan, bool wasRecurring})? removeMealFromPlan(
    NutritionPlan plan,
    DateTime date,
    String mealId,
  ) {
    // 1. Versuche als recurring meal zu entfernen
    final planWithoutRecurring = removeRecurringMeal(plan, mealId);
    if (planWithoutRecurring != null) {
      return (plan: planWithoutRecurring, wasRecurring: true);
    }

    // 2. Versuche als additional meal zu entfernen
    final planWithoutAdditional = removeAdditionalMealFromDay(
      plan,
      date,
      mealId,
    );
    if (planWithoutAdditional != null) {
      return (plan: planWithoutAdditional, wasRecurring: false);
    }

    return null;
  }
}
