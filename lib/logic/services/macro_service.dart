import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:eat_beat_repeat/logic/models/predefined_food.dart';
import 'package:eat_beat_repeat/logic/models/recipe_ingredient.dart';
import 'package:eat_beat_repeat/logic/models/recipe.dart';
import 'package:eat_beat_repeat/logic/models/food_entry.dart';
import 'package:eat_beat_repeat/logic/models/recipe_entry.dart';
import 'package:eat_beat_repeat/logic/models/meal_plan.dart';

// ======================================================================
// MACRO SERVICE CLASS
// ======================================================================

/// Ein Service, der alle Makronährstoff-Berechnungen kapselt.
class MacroService {
  // Die Map der FoodData ist die Single Source of Truth für alle Berechnungen.
  final Map<String, FoodData> foodDataMap;

  MacroService({required this.foodDataMap});

  // ----------------------------------------------------------------------
  // A. KERN-LOGIK: ELEMENTARE BERECHNUNGEN & DATEN-AUFLÖSUNG
  // ----------------------------------------------------------------------

  /// Liefert das FoodData-Objekt basierend auf der ID.
  FoodData? getFoodData(String foodDataId) {
    return foodDataMap[foodDataId];
  }

  /// Liefert den Namen der FoodData oder einen Fallback-String.
  String getFoodDataName(String foodDataId) {
    return getFoodData(foodDataId)?.name ?? 'Unbekannte FoodData ($foodDataId)';
  }

  /// Berechnet die Makros für eine Menge einer FoodData.
  MacroNutrients _calculateBaseMacros(String foodDataId, double quantity) {
    final foodData = getFoodData(foodDataId);
    if (foodData == null) {
      return MacroNutrients.zero();
    }

    // Annahme: Makros sind pro 100 Einheiten (g/ml) gespeichert.
    final factor = quantity / 100.0;

    return foodData.macrosPer100unit.scale(factor);
  }

  // ----------------------------------------------------------------------
  // B. BERECHNUNG FÜR DOMAIN-MODELLE
  // ----------------------------------------------------------------------

  /// 1. Berechnet die Makros für eine einzelne RecipeIngredient.
  MacroNutrients calculateMacrosForRecipeIngredient(
    RecipeIngredient ingredient,
  ) {
    return _calculateBaseMacros(
      ingredient.foodDataId,
      ingredient.quantity,
    );
  }

  /// 2. Berechnet die Makros für ein PredefinedFood oder FoodEntry.
  MacroNutrients calculateMacrosForFoodEntry(FoodEntry entry) {
    // Annahme: FoodEntry enthält foodDataId und Quantity
    return _calculateBaseMacros(
      entry.foodDataId,
      entry.quantity,
    );
  }

  /// 3. Berechnet die Makros für ein gesamtes Recipe.
  MacroNutrients calculateMacrosForRecipe(Recipe recipe) {
    return recipe.ingredients.fold(
      MacroNutrients.zero(),
      (sum, ingredient) {
        // Nutzt die Ingredient-Berechnung des Service
        return sum + calculateMacrosForRecipeIngredient(ingredient);
      },
    );
  }

  /// 4. Berechnet die Makros für ein RecipeEntry.
  /// (Skaliert die Gesamt-Makros des Rezepts auf die gegessene Menge).
  MacroNutrients calculateMacrosForRecipeEntry(RecipeEntry entry) {
    // Hier bräuchten wir idealerweise das Recipe-Objekt selbst.
    // Falls Recipes in einem anderen Provider gespeichert sind, muss dieser
    // Service auf diesen Provider zugreifen oder das Recipe-Objekt übergeben bekommen.

    // ANNAHME: Wir haben ein separates RecipeMapProvider, das Recipe-Objekte bereitstellt.
    // Wenn Sie diesen Service **noch reiner** halten wollen, müssten Sie
    // das Recipe-Objekt selbst als Argument übergeben.

    // Beispiel, wenn das Recipe-Objekt bereits im RecipeEntry gespeichert ist (nicht ideal)
    // oder von einem anderen Service/Provider übergeben wird.

    // Da Sie nur FoodData übergeben wollen, nehmen wir an, dass das Recipe-Objekt
    // aus einem separaten Provider im UI-Layer kommt und hier übergeben wird.

    // **Sauberer Aufruf (im UI-Layer):**
    // final recipe = ref.read(recipeProvider.select((map) => map[entry.recipeId]));
    // final macros = macroService.calculateRecipeEntryMacros(entry, recipe);

    // Wenn das Recipe-Objekt im Argument mitkommt (bevorzugt)
    throw UnimplementedError(
      'calculateRecipeEntryMacros benötigt das vollständige Recipe-Objekt.',
    );
  }

  /// 5. Berechnet die Makros für einen gesamten MealPlan.
  MacroNutrients calculateMacrosForMealPlan(
    MealPlan plan,
    Map<String, Recipe> recipeMap,
  ) {
    return plan.entries.fold(
      MacroNutrients.zero(),
      (sum, entry) {
        if (entry is FoodEntry) {
          return sum + calculateMacrosForFoodEntry(entry);
        } else if (entry is RecipeEntry) {
          final recipe = recipeMap[entry.recipeId];
          if (recipe != null) {
            final baseMacros = calculateMacrosForRecipe(recipe);
            return sum + baseMacros.scale(entry.servings);
          }
        }
        return sum;
      },
    );
  }

  // Berechnet die Makros für ein PredefinedFood
  MacroNutrients calculateMacrosForPredefinedFood(PredefinedFood predefined) {
    return _calculateBaseMacros(
      predefined.foodDataId,
      predefined.quantity,
    );
  }
}
