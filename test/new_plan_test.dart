// test/new_plan_test.dart
import 'package:eat_beat_repeat/logic/utils/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eat_beat_repeat/logic/models/meal_entry.dart';
import 'package:eat_beat_repeat/logic/models/nutrition_plan.dart';
import 'package:eat_beat_repeat/logic/models/recurring_meal_template.dart';
import 'package:eat_beat_repeat/logic/models/day_override.dart';
import 'package:eat_beat_repeat/logic/models/recurrence_rule.dart';
import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/models/recipe.dart';
import 'package:eat_beat_repeat/logic/models/recipe_ingredient.dart';
import 'package:eat_beat_repeat/logic/services/macro_service.dart';

void main() {
  // ============ TEST DATA ============
  late FoodData milkData;
  late FoodData oatsData;
  late FoodData bananaData;
  late Recipe oatmealRecipe;
  late Map<String, FoodData> foodDataMap;
  late Map<String, Recipe> recipeMap;

  setUp(() {
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

    foodDataMap = {
      milkData.id: milkData,
      oatsData.id: oatsData,
      bananaData.id: bananaData,
    };

    oatmealRecipe = Recipe(
      name: 'Porridge',
      ingredients: [
        RecipeIngredient(foodDataId: oatsData.id, quantity: 80),
        RecipeIngredient(foodDataId: milkData.id, quantity: 300),
      ],
    );

    recipeMap = {oatmealRecipe.id: oatmealRecipe};
  });

  // ============ MEAL ENTRY TESTS ============
  group('MealEntry (sealed class)', () {
    test('FoodEntry erstellen und Eigenschaften prüfen', () {
      final entry = FoodEntry(
        name: 'Banane',
        foodDataId: bananaData.id,
        quantity: 120,
      );

      expect(entry.name, 'Banane');
      expect(entry.foodDataId, bananaData.id);
      expect(entry.quantity, 120);
      expect(entry.id, isNotEmpty);
    });

    test('RecipeEntry erstellen und Eigenschaften prüfen', () {
      final entry = RecipeEntry(
        name: 'Porridge',
        recipeId: oatmealRecipe.id,
        servings: 1.5,
      );

      expect(entry.name, 'Porridge');
      expect(entry.recipeId, oatmealRecipe.id);
      expect(entry.servings, 1.5);
    });

    test('FoodEntry JSON round-trip', () {
      final original = FoodEntry(
        name: 'Banane',
        foodDataId: 'food-123',
        quantity: 120,
      );

      final json = original.toJson();
      expect(json['type'], 'Food');

      final restored = MealEntry.fromJson(json);
      expect(restored, isA<FoodEntry>());
      expect((restored as FoodEntry).foodDataId, 'food-123');
      expect(restored.quantity, 120);
    });

    test('RecipeEntry JSON round-trip', () {
      final original = RecipeEntry(
        name: 'Porridge',
        recipeId: 'recipe-456',
        servings: 2.0,
      );

      final json = original.toJson();
      expect(json['type'], 'Recipe');

      final restored = MealEntry.fromJson(json);
      expect(restored, isA<RecipeEntry>());
      expect((restored as RecipeEntry).recipeId, 'recipe-456');
      expect(restored.servings, 2.0);
    });

    test('MealEntry.fromJson wirft bei unbekanntem Typ', () {
      expect(
        () => MealEntry.fromJson({'type': 'Unknown', 'id': '1', 'name': 'X'}),
        throwsArgumentError,
      );
    });

    test('Pattern Matching funktioniert mit sealed class', () {
      final List<MealEntry> meals = [
        FoodEntry(name: 'Banane', foodDataId: 'f1', quantity: 100),
        RecipeEntry(name: 'Porridge', recipeId: 'r1', servings: 1),
      ];

      final types = meals
          .map(
            (meal) => switch (meal) {
              FoodEntry _ => 'food',
              RecipeEntry _ => 'recipe',
            },
          )
          .toList();

      expect(types, ['food', 'recipe']);
    });
  });

  // ============ RECURRENCE RULE TESTS ============
  group('RecurrenceRule', () {
    test('daily gilt für jeden Tag', () {
      final rule = RecurrenceRule.daily();
      expect(rule.appliesToDate(DateTime(2026, 2, 8)), isTrue); // Sonntag
      expect(rule.appliesToDate(DateTime(2026, 2, 9)), isTrue); // Montag
    });

    test('weekdays gilt Mo-Fr', () {
      final rule = RecurrenceRule.weekdays();
      expect(rule.appliesToDate(DateTime(2026, 2, 9)), isTrue); // Montag
      expect(rule.appliesToDate(DateTime(2026, 2, 13)), isTrue); // Freitag
      expect(rule.appliesToDate(DateTime(2026, 2, 8)), isFalse); // Sonntag
      expect(rule.appliesToDate(DateTime(2026, 2, 14)), isFalse); // Samstag
    });

    test('weekends gilt Sa-So', () {
      final rule = RecurrenceRule.weekends();
      expect(rule.appliesToDate(DateTime(2026, 2, 8)), isTrue); // Sonntag
      expect(rule.appliesToDate(DateTime(2026, 2, 14)), isTrue); // Samstag
      expect(rule.appliesToDate(DateTime(2026, 2, 9)), isFalse); // Montag
    });

    test('specificDays gilt nur für ausgewählte Tage', () {
      // Montag (1) und Mittwoch (3)
      final rule = RecurrenceRule.specificDaysOfWeek([1, 3]);
      expect(rule.appliesToDate(DateTime(2026, 2, 9)), isTrue); // Montag
      expect(rule.appliesToDate(DateTime(2026, 2, 11)), isTrue); // Mittwoch
      expect(rule.appliesToDate(DateTime(2026, 2, 10)), isFalse); // Dienstag
    });

    test('RecurrenceRule JSON round-trip', () {
      final original = RecurrenceRule.specificDaysOfWeek([1, 3, 5]);
      final json = original.toJson();
      final restored = RecurrenceRule.fromJson(json);

      expect(restored.pattern, RecurrencePattern.specificDaysOfWeek);
      expect(restored.daysOfWeek, [1, 3, 5]);
    });
  });

  // ============ RECURRING MEAL TEMPLATE TESTS ============
  group('RecurringMealTemplate', () {
    test('appliesToDate delegiert an RecurrenceRule', () {
      final template = RecurringMealTemplate(
        mealEntry: FoodEntry(
          name: 'Banane',
          foodDataId: bananaData.id,
          quantity: 120,
        ),
        rule: RecurrenceRule.weekdays(),
      );

      expect(template.appliesToDate(DateTime(2026, 2, 9)), isTrue); // Mo
      expect(template.appliesToDate(DateTime(2026, 2, 8)), isFalse); // So
    });

    test('RecurringMealTemplate JSON round-trip mit FoodEntry', () {
      final original = RecurringMealTemplate(
        mealEntry: FoodEntry(
          name: 'Banane',
          foodDataId: 'food-id',
          quantity: 120,
        ),
        rule: RecurrenceRule.daily(),
      );

      final json = original.toJson();
      final restored = RecurringMealTemplate.fromJson(json);

      expect(restored.mealEntry, isA<FoodEntry>());
      expect((restored.mealEntry as FoodEntry).quantity, 120);
      expect(restored.rule.pattern, RecurrencePattern.daily);
    });

    test('RecurringMealTemplate JSON round-trip mit RecipeEntry', () {
      final original = RecurringMealTemplate(
        mealEntry: RecipeEntry(
          name: 'Porridge',
          recipeId: 'recipe-id',
          servings: 1.5,
        ),
        rule: RecurrenceRule.weekends(),
      );

      final json = original.toJson();
      final restored = RecurringMealTemplate.fromJson(json);

      expect(restored.mealEntry, isA<RecipeEntry>());
      expect((restored.mealEntry as RecipeEntry).servings, 1.5);
    });
  });

  // ============ DAY OVERRIDE TESTS ============
  group('DayOverride', () {
    test('Erstellen mit versteckten Templates und zusätzlichen Meals', () {
      final override = DayOverride(
        dateKey: '2026-02-08',
        hiddenRecurringMealTemplateIds: ['template-1', 'template-2'],
        additionalMeals: [
          FoodEntry(name: 'Snack', foodDataId: 'f1', quantity: 50),
        ],
      );

      expect(override.dateKey, '2026-02-08');
      expect(override.hiddenRecurringMealTemplateIds, hasLength(2));
      expect(override.additionalMeals, hasLength(1));
    });

    test('DayOverride JSON round-trip mit gemischten MealEntries', () {
      final original = DayOverride(
        dateKey: '2026-02-08',
        hiddenRecurringMealTemplateIds: ['t1'],
        additionalMeals: [
          FoodEntry(name: 'Snack', foodDataId: 'f1', quantity: 50),
          RecipeEntry(name: 'Shake', recipeId: 'r1', servings: 1),
        ],
      );

      final json = original.toJson();
      final restored = DayOverride.fromJson(json);

      expect(restored.additionalMeals, hasLength(2));
      expect(restored.additionalMeals[0], isA<FoodEntry>());
      expect(restored.additionalMeals[1], isA<RecipeEntry>());
    });
  });

  // ============ NUTRITION PLAN TESTS ============
  group('NutritionPlan', () {
    test('Erstellen eines NutritionPlans', () {
      final plan = NutritionPlan(
        name: 'Mein Plan',
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 28),
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
        dailyMacroTargets: MacroNutrients(
          calories: 2000,
          protein: 150,
          carbs: 200,
          fat: 70,
          sugar: 50,
        ),
      );

      expect(plan.name, 'Mein Plan');
      expect(plan.recurringMeals, hasLength(1));
      expect(plan.dailyMacroTargets.calories, 2000);
    });

    test('NutritionPlan JSON round-trip', () {
      final original = NutritionPlan(
        name: 'Test Plan',
        startDate: DateTime(2026, 2, 1),
        recurringMeals: [
          RecurringMealTemplate(
            mealEntry: FoodEntry(
              name: 'Banane',
              foodDataId: 'banana-id',
              quantity: 120,
            ),
            rule: RecurrenceRule.daily(),
          ),
          RecurringMealTemplate(
            mealEntry: RecipeEntry(
              name: 'Porridge',
              recipeId: 'porridge-id',
              servings: 1,
            ),
            rule: RecurrenceRule.weekdays(),
          ),
        ],
        dayOverrides: {
          '2026-02-10': DayOverride(
            dateKey: '2026-02-10',
            hiddenRecurringMealTemplateIds: [],
            additionalMeals: [
              FoodEntry(
                name: 'Snack',
                foodDataId: 'snack-id',
                quantity: 30,
              ),
            ],
          ),
        },
        dailyMacroTargets: MacroNutrients.zero(),
      );

      final json = original.toJson();
      final restored = NutritionPlan.fromJson(json);

      expect(restored.name, 'Test Plan');
      expect(restored.recurringMeals, hasLength(2));
      expect(restored.recurringMeals[0].mealEntry, isA<FoodEntry>());
      expect(restored.recurringMeals[1].mealEntry, isA<RecipeEntry>());
      expect(restored.dayOverrides, hasLength(1));
      expect(
        restored.dayOverrides['2026-02-10']!.additionalMeals,
        hasLength(1),
      );
    });

    test('NutritionPlan copyWith behält ID bei', () {
      final original = NutritionPlan(
        name: 'Original',
        startDate: DateTime(2026, 2, 1),
        recurringMeals: [],
        dayOverrides: {},
        dailyMacroTargets: MacroNutrients.zero(),
      );

      final modified = original.copyWith(name: 'Modified');

      expect(modified.id, original.id);
      expect(modified.name, 'Modified');
    });
  });

  // ============ MACRO SERVICE TESTS ============
  group('MacroService', () {
    late MacroService macroService;

    setUp(() {
      macroService = MacroService(foodDataMap: foodDataMap);
    });

    test('calculateMacrosForFoodEntry', () {
      final entry = FoodEntry(
        name: 'Banane',
        foodDataId: bananaData.id,
        quantity: 200, // 200g
      );

      final macros = macroService.calculateMacrosForFoodEntry(entry);

      // 200g Banane = 2x Makros pro 100g
      expect(macros.calories, closeTo(178, 0.1)); // 89 * 2
      expect(macros.protein, closeTo(2.2, 0.1)); // 1.1 * 2
    });

    test('calculateMacrosForRecipe', () {
      final macros = macroService.calculateMacrosForRecipe(oatmealRecipe);

      // 80g Haferflocken + 300ml Milch
      // Hafer: 80/100 * 372 = 297.6 kcal
      // Milch: 300/100 * 64 = 192 kcal
      // Total: 489.6 kcal
      expect(macros.calories, closeTo(489.6, 0.1));
    });

    test(
      'calculateMacrosForFoodEntry mit unbekannter foodDataId gibt zero',
      () {
        final entry = FoodEntry(
          name: 'Unknown',
          foodDataId: 'does-not-exist',
          quantity: 100,
        );

        final macros = macroService.calculateMacrosForFoodEntry(entry);
        expect(macros.calories, 0);
      },
    );
  });

  // ============ INTEGRATION: MEALS FOR DAY ============
  group('getMealsForDay (TODO: NutritionPlanService)', () {
    test('Recurring meals für einen Tag sammeln', () {
      final dailyBanana = RecurringMealTemplate(
        mealEntry: FoodEntry(
          name: 'Banane',
          foodDataId: bananaData.id,
          quantity: 120,
        ),
        rule: RecurrenceRule.daily(),
      );

      final weekdayPorridge = RecurringMealTemplate(
        mealEntry: RecipeEntry(
          name: 'Porridge',
          recipeId: oatmealRecipe.id,
          servings: 1,
        ),
        rule: RecurrenceRule.weekdays(),
      );

      final plan = NutritionPlan(
        name: 'Test',
        startDate: DateTime(2026, 2, 1),
        recurringMeals: [dailyBanana, weekdayPorridge],
        dayOverrides: {},
        dailyMacroTargets: MacroNutrients.zero(),
      );

      // Montag 9.2.2026 - beide sollten gelten
      final monday = DateTime(2026, 2, 9);
      final mondayMeals = plan.recurringMeals
          .where((t) => t.appliesToDate(monday))
          .map((t) => t.mealEntry)
          .toList();

      expect(mondayMeals, hasLength(2));

      // Sonntag 8.2.2026 - nur Banane
      final sunday = DateTime(2026, 2, 8);
      final sundayMeals = plan.recurringMeals
          .where((t) => t.appliesToDate(sunday))
          .map((t) => t.mealEntry)
          .toList();

      expect(sundayMeals, hasLength(1));
      expect(sundayMeals[0], isA<FoodEntry>());
    });

    test('DayOverride versteckt recurring meals', () {
      final template = RecurringMealTemplate(
        mealEntry: FoodEntry(
          name: 'Banane',
          foodDataId: bananaData.id,
          quantity: 120,
        ),
        rule: RecurrenceRule.daily(),
      );

      final override = DayOverride(
        dateKey: '2026-02-10',
        hiddenRecurringMealTemplateIds: [template.id],
        additionalMeals: [],
      );

      final plan = NutritionPlan(
        name: 'Test',
        startDate: DateTime(2026, 2, 1),
        recurringMeals: [template],
        dayOverrides: {'2026-02-10': override},
        dailyMacroTargets: MacroNutrients.zero(),
      );

      // Logik: Recurring meals filtern, dann Override anwenden
      String dateKey(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      List<MealEntry> getMealsForDay(DateTime date) {
        final key = dateKey(date);
        final override = plan.dayOverrides[key];
        final hiddenIds = override?.hiddenRecurringMealTemplateIds ?? [];

        final recurring = plan.recurringMeals
            .where((t) => t.appliesToDate(date) && !hiddenIds.contains(t.id))
            .map((t) => t.mealEntry)
            .toList();

        final additional = override?.additionalMeals ?? [];
        return [...recurring, ...additional];
      }

      // 10.2. - Banane ist versteckt
      final meals10 = getMealsForDay(DateTime(2026, 2, 10));
      expect(meals10, isEmpty);

      // 11.2. - Banane ist da
      final meals11 = getMealsForDay(DateTime(2026, 2, 11));
      expect(meals11, hasLength(1));
    });
  });
}
