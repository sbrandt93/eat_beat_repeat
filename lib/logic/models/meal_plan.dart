// lib/logic/models/meal_plan.dart

import 'package:eat_beat_repeat/logic/models/abstract_meal_entry.dart';
import 'package:eat_beat_repeat/logic/models/food_entry.dart'; // NEU: Import der konkreten Entry-Typen
import 'package:eat_beat_repeat/logic/models/recipe_entry.dart'; // NEU
import 'package:uuid/uuid.dart';

class MealPlan {
  final String id;
  final String name;
  // Muss das Interface AbstractMealEntry verwenden
  final List<AbstractMealEntry> entries;
  final DateTime date;

  MealPlan._({
    required this.id,
    required this.name,
    required this.entries,
    required this.date,
  });

  factory MealPlan({
    required String name,
    DateTime? date,
    // Optional: Um Pläne mit bereits vorhandenen Einträgen zu erstellen
    List<AbstractMealEntry>? entries,
  }) {
    // Verwendung des privaten Konstruktors
    return MealPlan._(
      id: const Uuid().v4(), // ID wird bei Erstellung gesetzt
      name: name,
      entries: entries ?? [],
      date: date ?? DateTime.now(),
    );
  }

  // copyWith method (ID-sicher)
  MealPlan copyWith({
    String? name,
    List<AbstractMealEntry>? entries, // Anpassung auf Interface
    DateTime? date,
  }) {
    return MealPlan._(
      id: id, // ID bleibt unverändert
      name: name ?? this.name,
      entries: entries ?? this.entries,
      date: date ?? this.date,
    );
  }

  // Macro nutrients calculation (Gateway zur Berechnung)
  // Diese Methode muss die statischen Maps von den Providern erhalten!
  // MacroNutrients totalMacros(
  //   Map<String, FoodData> foodDataMap,
  //   Map<String, Recipe> recipeMap,
  // ) {
  //   return entries.fold(
  //     MacroNutrients.zero(),
  //     // Delegiert die Makro-Berechnung an jeden Eintrag
  //     (sum, entry) => sum + entry.totalMacros(foodDataMap, recipeMap),
  //   );
  // }

  // JSON serialization (Delegiert die Serialisierung an die Entries)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      // Jeder Entry kennt seinen Typ und wird korrekt serialisiert
      'entries': entries.map((e) => e.toJson()).toList(),
      'date': date.toIso8601String(),
    };
  }

  // JSON deserialization (Muss den Typ des Eintrags bestimmen)
  factory MealPlan.fromJson(Map<String, dynamic> json) {
    final List<AbstractMealEntry> loadedEntries = [];

    // Iteriert über die Liste der Einträge
    for (final entryJson in (json['entries'] as List? ?? [])) {
      final entryMap = entryJson as Map<String, dynamic>;
      final type = entryMap['type'] as String?; // Liest den gespeicherten Typ

      if (type == 'Food') {
        loadedEntries.add(FoodEntry.fromJson(entryMap));
      } else if (type == 'Recipe') {
        loadedEntries.add(RecipeEntry.fromJson(entryMap));
      } else {
        // Protokollierung oder Behandlung unbekannter Typen
      }
    }

    return MealPlan._(
      id: json['id'] as String,
      name: json['name'] as String,
      entries: loadedEntries,
      date: DateTime.parse(json['date'] as String),
    );
  }

  // toString override für Debugging
  @override
  String toString() {
    return 'MealPlan(id: $id, name: $name, entries: $entries, date: $date)';
  }
}
