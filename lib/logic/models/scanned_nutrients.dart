/// Holds nutrient values extracted from an OCR scan of a nutrition label.
/// All fields are nullable — OCR may only recognise some values.
class ScannedNutrients {
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;

  const ScannedNutrients({
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
  });

  /// True when no field was recognised at all.
  bool get isEmpty =>
      calories == null && protein == null && carbs == null && fat == null;

  /// True when every field was recognised.
  bool get isComplete =>
      calories != null && protein != null && carbs != null && fat != null;

  @override
  String toString() =>
      'ScannedNutrients(kcal=$calories, P=$protein, K=$carbs, F=$fat)';
}
