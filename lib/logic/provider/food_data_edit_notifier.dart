// import 'package:eat_beat_repeat/logic/models/food_data.dart';
// import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
// import 'package:flutter_riverpod/legacy.dart';

// // Dieser Notifier verwaltet NUR den Bearbeitungsstatus eines einzelnen FoodData-Objekts.
// class FoodDataEditNotifier extends StateNotifier<FoodData> {
//   // Der Zustand ist das FoodData-Objekt, das wir klonen/bearbeiten
//   FoodDataEditNotifier(super.initialData);

//   // --- Methoden zur direkten Änderung der Felder ---

//   void setName(String name) {
//     state = state.copyWith(name: name);
//   }

//   void setBrandName(String brandName) {
//     state = state.copyWith(brandName: brandName);
//   }

//   void setDefaultUnit(String unit) {
//     state = state.copyWith(defaultUnit: unit);
//   }

//   // Für die Makros benötigen wir die vollständige Makro-Einheit,
//   // oder wir implementieren Methoden, die einzelne Makro-Felder ändern.

//   // Beispiel: Nur Kalorien ändern
//   void setCalories(double calories) {
//     final currentMacros = state.macrosPer100unit;

//     // Kopiert die Makros und ändert nur die Kalorien
//     final newMacros = currentMacros.copyWith(calories: calories);

//     // Kopiert FoodData und weist die neuen Makros zu
//     state = state.copyWith(macrosPer100unit: newMacros);
//   }

//   // Beispiel: Alle Makros auf einmal setzen
//   void setAllMacros(MacroNutrients macros) {
//     state = state.copyWith(macrosPer100unit: macros);
//   }
// }
