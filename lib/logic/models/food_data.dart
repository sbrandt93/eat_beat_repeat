import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:uuid/uuid.dart';

class FoodData {
  final String id;
  final String name;
  final String brandName;
  final MacroNutrients macrosPer100unit;
  final String defaultUnit;

  FoodData._({
    required this.id,
    required this.name,
    required this.brandName,
    required this.macrosPer100unit,
    required this.defaultUnit,
  });

  factory FoodData({
    required String name,
    required String brandName,
    required MacroNutrients macrosPer100unit,
    required String defaultUnit,
  }) {
    return FoodData._(
      id: Uuid().v4(),
      name: name,
      brandName: brandName,
      macrosPer100unit: macrosPer100unit,
      defaultUnit: defaultUnit,
    );
  }

  // copyWith method
  FoodData copyWith({
    String? name,
    String? brandName,
    MacroNutrients? macrosPer100unit,
    String? defaultUnit,
  }) {
    return FoodData._(
      id: id,
      name: name ?? this.name,
      brandName: brandName ?? this.brandName,
      macrosPer100unit: macrosPer100unit ?? this.macrosPer100unit,
      defaultUnit: defaultUnit ?? this.defaultUnit,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brandName': brandName,
      'macrosPer100unit': macrosPer100unit.toJson(),
      'defaultUnit': defaultUnit,
    };
  }

  // JSON deserialization
  factory FoodData.fromJson(Map<String, dynamic> json) {
    return FoodData._(
      id: json['id'],
      name: json['name'],
      brandName: json['brandName'],
      macrosPer100unit: MacroNutrients.fromJson(json['macrosPer100unit']),
      defaultUnit: json['defaultUnit'],
    );
  }

  // toString override for Debugging
  @override
  String toString() {
    return 'FoodData(id: $id, name: $name, brandName: $brandName, macrosPer100unit: $macrosPer100unit, defaultUnit: $defaultUnit)';
  }
}
