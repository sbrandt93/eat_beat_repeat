import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:eat_beat_repeat/logic/models/predefined_food.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Test Data Setup
  MacroNutrients getTestMacros() => MacroNutrients(
    calories: 100.0,
    protein: 5.0,
    carbs: 20.0,
    fat: 2.0,
    sugar: 10.0,
  );

  FoodData getTestFoodData() => FoodData(
    name: 'Test Food',
    brandName: 'Test Brand',
    macrosPer100unit: getTestMacros(),
    defaultUnit: 'grams',
  );
  group('Constructor Test', () {
    test('PredefinedFood constructor assigns values correctly', () {
      //? Arrange
      final foodData = getTestFoodData();
      final quantity = 150.0;

      //& Act
      final predefinedFood = PredefinedFood(
        foodDataId: foodData.id,
        quantity: quantity,
      );

      //^ Assert
      expect(predefinedFood.foodDataId, equals(foodData.id));
      expect(predefinedFood.quantity, equals(quantity));
      expect(predefinedFood.id, isNotNull);
    });
  });

  group('CopyWith Method Test', () {
    test('PredefinedFood copyWith creates a modified copy', () {
      //? Arrange
      final foodData = getTestFoodData();
      final original = PredefinedFood(
        foodDataId: foodData.id,
        quantity: 200.0,
      );

      //& Act
      final modified = original.copyWith(
        quantity: 250.0,
      );

      //^ Assert
      expect(modified.id, equals(original.id)); // ID should remain the same
      expect(modified.foodDataId, equals(original.foodDataId)); // Unchanged
      expect(modified.quantity, equals(250.0)); // Modified
    });
  });

  group('JSON Serialization Test', () {
    test('PredefinedFood toJson and fromJson work correctly', () {
      //? Arrange
      final foodData = getTestFoodData();
      final predefinedFood = PredefinedFood(
        foodDataId: foodData.id,
        quantity: 300.0,
      );

      //& Act
      final json = predefinedFood.toJson();
      final deserialized = PredefinedFood.fromJson(json);

      //^ Assert
      expect(deserialized.id, equals(predefinedFood.id));
      expect(deserialized.foodDataId, equals(predefinedFood.foodDataId));
      expect(deserialized.quantity, equals(predefinedFood.quantity));
    });
  });

  group('ToString Method Test', () {
    test('PredefinedFood toString returns correct format', () {
      //? Arrange
      final foodData = getTestFoodData();
      final predefinedFood = PredefinedFood(
        foodDataId: foodData.id,
        quantity: 400.0,
      );

      //& Act
      final str = predefinedFood.toString();

      //^ Assert
      expect(
        str,
        contains(
          'PredefinedFood(id: ${predefinedFood.id}, foodDataId: ${predefinedFood.foodDataId}, quantity: ${predefinedFood.quantity})',
        ),
      );
    });
  });
}
