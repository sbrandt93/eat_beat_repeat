abstract class AbstractMealEntry {
  // Muss im konkreten Child implementiert werden (final String id;)
  String get id;

  // Name (z.B. "Banane", "Protein-Shake")
  String get name;

  // Dynamische Berechnung der Makros. Muss die statischen Daten erhalten.
  // MacroNutrients totalMacros();

  // Gesamtmenge in g/ml (dynamisch)
  double get totalQuantity;

  // Muss den Typ (Food/Recipe) für die Deserialisierung beinhalten
  Map<String, dynamic> toJson();
}
