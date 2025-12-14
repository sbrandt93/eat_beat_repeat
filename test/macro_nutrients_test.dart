import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Constructor Test', () {
    test('MacroNutrients constructor assigns values correctly', () {
      //? Arrange
      final calories = 250.0;
      final protein = 10.0;
      final carbs = 30.0;
      final fat = 5.0;
      final sugar = 15.0;

      //& Act
      final macros = MacroNutrients(
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        sugar: sugar,
      );

      //^ Assert
      expect(macros.calories, equals(calories));
      expect(macros.protein, equals(protein));
      expect(macros.carbs, equals(carbs));
      expect(macros.fat, equals(fat));
      expect(macros.sugar, equals(sugar));
    });
  });
  group('CopyWith Method Test', () {
    test('MacroNutrients copyWith creates a modified copy', () {
      //? Arrange
      final original = MacroNutrients(
        calories: 200.0,
        protein: 8.0,
        carbs: 25.0,
        fat: 4.0,
        sugar: 10.0,
      );

      //& Act
      final modified = original.copyWith(
        protein: 12.0,
        fat: 6.0,
      );

      //^ Assert
      expect(modified.calories, equals(200.0));
      expect(modified.protein, equals(12.0));
      expect(modified.carbs, equals(25.0));
      expect(modified.fat, equals(6.0));
      expect(modified.sugar, equals(10.0));
    });
  });

  group('Scale Method Test', () {
    test('MacroNutrients scale scales all values correctly', () {
      //? Arrange
      final original = MacroNutrients(
        calories: 150.0,
        protein: 6.0,
        carbs: 20.0,
        fat: 3.0,
        sugar: 8.0,
      );
      final factor = 2.0;

      //& Act
      final scaled = original.scale(factor);

      //^ Assert
      expect(scaled.calories, equals(300.0));
      expect(scaled.protein, equals(12.0));
      expect(scaled.carbs, equals(40.0));
      expect(scaled.fat, equals(6.0));
      expect(scaled.sugar, equals(16.0));
    });
  });

  group('Addition Operator Test', () {
    test('MacroNutrients addition adds all values correctly', () {
      //? Arrange
      final first = MacroNutrients(
        calories: 100.0,
        protein: 4.0,
        carbs: 15.0,
        fat: 2.0,
        sugar: 5.0,
      );
      final second = MacroNutrients(
        calories: 200.0,
        protein: 8.0,
        carbs: 25.0,
        fat: 4.0,
        sugar: 10.0,
      );

      //& Act
      final total = first + second;

      //^ Assert
      expect(total.calories, equals(300.0));
      expect(total.protein, equals(12.0));
      expect(total.carbs, equals(40.0));
      expect(total.fat, equals(6.0));
      expect(total.sugar, equals(15.0));
    });
  });

  group('Zero Factory Test', () {
    test('MacroNutrients.zero creates an instance with all values zero', () {
      //& Act
      final zeroMacros = MacroNutrients.zero();

      //^ Assert
      expect(zeroMacros.calories, equals(0.0));
      expect(zeroMacros.protein, equals(0.0));
      expect(zeroMacros.carbs, equals(0.0));
      expect(zeroMacros.fat, equals(0.0));
      expect(zeroMacros.sugar, equals(0.0));
    });
  });

  group('JSON Serialization Test', () {
    test('MacroNutrients toJson and fromJson work correctly', () {
      //? Arrange
      final original = MacroNutrients(
        calories: 180.0,
        protein: 7.0,
        carbs: 22.0,
        fat: 3.5,
        sugar: 9.0,
      );

      //& Act
      final json = original.toJson();
      final fromJson = MacroNutrients.fromJson(json);

      //^ Assert
      expect(fromJson.calories, equals(original.calories));
      expect(fromJson.protein, equals(original.protein));
      expect(fromJson.carbs, equals(original.carbs));
      expect(fromJson.fat, equals(original.fat));
      expect(fromJson.sugar, equals(original.sugar));
    });
  });

  group('toString Method Test', () {
    test('MacroNutrients toString returns correct string representation', () {
      //? Arrange
      final macros = MacroNutrients(
        calories: 220.0,
        protein: 9.0,
        carbs: 28.0,
        fat: 4.0,
        sugar: 11.0,
      );

      //& Act
      final str = macros.toString();

      //^ Assert
      expect(
        str,
        equals(
          'MacroNutrients(calories: 220.0, protein: 9.0, carbs: 28.0, fat: 4.0, sugar: 11.0)',
        ),
      );
    });
  });
}
