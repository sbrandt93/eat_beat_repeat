import 'package:eat_beat_repeat/logic/models/scanned_nutrients.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

/// Fetches nutrient data from the Open Food Facts database by barcode (EAN/UPC).
///
/// Usage:
/// ```dart
/// final result = await NutritionScanService().lookupBarcode('4000417025005');
/// ```
class NutritionScanService {
  static bool _configured = false;

  static void _configure() {
    if (_configured) return;
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'eat_beat_repeat',
    );
    _configured = true;
  }

  /// Looks up a product by [barcode] on Open Food Facts and returns the
  /// per-100 g macronutrients, or `null` if the product is not found / has
  /// no nutrient data.
  Future<ScannedNutrients?> lookupBarcode(String barcode) async {
    _configure();

    final configuration = ProductQueryConfiguration(
      barcode,
      version: ProductQueryVersion.v3,
      fields: [
        ProductField.NUTRIMENTS,
        ProductField.NAME,
        ProductField.BRANDS,
        ProductField.IMAGE_FRONT_URL,
      ],
      language: OpenFoodFactsLanguage.GERMAN,
    );

    final result = await OpenFoodAPIClient.getProductV3(configuration);

    if (result.status != ProductResultV3.statusSuccess) return null;

    final nutriments = result.product?.nutriments;
    if (nutriments == null) return null;

    return ScannedNutrients(
      calories: nutriments.getValue(
        Nutrient.energyKCal,
        PerSize.oneHundredGrams,
      ),
      protein: nutriments.getValue(Nutrient.proteins, PerSize.oneHundredGrams),
      carbs: nutriments.getValue(
        Nutrient.carbohydrates,
        PerSize.oneHundredGrams,
      ),
      fat: nutriments.getValue(Nutrient.fat, PerSize.oneHundredGrams),
      name: result.product?.productName,
      brand: result.product?.brands,
      imageUrl: result.product?.imageFrontUrl,
    );
  }
}
