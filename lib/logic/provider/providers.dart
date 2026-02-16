import 'package:eat_beat_repeat/backend/local_storage_service.dart';
import 'package:eat_beat_repeat/logic/interfaces/i_storage_service.dart';
import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/models/nutrition_plan.dart';
import 'package:eat_beat_repeat/logic/models/predefined_food.dart';
import 'package:eat_beat_repeat/logic/models/recipe.dart';
import 'package:eat_beat_repeat/logic/provider/food_data_notifier.dart';
import 'package:eat_beat_repeat/logic/provider/nutrition_plan_notifier.dart';
import 'package:eat_beat_repeat/logic/provider/predefined_food_notifier.dart';
import 'package:eat_beat_repeat/logic/provider/recipe_notifier.dart';
import 'package:eat_beat_repeat/logic/services/macro_service.dart';
import 'package:eat_beat_repeat/logic/services/nutrition_plan_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ======================================================================
// RIVERPOD PROVIDER
// ======================================================================

/// Die zentrale Quelle für alle Lebensmitteldaten in der App.
/// Liefert ein **[Map<String, FoodData>]**, wobei der Schlüssel
/// die eindeutige Lebensmittel-ID ist.
final foodDataMapProvider =
    StateNotifierProvider<FoodDataNotifier, Map<String, FoodData>>(
      (ref) {
        final storageService = ref.watch(storageServiceProvider);
        return FoodDataNotifier(storageService);
      },
    );

final activeFoodDataProvider = Provider<Map<String, FoodData>>((ref) {
  final allFoodData = ref.watch(foodDataMapProvider);
  return Map.fromEntries(
    allFoodData.entries.where((entry) => entry.value.deletedAt == null),
  );
});

final trashedFoodDataProvider = Provider<Map<String, FoodData>>((ref) {
  final allFoodData = ref.watch(foodDataMapProvider);
  return Map.fromEntries(
    allFoodData.entries.where((entry) => entry.value.deletedAt != null),
  );
});

// ======================================================================

/// Die zentrale Quelle für alle Ernährungspläne in der App.
/// Liefert ein **[Map<String, NutritionPlan>]**, wobei der Schlüssel
/// die eindeutige Plan-ID ist.
final nutritionPlanProvider =
    StateNotifierProvider<NutritionPlanNotifier, Map<String, NutritionPlan>>(
      (ref) {
        final storageService = ref.watch(storageServiceProvider);
        return NutritionPlanNotifier(storageService);
      },
    );

final activeNutritionPlansProvider = Provider<List<NutritionPlan>>((ref) {
  final allPlans = ref.watch(nutritionPlanProvider).values;
  return allPlans.where((plan) => plan.deletedAt == null).toList();
});

/// Der Provider für den NutritionPlanService.
/// Er erhält FoodDataMap und RecipeMap als Abhängigkeiten.
final nutritionPlanServiceProvider = Provider<NutritionPlanService>((ref) {
  final foodDataMap = ref.watch(foodDataMapProvider);
  final recipeMap = ref.watch(recipeProvider);
  return NutritionPlanService(
    foodDataMap: foodDataMap,
    recipeMap: recipeMap,
  );
});

// ======================================================================

/// Die zentrale Quelle für alle vordefinierten Lebensmittel in der App.
/// Liefert ein **[Map<String, PredefinedFood>]**, wobei der Schlüssel
/// die eindeutige PredefinedFood-ID ist.
final predefinedFoodProvider =
    StateNotifierProvider<PredefinedFoodNotifier, Map<String, PredefinedFood>>(
      (ref) {
        final storageService = ref.watch(storageServiceProvider);
        return PredefinedFoodNotifier(storageService);
      },
    );

// 2. Filter-Provider für die normale Ansicht (Aktiv)
final activePredefinedFoodsProvider = Provider<List<PredefinedFood>>((ref) {
  final allFoods = ref.watch(predefinedFoodProvider).values;
  return allFoods.where((food) => food.deletedAt == null).toList();
});

// 3. Filter-Provider für den Papierkorb
final trashedPredefinedFoodsProvider = Provider<List<PredefinedFood>>((ref) {
  final allFoods = ref.watch(predefinedFoodProvider).values;
  return allFoods.where((food) => food.deletedAt != null).toList();
});

// ======================================================================

/// Die zentrale Quelle für alle Rezepte in der App.
/// Liefert ein **[Map<String, Recipe>]**, wobei der Schlüssel
/// die eindeutige Recipe-ID ist.
final recipeProvider =
    StateNotifierProvider<RecipeNotifier, Map<String, Recipe>>(
      (ref) => RecipeNotifier(ref.watch(storageServiceProvider)),
    );

final activeRecipesProvider = Provider<List<Recipe>>((ref) {
  final allRecipes = ref.watch(recipeProvider).values;
  return allRecipes.where((recipe) => recipe.deletedAt == null).toList();
});

final trashedRecipesProvider = Provider<List<Recipe>>((ref) {
  final allRecipes = ref.watch(recipeProvider).values;
  return allRecipes.where((recipe) => recipe.deletedAt != null).toList();
});

// ======================================================================

/// Der Provider für den MacroService, der die Makronährstoff-Logik kapselt.
/// Er erhält die FoodDataMap als Abhängigkeit injiziert.
final macroServiceProvider = Provider<MacroService>((ref) {
  final foodDataMap = ref.watch(foodDataMapProvider);
  return MacroService(foodDataMap: foodDataMap);
});

// ======================================================================

final storageServiceProvider = Provider<IStorageService>((ref) {
  return LocalStorageService();
});
