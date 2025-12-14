import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Test Data Setup
  getTestMacros() => MacroNutrients(
    calories: 100.0,
    protein: 5.0,
    carbs: 20.0,
    fat: 2.0,
  );

  group('Constructor Test', () {
    test('FoodData constructor assigns values correctly', () {
      //? Arrange
      final name = 'Apple';
      final brandName = 'Fresh Farms';
      final macros = getTestMacros();
      final defaultUnit = 'grams';

      //& Act
      final foodData = FoodData(
        name: name,
        brandName: brandName,
        macrosPer100unit: macros,
        defaultUnit: defaultUnit,
      );

      //^ Assert
      expect(foodData.name, equals(name));
      expect(foodData.brandName, equals(brandName));
      expect(foodData.macrosPer100unit, equals(macros));
      expect(foodData.defaultUnit, equals(defaultUnit));
      expect(foodData.id, isNotNull);
    });
  });
  group('CopyWith Method Test', () {
    test('FoodData copyWith creates a modified copy', () {
      //? Arrange
      final testMacros = getTestMacros();
      final original = FoodData(
        name: 'Banana',
        brandName: 'Tropical Fruits',
        macrosPer100unit: testMacros,
        defaultUnit: 'grams',
      );

      //& Act
      final modified = original.copyWith(
        name: 'Ripe Banana',
        macrosPer100unit: MacroNutrients(
          calories: 95.0,
          protein: 1.2,
          carbs: 25.0,
          fat: 0.4,
        ),
      );

      //^ Assert
      expect(modified.name, equals('Ripe Banana'));
      expect(modified.brandName, equals(original.brandName));
      expect(modified.macrosPer100unit.calories, equals(95.0));
      expect(modified.macrosPer100unit.protein, equals(1.2));
      expect(modified.macrosPer100unit.carbs, equals(25.0));
      expect(modified.macrosPer100unit.fat, equals(0.4));
      expect(modified.defaultUnit, equals(original.defaultUnit));
      expect(modified.id, equals(original.id));
    });
  });
  group('JSON Serialization Test', () {
    test('FoodData toJson and fromJson work correctly', () {
      //? Arrange
      final testMacros = getTestMacros();
      final original = FoodData(
        name: 'Orange',
        brandName: 'Citrus World',
        macrosPer100unit: testMacros,
        defaultUnit: 'grams',
      );

      //& Act
      final json = original.toJson();
      final deserialized = FoodData.fromJson(json);

      //^ Assert
      expect(deserialized.id, equals(original.id));
      expect(deserialized.name, equals(original.name));
      expect(deserialized.brandName, equals(original.brandName));
      expect(
        deserialized.macrosPer100unit.calories,
        equals(original.macrosPer100unit.calories),
      );
      expect(
        deserialized.macrosPer100unit.protein,
        equals(original.macrosPer100unit.protein),
      );
      expect(
        deserialized.macrosPer100unit.carbs,
        equals(original.macrosPer100unit.carbs),
      );
      expect(
        deserialized.macrosPer100unit.fat,
        equals(original.macrosPer100unit.fat),
      );
      expect(deserialized.defaultUnit, equals(original.defaultUnit));
    });
  });

  group('toString Method Test', () {
    test('FoodData toString returns correct string representation', () {
      //? Arrange
      final testMacros = getTestMacros();
      final foodData = FoodData(
        name: 'Grapes',
        brandName: 'Vineyard Select',
        macrosPer100unit: testMacros,
        defaultUnit: 'grams',
      );

      //& Act
      final str = foodData.toString();

      //^ Assert
      expect(str, contains('FoodData'));
      expect(str, contains('name: Grapes'));
      expect(str, contains('brandName: Vineyard Select'));
    });
  });
}
