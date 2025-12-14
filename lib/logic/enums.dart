enum FoodUnit {
  gramm('g'),
  milliliter('ml')
  ;

  final String displayString;
  const FoodUnit(this.displayString);

  // Hilfsmethode, um alle Strings für ein Dropdown zu bekommen
  static List<String> get displayValues =>
      FoodUnit.values.map((unit) => unit.displayString).toList();
}
