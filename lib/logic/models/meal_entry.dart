import 'package:eat_beat_repeat/logic/models/predefined_food.dart';
import 'package:uuid/uuid.dart';

sealed class MealEntry {
  const MealEntry();
  String get id;
  String get name;

  factory MealEntry.fromJson(Map<String, dynamic> json) =>
      switch (json['type']) {
        'Food' => FoodEntry.fromJson(json),
        'Recipe' => RecipeEntry.fromJson(json),
        _ => throw ArgumentError('Unknown type: ${json['type']}'),
      };

  Map<String, dynamic> toJson();
}

class FoodEntry extends MealEntry {
  @override
  final String id;
  @override
  final String name;
  final String foodDataId;
  final double quantity;

  // ... rest deiner bestehenden FoodEntry Logik
  FoodEntry._({
    required this.id,
    required this.name,
    required this.foodDataId,
    required this.quantity,
  }) : super();

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

  factory FoodEntry.fromPredefinedFood({
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
      id: Uuid().v4(),
      name: name ?? this.name,
      foodDataId: foodDataId ?? this.foodDataId,
      quantity: quantity ?? this.quantity,
    );
  }

  factory FoodEntry.fromJson(Map<String, dynamic> json) {
    return FoodEntry._(
      id: json['id'] as String,
      name: json['name'] as String,
      foodDataId: json['foodDataId'] as String,
      quantity: (json['quantity'] as num).toDouble(),
    );
  }

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

  @override
  String toString() {
    return 'FoodEntry(id: $id, name: $name, foodDataId: $foodDataId, quantity: $quantity)';
  }
}

class RecipeEntry extends MealEntry {
  @override
  final String id;
  @override
  final String name;
  final String recipeId;
  final double servings;

  // ... rest deiner bestehenden RecipeEntry Logik
  RecipeEntry._({
    required this.id,
    required this.name,
    required this.recipeId,
    required this.servings,
  }) : super();

  factory RecipeEntry({
    required String name,
    required String recipeId,
    required double servings,
  }) {
    return RecipeEntry._(
      id: Uuid().v4(),
      name: name,
      recipeId: recipeId,
      servings: servings,
    );
  }

  RecipeEntry copyWith({
    String? name,
    String? recipeId,
    double? servings,
  }) {
    return RecipeEntry._(
      id: Uuid().v4(),
      name: name ?? this.name,
      recipeId: recipeId ?? this.recipeId,
      servings: servings ?? this.servings,
    );
  }

  factory RecipeEntry.fromJson(Map<String, dynamic> json) {
    return RecipeEntry._(
      id: json['id'] as String,
      name: json['name'] as String,
      recipeId: json['recipeId'] as String,
      servings: (json['servings'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'Recipe',
      'id': id,
      'name': name,
      'recipeId': recipeId,
      'servings': servings,
    };
  }

  @override
  String toString() {
    return 'RecipeEntry(id: $id, name: $name, recipeId: $recipeId, servings: $servings)';
  }
}
