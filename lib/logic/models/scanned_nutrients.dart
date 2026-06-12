/// Holds nutrient values extracted from a barcode scan.
/// All fields are nullable — a product may not have all data.
class ScannedNutrients {
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String? name;
  final String? brand;
  final String? imageUrl;

  const ScannedNutrients({
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.name,
    this.brand,
    this.imageUrl,
  });

  bool get isEmpty =>
      calories == null && protein == null && carbs == null && fat == null;

  bool get isComplete =>
      calories != null && protein != null && carbs != null && fat != null;

  @override
  String toString() =>
      'ScannedNutrients(kcal=$calories, P=$protein, K=$carbs, F=$fat, name=$name, brand=$brand)';
}
