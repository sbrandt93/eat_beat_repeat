import 'package:eat_beat_repeat/backend/local_storage_service.dart';
import 'package:eat_beat_repeat/logic/interfaces/i_storage_service.dart';
import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/models/meal_plan.dart';
import 'package:eat_beat_repeat/logic/models/predefined_food.dart';
import 'package:eat_beat_repeat/logic/models/recipe.dart';
import 'package:eat_beat_repeat/logic/provider/food_data_notifier.dart';
import 'package:eat_beat_repeat/logic/provider/meal_plan_notifier.dart';
import 'package:eat_beat_repeat/logic/provider/predefined_food_notifier.dart';
import 'package:eat_beat_repeat/logic/provider/recipe_notifier.dart';
import 'package:eat_beat_repeat/logic/services/macro_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ======================================================================
// RIVERPOD PROVIDER
// ======================================================================

/// Die zentrale Quelle für alle Lebensmitteldaten in der App.
/// Liefert ein **[Map<String, FoodData>]**, wobei der Schlüssel
/// die eindeutige Lebensmittel-ID ist.
final foodDataProvider =
    StateNotifierProvider<FoodDataNotifier, Map<String, FoodData>>(
      (ref) {
        final storageService = ref.watch(storageServiceProvider);
        return FoodDataNotifier(storageService);
      },
    );

// ======================================================================

/// Die zentrale Quelle für alle MealPlans in der App.
/// Liefert ein **[Map<String, MealPlan>]**, wobei der Schlüssel
/// die eindeutige MealPlan-ID ist.
final mealPlanProvider =
    StateNotifierProvider<MealPlanNotifier, Map<String, MealPlan>>(
      // Umbenannter Provider
      (ref) {
        final storageService = ref.watch(storageServiceProvider);
        return MealPlanNotifier(storageService);
      },
    );

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

// ======================================================================

/// Die zentrale Quelle für alle Rezepte in der App.
/// Liefert ein **[Map<String, Recipe>]**, wobei der Schlüssel
/// die eindeutige Recipe-ID ist.
final recipeProvider =
    StateNotifierProvider<RecipeNotifier, Map<String, Recipe>>(
      (ref) => RecipeNotifier(ref.watch(storageServiceProvider)),
    );

// ======================================================================

/// Der Provider für den MacroService, der die Makronährstoff-Logik kapselt.
/// Er erhält die FoodDataMap als Abhängigkeit injiziert.
final macroServiceProvider = Provider<MacroService>((ref) {
  final foodDataMap = ref.watch(foodDataProvider);
  return MacroService(foodDataMap: foodDataMap);
});

// ======================================================================

final storageServiceProvider = Provider<IStorageService>((ref) {
  return LocalStorageService();
});
