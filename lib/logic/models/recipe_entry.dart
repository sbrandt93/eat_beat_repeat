// lib/logic/models/recipe_entry.dart

import 'package:eat_beat_repeat/logic/models/abstract_meal_entry.dart';
import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:eat_beat_repeat/logic/models/recipe.dart';
import 'package:uuid/uuid.dart';

class RecipeEntry implements AbstractMealEntry {
  // FINAL Attribute: Implementieren die Getter des Interfaces und sind unveränderlich.
  @override
  final String id;
  @override
  final String name;
  final String recipeId; // Referenziert das statische Recipe-Objekt
  final double servings; // Die verwendete Portionenzahl

  // Privater Konstruktor: Für Deserialisierung und copyWith
  RecipeEntry._({
    required this.id,
    required this.name,
    required this.recipeId,
    required this.servings,
  });

  // Factory-Konstruktor: Für die Erstellung neuer Einträge
  factory RecipeEntry({
    required String name,
    required String recipeId,
    required double servings,
  }) {
    // Ruft den privaten Konstruktor mit einer neu generierten, unveränderlichen ID auf
    return RecipeEntry._(
      id: Uuid().v4(),
      name: name,
      recipeId: recipeId,
      servings: servings,
    );
  }

  // copyWith method: ID wird beibehalten
  RecipeEntry copyWith({
    String? name,
    String? recipeId,
    double? servings,
  }) {
    return RecipeEntry._(
      id: id,
      name: name ?? this.name,
      recipeId: recipeId ?? this.recipeId,
      servings: servings ?? this.servings,
    );
  }

  // --- ABSTRACTMEALENTRY IMPLEMENTIERUNG ---

  @override
  double get totalQuantity {
    // PLATZHALTER: Um das Gesamtgewicht zu berechnen, müsste hier ebenfalls
    // das Recipe-Objekt abgerufen und die Mengen der Zutaten summiert und skaliert werden.
    return 0.0;
  }

  // getMacros
  // using recipe.getMacros(foodDataMap) and scaling by servings
  MacroNutrients getMacros(
    Map<String, FoodData> foodDataMap,
    Map<String, Recipe> recipeMap,
  ) {
    final recipe = recipeMap[recipeId];
    if (recipe == null) {
      return MacroNutrients.zero();
    }
    final baseMacros = recipe.getMacros(foodDataMap);
    return baseMacros.scale(servings);
  }

  // --- JSON SERIALIZATION ---
  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'Recipe', // Wichtig für die Deserialisierung im MealPlan
      'id': id,
      'name': name,
      'recipeId': recipeId,
      'servings': servings,
    };
  }

  // JSON deserialization
  factory RecipeEntry.fromJson(Map<String, dynamic> json) {
    return RecipeEntry._(
      id: json['id'] as String,
      name: json['name'] as String,
      recipeId: json['recipeId'] as String,
      servings: (json['servings'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // toString override für Debugging
  @override
  String toString() {
    return 'RecipeEntry(id: $id, name: $name, recipeId: $recipeId, servings: $servings)';
  }
}
