// lib/logic/models/recipe.dart

import 'package:eat_beat_repeat/logic/interfaces/i_soft_deletable.dart';
import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:eat_beat_repeat/logic/models/meal_entry.dart';
import 'package:eat_beat_repeat/logic/models/recipe_ingredient.dart'; // NEU: Unsere Zutatendefinition
import 'package:eat_beat_repeat/logic/utils/wrapper.dart';
import 'package:uuid/uuid.dart';

class Recipe implements ISoftDeletable<Recipe> {
  @override
  final String id;
  final String name;
  final List<RecipeIngredient> ingredients;
  @override
  final DateTime? deletedAt;

  // Wir vereinfachen die Felder quantity/unit, da wir 1.0 Portion als Standard annehmen.
  // Diese Felder sind für die Instanziierung im DailyPlan nicht notwendig,
  // da RecipeEntry später die 'servings' (Portionen) definiert.
  final double baseQuantity; // Standard 1.0 (Portion)
  final String baseUnit; // Standard 'Portion'

  Recipe._({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.baseQuantity,
    required this.baseUnit,
    this.deletedAt,
  });

  factory Recipe({
    required String name,
    required List<RecipeIngredient> ingredients,
  }) {
    return Recipe._(
      id: const Uuid().v4(),
      name: name,
      ingredients: ingredients,
      baseQuantity: 1.0,
      baseUnit: 'Portion',
      deletedAt: null,
    );
  }

  // copyWith method (ID-sicher)
  @override
  Recipe copyWith({
    String? name,
    List<RecipeIngredient>? ingredients,
    Wrapper<DateTime?>? deletedAt,
  }) {
    return Recipe._(
      id: id,
      name: name ?? this.name,
      ingredients: ingredients ?? this.ingredients,
      baseQuantity: baseQuantity,
      baseUnit: baseUnit,
      deletedAt: deletedAt != null ? deletedAt.value : this.deletedAt,
    );
  }

  // --- NÄHRWERT-BERECHNUNG ---

  // 1. Berechnet Makros für EINE BASIS-PORTION (baseQuantity)
  // WICHTIG: Der Getter muss die statischen Daten aus der Applikationsebene (Service) erhalten.
  // Da dies ein Model ist, muss der Zugriff extern erfolgen (z.B. über eine Provider-Methode).
  // Wir belassen den UnimplementedError, um die Trennung zu erzwingen, da Getter keine Argumente haben dürfen.
  // Wir verwenden stattdessen die Hilfsmethode direkt im Service.
  MacroNutrients get totalMacrosForBasePortion {
    throw UnimplementedError(
      'Die Makro-Berechnung eines Recipes muss über den RecipeMacroService erfolgen, da FoodData-Karten benötigt werden.',
    );
  }

  // Die übergebenen Methoden zur Berechnung sind korrekt, ABER die
  // Implementierung muss in einem Service/Helper erfolgen,
  // da ein Model nicht direkt auf den Provider zugreifen sollte.

  // Hilfsmethode, um die Makros für die Basisportion zu summieren
  // static MacroNutrients calculateBaseMacros(
  //   List<RecipeIngredient> ingredients,
  //   Map<String, FoodData> foodDataMap,
  // ) {
  //   return ingredients.fold(
  //     MacroNutrients.zero(),
  //     (sum, ingredient) {
  //       // Findet die Basis-FoodData
  //       final data = foodDataMap[ingredient.foodDataId];
  //       if (data == null) {
  //         // Vorsichtiger Umgang mit fehlender FoodData (z.B. gelöscht)
  //         return sum;
  //       }

  //       // Berechnet die Makros für die tatsächliche Menge des Ingredients
  //       final scaleFactor = ingredient.quantity / 100.0;
  //       final ingredientMacros = data.macrosPer100unit.scale(scaleFactor);

  //       return sum + ingredientMacros;
  //     },
  //   );
  // }

  // getMacros
  // using ingredient.getMacros(foodDataMap)
  MacroNutrients getMacros(
    Map<String, FoodData> foodDataMap,
  ) {
    return ingredients.fold(
      MacroNutrients.zero(),
      (sum, ingredient) {
        return sum + ingredient.getMacros(foodDataMap);
      },
    );
  }

  // Recipe to RecipeEntry Konvertierung
  RecipeEntry toRecipeEntry({
    required String entryName,
    required double servings,
  }) {
    return RecipeEntry(
      name: entryName,
      recipeId: id,
      servings: servings,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      // Anpassung: serialisiert RecipeIngredient
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'baseQuantity': baseQuantity,
      'baseUnit': baseUnit,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  // JSON deserialization
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe._(
      id: json['id'] as String,
      name: json['name'] as String,
      // Anpassung: deserialisiert RecipeIngredient
      ingredients: (json['ingredients'] as List? ?? [])
          .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      baseQuantity: (json['baseQuantity'] as num?)?.toDouble() ?? 1.0,
      baseUnit: json['baseUnit'] as String? ?? 'Portion',
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'])
          : null,
    );
  }

  // toString override für Debugging
  @override
  String toString() {
    return 'Recipe(id: $id, name: $name, ingredients: $ingredients, baseQuantity: $baseQuantity, baseUnit: $baseUnit, deletedAt: $deletedAt)';
  }
}
