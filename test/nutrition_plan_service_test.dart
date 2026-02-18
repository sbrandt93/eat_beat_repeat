// test/nutrition_plan_service_test.dart
import 'package:eat_beat_repeat/logic/models/day_override.dart';
import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:eat_beat_repeat/logic/models/meal_entry.dart';
import 'package:eat_beat_repeat/logic/models/nutrition_plan.dart';
import 'package:eat_beat_repeat/logic/models/recipe.dart';
import 'package:eat_beat_repeat/logic/models/recipe_ingredient.dart';
import 'package:eat_beat_repeat/logic/models/recurrence_rule.dart';
import 'package:eat_beat_repeat/logic/models/recurring_meal_template.dart';
import 'package:eat_beat_repeat/logic/services/nutrition_plan_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ============ TEST DATA ============
  late FoodData milkData;
  late FoodData oatsData;
  late FoodData bananaData;
  late FoodData chickenData;
  late Recipe oatmealRecipe;
  late Map<String, FoodData> foodDataMap;
  late Map<String, Recipe> recipeMap;
  late NutritionPlanService service;

  setUp(() {
    // Milch: 64 kcal, 3.4g Protein, 4.8g Carbs, 3.6g Fat pro 100ml
    milkData = FoodData(
      name: 'Milch',
      brandName: 'Generic',
      macrosPer100unit: MacroNutrients(
        calories: 64,
        protein: 3.4,
        carbs: 4.8,
        fat: 3.6,
        sugar: 4.8,
      ),
      defaultUnit: 'ml',
    );

    // Haferflocken: 372 kcal, 13.5g Protein, 58.7g Carbs, 7.0g Fat pro 100g
    oatsData = FoodData(
      name: 'Haferflocken',
      brandName: 'Kölln',
      macrosPer100unit: MacroNutrients(
        calories: 372,
        protein: 13.5,
        carbs: 58.7,
        fat: 7.0,
        sugar: 1.0,
      ),
      defaultUnit: 'g',
    );

    // Banane: 89 kcal, 1.1g Protein, 22.8g Carbs, 0.3g Fat pro 100g
    bananaData = FoodData(
      name: 'Banane',
      brandName: '',
      macrosPer100unit: MacroNutrients(
        calories: 89,
        protein: 1.1,
        carbs: 22.8,
        fat: 0.3,
        sugar: 12.2,
      ),
      defaultUnit: 'g',
    );

    // Hähnchenbrust: 165 kcal, 31g Protein, 0g Carbs, 3.6g Fat pro 100g
    chickenData = FoodData(
      name: 'Hähnchenbrust',
      brandName: '',
      macrosPer100unit: MacroNutrients(
        calories: 165,
        protein: 31,
        carbs: 0,
        fat: 3.6,
        sugar: 0,
      ),
      defaultUnit: 'g',
    );

    foodDataMap = {
      milkData.id: milkData,
      oatsData.id: oatsData,
      bananaData.id: bananaData,
      chickenData.id: chickenData,
    };

    // Porridge Rezept: 80g Hafer + 300ml Milch
    // Hafer (80g): 297.6 kcal, 10.8g Protein, 46.96g Carbs, 5.6g Fat
    // Milch (300ml): 192 kcal, 10.2g Protein, 14.4g Carbs, 10.8g Fat
    // Total: 489.6 kcal, 21g Protein, 61.36g Carbs, 16.4g Fat
    oatmealRecipe = Recipe(
      name: 'Porridge',
      ingredients: [
        RecipeIngredient(foodDataId: oatsData.id, quantity: 80),
        RecipeIngredient(foodDataId: milkData.id, quantity: 300),
      ],
    );

    recipeMap = {oatmealRecipe.id: oatmealRecipe};

    service = NutritionPlanService(
      foodDataMap: foodDataMap,
      recipeMap: recipeMap,
    );
  });

  // ============ HELPER TESTS ============
  group('NutritionPlanService - Helper', () {
    test('dateKey formatiert korrekt', () {
      expect(service.dateKey(DateTime(2026, 2, 9)), '2026-02-09');
      expect(service.dateKey(DateTime(2026, 12, 31)), '2026-12-31');
      expect(service.dateKey(DateTime(2026, 1, 1)), '2026-01-01');
    });
  });

  // ============ MEALS FOR DAY TESTS ============
  group('NutritionPlanService - getMealsForDay', () {
    test('gibt recurring meals für zutreffenden Tag zurück', () {
      final plan = NutritionPlan(
        name: 'Test',
        startDate: DateTime(2026, 2, 1),
        recurringMeals: [
          RecurringMealTemplate(
            mealEntry: FoodEntry(
              name: 'Banane',
              foodDataId: bananaData.id,
              quantity: 120,
            ),
            rule: RecurrenceRule.daily(),
          ),
        ],
        dayOverrides: {},
        dailyMacroTargets: MacroNutrients.zero(),
      );

      final meals = service.getMealsForDay(plan, DateTime(2026, 2, 9));

      expect(meals, hasLength(1));
      expect(meals[0], isA<FoodEntry>());
      expect((meals[0] as FoodEntry).name, 'Banane');
    });

    test('filtert recurring meals nach RecurrenceRule', () {
      final plan = NutritionPlan(
        name: 'Test',
        startDate: DateTime(2026, 2, 1),
        recurringMeals: [
          RecurringMealTemplate(
            mealEntry: FoodEntry(
              name: 'Banane täglich',
              foodDataId: bananaData.id,
              quantity: 120,
            ),
            rule: RecurrenceRule.daily(),
          ),
          RecurringMealTemplate(
            mealEntry: RecipeEntry(
              name: 'Porridge wochentags',
              recipeId: oatmealRecipe.id,
              servings: 1,
            ),
            rule: RecurrenceRule.weekdays(),
          ),
        ],
        dayOverrides: {},
        dailyMacroTargets: MacroNutrients.zero(),
      );

      // Montag - beide aktiv
      final mondayMeals = service.getMealsForDay(plan, DateTime(2026, 2, 9));
      expect(mondayMeals, hasLength(2));

      // Sonntag - nur Banane
      final sundayMeals = service.getMealsForDay(plan, DateTime(2026, 2, 8));
      expect(sundayMeals, hasLength(1));
      expect(sundayMeals[0].name, 'Banane täglich');
    });

    test('berücksichtigt hiddenRecurringMealTemplateIds', () {
      final bananaTemplate = RecurringMealTemplate(
        mealEntry: FoodEntry(
          name: 'Banane',
          foodDataId: bananaData.id,
          quantity: 120,
        ),
        rule: RecurrenceRule.daily(),
      );

      final plan = NutritionPlan(
        name: 'Test',
        startDate: DateTime(2026, 2, 1),
        recurringMeals: [bananaTemplate],
        dayOverrides: {
          '2026-02-10': DayOverride(
            dateKey: '2026-02-10',
            hiddenRecurringMealTemplateIds: [bananaTemplate.id],
            additionalMeals: [],
          ),
        },
        dailyMacroTargets: MacroNutrients.zero(),
      );

      // 10.2. - Banane versteckt
      final meals10 = service.getMealsForDay(plan, DateTime(2026, 2, 10));
      expect(meals10, isEmpty);

      // 11.2. - Banane wieder da
      final meals11 = service.getMealsForDay(plan, DateTime(2026, 2, 11));
      expect(meals11, hasLength(1));
    });

    test('fügt additionalMeals aus DayOverride hinzu', () {
      final plan = NutritionPlan(
        name: 'Test',
        startDate: DateTime(2026, 2, 1),
        recurringMeals: [
          RecurringMealTemplate(
            mealEntry: FoodEntry(
              name: 'Banane',
              foodDataId: bananaData.id,
              quantity: 120,
            ),
            rule: RecurrenceRule.daily(),
          ),
        ],
        dayOverrides: {
          '2026-02-10': DayOverride(
            dateKey: '2026-02-10',
            hiddenRecurringMealTemplateIds: [],
            additionalMeals: [
              FoodEntry(
                name: 'Extra Chicken',
                foodDataId: chickenData.id,
                quantity: 200,
              ),
            ],
          ),
        },
        dailyMacroTargets: MacroNutrients.zero(),
      );

      // 10.2. - Banane + Extra Chicken
      final meals10 = service.getMealsForDay(plan, DateTime(2026, 2, 10));
      expect(meals10, hasLength(2));
      expect(
        meals10.map((m) => m.name),
        containsAll(['Banane', 'Extra Chicken']),
      );
    });
  });

  // ============ MACRO CALCULATION TESTS ============
  group('NutritionPlanService - calculateMacrosForMealEntry', () {
    test('berechnet Makros für FoodEntry korrekt', () {
      final entry = FoodEntry(
        name: 'Banane',
        foodDataId: bananaData.id,
        quantity: 200, // 200g
      );

      final macros = service.calculateMacrosForMealEntry(entry);

      // 200g Banane = 2x Makros pro 100g
      expect(macros.calories, closeTo(178, 0.1)); // 89 * 2
      expect(macros.protein, closeTo(2.2, 0.1)); // 1.1 * 2
      expect(macros.carbs, closeTo(45.6, 0.1)); // 22.8 * 2
      expect(macros.fat, closeTo(0.6, 0.1)); // 0.3 * 2
    });

    test('berechnet Makros für RecipeEntry korrekt', () {
      final entry = RecipeEntry(
        name: 'Porridge',
        recipeId: oatmealRecipe.id,
        servings: 1.0,
      );

      final macros = service.calculateMacrosForMealEntry(entry);

      // 80g Haferflocken + 300ml Milch
      // Hafer: 80/100 * 372 = 297.6 kcal
      // Milch: 300/100 * 64 = 192 kcal
      // Total: 489.6 kcal
      expect(macros.calories, closeTo(489.6, 0.1));
    });

    test('skaliert RecipeEntry nach servings', () {
      final halfServing = RecipeEntry(
        name: 'Porridge',
        recipeId: oatmealRecipe.id,
        servings: 0.5,
      );

      final macros = service.calculateMacrosForMealEntry(halfServing);

      // Halbe Portion = 244.8 kcal
      expect(macros.calories, closeTo(244.8, 0.1));
    });

    test('gibt zero für unbekannte FoodData zurück', () {
      final entry = FoodEntry(
        name: 'Unknown',
        foodDataId: 'does-not-exist',
        quantity: 100,
      );

      final macros = service.calculateMacrosForMealEntry(entry);

      expect(macros.calories, 0);
      expect(macros.protein, 0);
    });

    test('gibt zero für unbekanntes Recipe zurück', () {
      final entry = RecipeEntry(
        name: 'Unknown Recipe',
        recipeId: 'does-not-exist',
        servings: 1,
      );

      final macros = service.calculateMacrosForMealEntry(entry);

      expect(macros.calories, 0);
    });
  });

  // ============ DAILY MACRO CALCULATION TESTS ============
  group('NutritionPlanService - calculateMacrosForDay', () {
    test('summiert alle Meals eines Tages', () {
      final plan = NutritionPlan(
        name: 'Test',
        startDate: DateTime(2026, 2, 1),
        recurringMeals: [
          // Banane 120g täglich: 106.8 kcal
          RecurringMealTemplate(
            mealEntry: FoodEntry(
              name: 'Banane',
              foodDataId: bananaData.id,
              quantity: 120,
            ),
            rule: RecurrenceRule.daily(),
          ),
          // Porridge wochentags: 489.6 kcal
          RecurringMealTemplate(
            mealEntry: RecipeEntry(
              name: 'Porridge',
              recipeId: oatmealRecipe.id,
              servings: 1,
            ),
            rule: RecurrenceRule.weekdays(),
          ),
        ],
        dayOverrides: {},
        dailyMacroTargets: MacroNutrients.zero(),
      );

      // Montag: Banane + Porridge = 106.8 + 489.6 = 596.4 kcal
      final mondayMacros = service.calculateMacrosForDay(
        plan,
        DateTime(2026, 2, 9),
      );
      expect(mondayMacros.calories, closeTo(596.4, 0.1));

      // Sonntag: nur Banane = 106.8 kcal
      final sundayMacros = service.calculateMacrosForDay(
        plan,
        DateTime(2026, 2, 8),
      );
      expect(sundayMacros.calories, closeTo(106.8, 0.1));
    });

    test('berücksichtigt DayOverride bei Tagesberechnung', () {
      final bananaTemplate = RecurringMealTemplate(
        mealEntry: FoodEntry(
          name: 'Banane',
          foodDataId: bananaData.id,
          quantity: 120, // 106.8 kcal
        ),
        rule: RecurrenceRule.daily(),
      );

      final plan = NutritionPlan(
        name: 'Test',
        startDate: DateTime(2026, 2, 1),
        recurringMeals: [bananaTemplate],
        dayOverrides: {
          '2026-02-10': DayOverride(
            dateKey: '2026-02-10',
            hiddenRecurringMealTemplateIds: [bananaTemplate.id],
            additionalMeals: [
              // Chicken 200g: 330 kcal
              FoodEntry(
                name: 'Chicken',
                foodDataId: chickenData.id,
                quantity: 200,
              ),
            ],
          ),
        },
        dailyMacroTargets: MacroNutrients.zero(),
      );

      // 10.2.: Banane versteckt, nur Chicken = 330 kcal
      final macros10 = service.calculateMacrosForDay(
        plan,
        DateTime(2026, 2, 10),
      );
      expect(macros10.calories, closeTo(330, 0.1));
      expect(macros10.protein, closeTo(62, 0.1)); // 31 * 2

      // 11.2.: nur Banane = 106.8 kcal
      final macros11 = service.calculateMacrosForDay(
        plan,
        DateTime(2026, 2, 11),
      );
      expect(macros11.calories, closeTo(106.8, 0.1));
    });
  });

  // ============ DATE RANGE TESTS ============
  group('NutritionPlanService - calculateMacrosForDateRange', () {
    test('berechnet Makros für jeden Tag im Bereich', () {
      final plan = NutritionPlan(
        name: 'Test',
        startDate: DateTime(2026, 2, 1),
        recurringMeals: [
          RecurringMealTemplate(
            mealEntry: FoodEntry(
              name: 'Banane',
              foodDataId: bananaData.id,
              quantity: 100, // 89 kcal
            ),
            rule: RecurrenceRule.daily(),
          ),
        ],
        dayOverrides: {},
        dailyMacroTargets: MacroNutrients.zero(),
      );

      // 3 Tage: 9., 10., 11. Februar
      final macrosPerDay = service.calculateMacrosForDateRange(
        plan,
        DateTime(2026, 2, 9),
        DateTime(2026, 2, 11),
      );

      expect(macrosPerDay.length, 3);
      expect(macrosPerDay['2026-02-09']!.calories, closeTo(89, 0.1));
      expect(macrosPerDay['2026-02-10']!.calories, closeTo(89, 0.1));
      expect(macrosPerDay['2026-02-11']!.calories, closeTo(89, 0.1));
    });

    test('calculateTotalMacrosForDateRange summiert alle Tage', () {
      final plan = NutritionPlan(
        name: 'Test',
        startDate: DateTime(2026, 2, 1),
        recurringMeals: [
          RecurringMealTemplate(
            mealEntry: FoodEntry(
              name: 'Banane',
              foodDataId: bananaData.id,
              quantity: 100, // 89 kcal pro Tag
            ),
            rule: RecurrenceRule.daily(),
          ),
        ],
        dayOverrides: {},
        dailyMacroTargets: MacroNutrients.zero(),
      );

      // 7 Tage
      final total = service.calculateTotalMacrosForDateRange(
        plan,
        DateTime(2026, 2, 1),
        DateTime(2026, 2, 7),
      );

      expect(total.calories, closeTo(89 * 7, 0.1)); // 623 kcal
    });

    test('calculateAverageMacrosForDateRange berechnet Durchschnitt', () {
      final plan = NutritionPlan(
        name: 'Test',
        startDate: DateTime(2026, 2, 1),
        recurringMeals: [
          RecurringMealTemplate(
            mealEntry: FoodEntry(
              name: 'Banane',
              foodDataId: bananaData.id,
              quantity: 100, // 89 kcal
            ),
            rule: RecurrenceRule.daily(),
          ),
          RecurringMealTemplate(
            mealEntry: RecipeEntry(
              name: 'Porridge',
              recipeId: oatmealRecipe.id,
              servings: 1, // 489.6 kcal
            ),
            rule: RecurrenceRule.weekdays(),
          ),
        ],
        dayOverrides: {},
        dailyMacroTargets: MacroNutrients.zero(),
      );

      // Woche vom 2.-8.2.2026 (Mo bis So)
      // Mo-Fr: 89 + 489.6 = 578.6 kcal (5 Tage)
      // Sa-So: 89 kcal (2 Tage)
      // Total: 5 * 578.6 + 2 * 89 = 2893 + 178 = 3071 kcal
      // Average: 3071 / 7 = 438.7 kcal
      final average = service.calculateAverageMacrosForDateRange(
        plan,
        DateTime(2026, 2, 2), // Montag
        DateTime(2026, 2, 8), // Sonntag
      );

      expect(average.calories, closeTo(438.7, 1));
    });
  });

  // ============ TARGET COMPARISON TESTS ============
  group('NutritionPlanService - Target Comparison', () {
    test('calculateDifferenceToTarget zeigt Differenz zu Zielen', () {
      final plan = NutritionPlan(
        name: 'Test',
        startDate: DateTime(2026, 2, 1),
        recurringMeals: [
          RecurringMealTemplate(
            mealEntry: FoodEntry(
              name: 'Banane',
              foodDataId: bananaData.id,
              quantity: 200, // 178 kcal, 2.2g protein
            ),
            rule: RecurrenceRule.daily(),
          ),
        ],
        dayOverrides: {},
        dailyMacroTargets: MacroNutrients(
          calories: 2000,
          protein: 150,
          carbs: 200,
          fat: 70,
          sugar: 50,
        ),
      );

      final diff = service.calculateDifferenceToTarget(
        plan,
        DateTime(2026, 2, 9),
      );

      // 178 - 2000 = -1822 (unter Ziel)
      expect(diff.calories, closeTo(-1822, 1));
      // 2.2 - 150 = -147.8 (unter Ziel)
      expect(diff.protein, closeTo(-147.8, 0.1));
    });

    test('calculateTargetPercentages zeigt Erfüllungsgrad', () {
      final plan = NutritionPlan(
        name: 'Test',
        startDate: DateTime(2026, 2, 1),
        recurringMeals: [
          RecurringMealTemplate(
            mealEntry: FoodEntry(
              name: 'Doppelbanane',
              foodDataId: bananaData.id,
              quantity: 1000, // 890 kcal
            ),
            rule: RecurrenceRule.daily(),
          ),
        ],
        dayOverrides: {},
        dailyMacroTargets: MacroNutrients(
          calories: 2000,
          protein: 100,
          carbs: 200,
          fat: 50,
          sugar: 100,
        ),
      );

      final percentages = service.calculateTargetPercentages(
        plan,
        DateTime(2026, 2, 9),
      );

      // 890 / 2000 * 100 = 44.5%
      expect(percentages['calories'], closeTo(44.5, 0.1));
      // 11 / 100 * 100 = 11%
      expect(percentages['protein'], closeTo(11, 0.1));
      // 228 / 200 * 100 = 114%
      expect(percentages['carbs'], closeTo(114, 0.1));
    });

    test('calculateTargetPercentages behandelt zero target', () {
      final plan = NutritionPlan(
        name: 'Test',
        startDate: DateTime(2026, 2, 1),
        recurringMeals: [],
        dayOverrides: {},
        dailyMacroTargets: MacroNutrients.zero(),
      );

      final percentages = service.calculateTargetPercentages(
        plan,
        DateTime(2026, 2, 9),
      );

      // 0 / 0 = 100% (beide null)
      expect(percentages['calories'], 100);
    });
  });

  // ============ COMPREHENSIVE INTEGRATION TEST ============
  group('NutritionPlanService - Integration', () {
    test('vollständiger Wochenplan mit verschiedenen Meals', () {
      final dailyBanana = RecurringMealTemplate(
        mealEntry: FoodEntry(
          name: 'Banane zum Frühstück',
          foodDataId: bananaData.id,
          quantity: 120, // 106.8 kcal, 1.32g protein, 27.36g carbs, 0.36g fat
        ),
        rule: RecurrenceRule.daily(),
      );

      final weekdayPorridge = RecurringMealTemplate(
        mealEntry: RecipeEntry(
          name: 'Porridge',
          recipeId: oatmealRecipe.id,
          servings: 1, // 489.6 kcal
        ),
        rule: RecurrenceRule.weekdays(),
      );

      final weekendChicken = RecurringMealTemplate(
        mealEntry: FoodEntry(
          name: 'Hähnchen am Wochenende',
          foodDataId: chickenData.id,
          quantity: 250, // 412.5 kcal, 77.5g protein
        ),
        rule: RecurrenceRule.weekends(),
      );

      final plan = NutritionPlan(
        name: 'Mein Wochenplan',
        startDate: DateTime(2026, 2, 2), // Montag
        endDate: DateTime(2026, 2, 8), // Sonntag
        recurringMeals: [dailyBanana, weekdayPorridge, weekendChicken],
        dayOverrides: {
          // Mittwoch: Extra Snack
          '2026-02-04': DayOverride(
            dateKey: '2026-02-04',
            hiddenRecurringMealTemplateIds: [],
            additionalMeals: [
              FoodEntry(
                name: 'Nachmittags-Snack',
                foodDataId: bananaData.id,
                quantity: 80, // 71.2 kcal
              ),
            ],
          ),
          // Freitag: Kein Porridge
          '2026-02-06': DayOverride(
            dateKey: '2026-02-06',
            hiddenRecurringMealTemplateIds: [weekdayPorridge.id],
            additionalMeals: [],
          ),
        },
        dailyMacroTargets: MacroNutrients(
          calories: 2000,
          protein: 150,
          carbs: 200,
          fat: 70,
          sugar: 50,
        ),
      );

      // Montag: Banane(106.8) + Porridge(489.6) = 596.4 kcal
      final monday = service.calculateMacrosForDay(plan, DateTime(2026, 2, 2));
      expect(monday.calories, closeTo(596.4, 0.1));

      // Mittwoch: Banane + Porridge + Extra Snack(71.2) = 667.6 kcal
      final wednesday = service.calculateMacrosForDay(
        plan,
        DateTime(2026, 2, 4),
      );
      expect(wednesday.calories, closeTo(667.6, 0.1));

      // Freitag: nur Banane (Porridge versteckt) = 106.8 kcal
      final friday = service.calculateMacrosForDay(plan, DateTime(2026, 2, 6));
      expect(friday.calories, closeTo(106.8, 0.1));

      // Samstag: Banane(106.8) + Chicken(412.5) = 519.3 kcal
      final saturday = service.calculateMacrosForDay(
        plan,
        DateTime(2026, 2, 7),
      );
      expect(saturday.calories, closeTo(519.3, 0.1));
      expect(saturday.protein, closeTo(78.82, 0.1)); // 1.32 + 77.5

      // Gesamtwoche berechnen
      final weeklyMacros = service.calculateMacrosForDateRange(
        plan,
        DateTime(2026, 2, 2),
        DateTime(2026, 2, 8),
      );

      expect(weeklyMacros.length, 7);

      // Ausgabe für Debugging/Dokumentation
      final dailyCalories = weeklyMacros.entries.map(
        (e) => '${e.key}: ${e.value.calories.toStringAsFixed(1)} kcal',
      );
      print('=== Wochenübersicht ===');
      print(dailyCalories.join('\n'));

      // Total der Woche
      final totalWeek = service.calculateTotalMacrosForDateRange(
        plan,
        DateTime(2026, 2, 2),
        DateTime(2026, 2, 8),
      );

      print('\n=== Wochen-Total ===');
      print('Calories: ${totalWeek.calories.toStringAsFixed(1)}');
      print('Protein: ${totalWeek.protein.toStringAsFixed(1)}g');
      print('Carbs: ${totalWeek.carbs.toStringAsFixed(1)}g');
      print('Fat: ${totalWeek.fat.toStringAsFixed(1)}g');

      // Wochendurchschnitt
      final avgWeek = service.calculateAverageMacrosForDateRange(
        plan,
        DateTime(2026, 2, 2),
        DateTime(2026, 2, 8),
      );

      print('\n=== Tages-Durchschnitt ===');
      print('Calories: ${avgWeek.calories.toStringAsFixed(1)}');
      print('Protein: ${avgWeek.protein.toStringAsFixed(1)}g');
      print('Carbs: ${avgWeek.carbs.toStringAsFixed(1)}g');
      print('Fat: ${avgWeek.fat.toStringAsFixed(1)}g');

      // Verifiziere dass wir sinnvolle Werte haben
      expect(totalWeek.calories, greaterThan(0));
      expect(avgWeek.calories, greaterThan(0));
    });
  });
}
