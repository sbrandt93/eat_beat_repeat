/// Represents macronutrient information for food items per 100 units.
class MacroNutrients {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;

  MacroNutrients({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.sugar = 0,
  });

  static MacroNutrients zero() => MacroNutrients(
    calories: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
    sugar: 0,
  );

  // copyWith method
  MacroNutrients copyWith({
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? sugar,
  }) {
    return MacroNutrients(
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      sugar: sugar ?? this.sugar,
    );
  }

  // scale method
  MacroNutrients scale(double factor) {
    return MacroNutrients(
      calories: calories * factor,
      protein: protein * factor,
      carbs: carbs * factor,
      fat: fat * factor,
      sugar: sugar * factor,
    );
  }

  // add operator
  MacroNutrients operator +(MacroNutrients other) {
    return MacroNutrients(
      calories: calories + other.calories,
      protein: protein + other.protein,
      carbs: carbs + other.carbs,
      fat: fat + other.fat,
      sugar: sugar + other.sugar,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'sugar': sugar,
    };
  }

  // JSON deserialization
  factory MacroNutrients.fromJson(Map<String, dynamic> json) {
    return MacroNutrients(
      calories: json['calories'] ?? 0,
      protein: json['protein'] ?? 0,
      carbs: json['carbs'] ?? 0,
      fat: json['fat'] ?? 0,
      sugar: json['sugar'] ?? 0,
    );
  }

  // toString override for debugging
  @override
  String toString() {
    return 'MacroNutrients(calories: $calories, protein: $protein, carbs: $carbs, fat: $fat, sugar: $sugar)';
  }
}
