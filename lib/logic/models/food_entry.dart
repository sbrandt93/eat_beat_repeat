// lib/logic/models/food_entry.dart

import 'package:eat_beat_repeat/logic/models/abstract_meal_entry.dart';
import 'package:eat_beat_repeat/logic/models/predefined_food.dart';
import 'package:uuid/uuid.dart';

class FoodEntry implements AbstractMealEntry {
  @override
  final String id;
  // Der Name wird von der Applikationslogik gesetzt (Custom oder FoodData Name)
  @override
  final String name;
  final String foodDataId;
  final double quantity;

  FoodEntry._({
    required this.id,
    required this.name,
    required this.foodDataId,
    required this.quantity,
  });

  factory FoodEntry({
    required String name,
    required String foodDataId,
    required double quantity,
  }) {
    return FoodEntry._(
      id: Uuid().v4(),
      name: name,
      foodDataId: foodDataId,
      quantity: quantity,
    );
  }

  static FoodEntry fromPredefinedFood({
    required String name,
    required PredefinedFood predefinedFood,
  }) {
    return FoodEntry._(
      id: Uuid().v4(),
      name: name,
      foodDataId: predefinedFood.foodDataId,
      quantity: predefinedFood.quantity,
    );
  }

  FoodEntry copyWith({
    String? name,
    String? foodDataId,
    double? quantity,
  }) {
    return FoodEntry._(
      id: id,
      name: name ?? this.name,
      foodDataId: foodDataId ?? this.foodDataId,
      quantity: quantity ?? this.quantity,
    );
  }

  // --- ABSTRACTMEALENTRY IMPLEMENTIERUNG ---

  // @override
  // MacroNutrients totalMacros(
  //   Map<String, FoodData> foodDataMap,
  //   Map<String, Recipe> recipeMap,
  // ) {
  //   final foodData = foodDataMap[foodDataId];
  //   if (foodData == null) {
  //     return MacroNutrients.zero();
  //   }

  //   // Berechnung: (Menge / 100) * Makros pro 100g/ml
  //   final factor = quantity / 100;
  //   return foodData.macrosPer100unit.scale(factor);
  // }

  @override
  double get totalQuantity => quantity;

  // --- JSON SERIALIZATION ---

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'Food',
      'id': id,
      'name': name,
      'foodDataId': foodDataId,
      'quantity': quantity,
    };
  }

  factory FoodEntry.fromJson(Map<String, dynamic> json) {
    return FoodEntry._(
      id: json['id'] as String,
      name: json['name'] as String,
      foodDataId: json['foodDataId'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // toString override für Debugging
  @override
  String toString() {
    return 'FoodEntry(id: $id, name: $name, foodDataId: $foodDataId, quantity: $quantity)';
  }
}
