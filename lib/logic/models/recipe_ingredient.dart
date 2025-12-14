// lib/logic/models/recipe_ingredient.dart

import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:uuid/uuid.dart';

class RecipeIngredient {
  final String id;
  final String foodDataId;
  final double quantity;

  // 3. (Optional) Einheit, falls nicht g/ml verwendet werden (z.B. "Stück")
  // Da die FoodData bereits die Standard-Einheit definiert, nutzen wir quantity als Wert in dieser Einheit.

  const RecipeIngredient._({
    required this.id,
    required this.foodDataId,
    required this.quantity,
  });

  factory RecipeIngredient({
    required String foodDataId,
    required double quantity,
  }) {
    return RecipeIngredient._(
      id: const Uuid().v4(),
      foodDataId: foodDataId,
      quantity: quantity,
    );
  }

  // copyWith method
  RecipeIngredient copyWith({
    String? foodDataId,
    double? quantity,
  }) {
    return RecipeIngredient._(
      id: id,
      foodDataId: foodDataId ?? this.foodDataId,
      quantity: quantity ?? this.quantity,
    );
  }

  // getFoodData
  FoodData? getFoodData(Map<String, FoodData> foodDataMap) {
    return foodDataMap[foodDataId];
  }

  // getMacros
  MacroNutrients getMacros(Map<String, FoodData> foodDataMap) {
    final foodData = foodDataMap[foodDataId];
    if (foodData == null) {
      return MacroNutrients.zero();
    }

    final factor = quantity / 100.0;

    return foodData.macrosPer100unit.scale(factor);
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foodDataId': foodDataId,
      'quantity': quantity,
    };
  }

  // JSON deserialization
  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient._(
      id: json['id'] as String,
      foodDataId: json['foodDataId'],
      quantity: (json['quantity'] as num).toDouble(),
    );
  }

  // toString override für Debugging
  @override
  String toString() {
    return 'RecipeIngredient(id: $id, foodDataId: $foodDataId, quantity: $quantity)';
  }
}
