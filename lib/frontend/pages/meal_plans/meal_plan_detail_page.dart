import 'package:eat_beat_repeat/logic/models/food_entry.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eat_beat_repeat/logic/helpers.dart'; // Für formatDateTime

// --- PLATZHALTER FUNKTIONEN FÜR DIE NAVIGATION (Muss von Ihnen verknüpft werden) ---
void _navigateToNewRecipePage(BuildContext context) {
  // TODO: Hier die Navigation zur Rezept-Erstellungsseite einfügen
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('PLATZHALTER: Navigiere zur Rezept-Erstellungsseite'),
    ),
  );
}

void _navigateToNewPredefinedFoodPage(BuildContext context) {
  // TODO: Hier die Navigation zur PredefinedFood-Erstellungsseite einfügen
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'PLATZHALTER: Navigiere zur Vordefinierte Portion-Erstellungsseite',
      ),
    ),
  );
}
// ----------------------------------------------------------------------------------

class MealPlanDetailPage extends ConsumerWidget {
  // static const routeName = '/mealPlanDetail';
  final String planId;

  const MealPlanDetailPage({required this.planId, super.key});

  // Funktion zum Anzeigen des Dialogs, wie vom Benutzer gewünscht
  void _showAddMealEntryDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Für mehr Platz
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          height:
              MediaQuery.of(context).size.height *
              0.75, // 75% der Bildschirmhöhe
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Neuen Eintrag hinzufügen',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const Divider(height: 20, thickness: 1),

              // 1. Wahl: Bestehendes Rezept hinzufügen
              _ChoiceButton(
                icon: Icons.local_dining,
                label: 'Wähle bestehendes Rezept',
                color: Colors.pink,
                onTap: () {
                  Navigator.of(context).pop(); // Schließe Haupt-Sheet
                  _showRecipeSelection(context, ref, planId);
                },
              ),
              const SizedBox(height: 10),

              // 2. Wahl: Bestehende Vordefinierte Portion hinzufügen
              _ChoiceButton(
                icon: Icons.inventory_2,
                label: 'Wähle vordefinierte Portion',
                color: Colors.teal,
                onTap: () {
                  Navigator.of(context).pop(); // Schließe Haupt-Sheet
                  _showPredefinedFoodSelection(context, ref, planId);
                },
              ),
              const SizedBox(height: 20),

              const Text(
                'Oder Neu erstellen und hinzufügen',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const Divider(height: 20, thickness: 1),

              // 3. Wahl: Neues Rezept anlegen (Navigation)
              _ChoiceButton(
                icon: Icons.restaurant_menu,
                label: 'Neues Rezept anlegen',
                color: Colors.pink.shade300,
                onTap: () {
                  Navigator.of(context).pop();
                  _navigateToNewRecipePage(context);
                },
              ),
              const SizedBox(height: 10),

              // 4. Wahl: Neue Vordefinierte Portion anlegen (Navigation)
              _ChoiceButton(
                icon: Icons.fastfood,
                label: 'Neue vordefinierte Portion anlegen',
                color: Colors.teal.shade300,
                onTap: () {
                  Navigator.of(context).pop();
                  _navigateToNewPredefinedFoodPage(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Hilfsfunktion zur Anzeige der Rezept-Auswahl
  void _showRecipeSelection(
    BuildContext context,
    WidgetRef ref,
    String planId,
  ) {
    final recipesMap = ref.read(recipeProvider);
    final recipes = recipesMap.values.toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rezept auswählen'),
          content: SizedBox(
            width: double.maxFinite,
            child: recipes.isEmpty
                ? const Text(
                    'Keine Rezepte vorhanden. Bitte erstelle ein neues.',
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return ListTile(
                        title: Text(recipe.name),
                        trailing: const Icon(
                          Icons.add_circle,
                          color: Colors.pink,
                        ),
                        onTap: () {
                          ref
                              .read(mealPlanProvider.notifier)
                              .addEntryToPlan(planId, recipe.toRecipeEntry());

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Rezept "${recipe.name}" zu Plan $planId hinzugefügt (PLATZHALTER).',
                              ),
                            ),
                          );
                          Navigator.of(
                            context,
                          ).pop(); // Schließe Auswahl-Dialog
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zurück'),
            ),
          ],
        );
      },
    );
  }

  // Hilfsfunktion zur Anzeige der PredefinedFood-Auswahl
  void _showPredefinedFoodSelection(
    BuildContext context,
    WidgetRef ref,
    String planId,
  ) {
    final predefinedFoodsMap = ref.read(predefinedFoodProvider);
    final predefinedFoods = predefinedFoodsMap.values.toList();
    // Hier müsste man eigentlich auch die FoodData auflösen, um mehr Infos zu zeigen.
    final foodDataMap = ref.read(foodDataProvider);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Vordefinierte Portion auswählen'),
          content: SizedBox(
            width: double.maxFinite,
            child: predefinedFoods.isEmpty
                ? const Text(
                    'Keine vordefinierten Portionen vorhanden. Bitte erstelle eine neue.',
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: predefinedFoods.length,
                    itemBuilder: (context, index) {
                      final portion = predefinedFoods[index];
                      final foodName =
                          foodDataMap[portion.foodDataId]?.name ?? 'Unbekannt';

                      return ListTile(
                        title: Text(foodName),
                        subtitle: Text('Basis: $foodName'),
                        trailing: const Icon(
                          Icons.add_circle,
                          color: Colors.teal,
                        ),
                        onTap: () {
                          print('PORTION: $portion');
                          // TODO: Hier Logik zum Hinzufügen des PredefinedFood-Eintrags zum Plan
                          ref
                              .read(mealPlanProvider.notifier)
                              .addEntryToPlan(
                                planId,
                                FoodEntry.fromPredefinedFood(
                                  name: foodName,
                                  predefinedFood: portion,
                                ),
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Portion "$foodName" zu Plan $planId hinzugefügt (PLATZHALTER).',
                              ),
                            ),
                          );
                          Navigator.of(
                            context,
                          ).pop(); // Schließe Auswahl-Dialog
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zurück'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Plan aus Riverpod abrufen
    // Da wir einen StateNotifierProvider mit Map verwenden, können wir direkt auf die Map zugreifen.
    final planMap = ref.watch(mealPlanProvider);
    final plan = planMap[planId];

    // // Da ich die tatsächlichen Food/Recipe-Daten nicht habe,
    // // verwende ich die Mocks, um die totalMacros-Funktion zu simulieren.
    // final foodDataMap = {for (var f in ref.read(mockFoodDataProvider)) f.id: f};
    // final recipeMap = {for (var r in ref.read(recipeProvider)) r.id: r};

    // Prüfung, falls Plan nicht gefunden wird (Sollte nur bei App-Fehlern passieren)
    if (plan == null) {
      return const Scaffold(
        appBar: null,
        body: Center(
          child: Text('Fehler: Ernährungsplan nicht gefunden.'),
        ),
      );
    }

    // 2. Den Notifier für Aktionen abrufen
    final notifier = ref.read(mealPlanProvider.notifier);

    // 1. Abhängigkeiten auflösen (DI-Container)
    final macroService = ref.watch(macroServiceProvider);
    // Annahme: recipeMapProvider liefert Map<String, Recipe>
    final recipeMap = ref.watch(recipeProvider);

    // final entry = plan.entries[0]; // Beispiel-Eintrag
    // print('Plan Entry: ${entry}');
    // MacroNutrients? macros;
    // String name;

    // if (entry is FoodEntry) {
    //   // Einfache Berechnung durch den Service
    //   macros = macroService.calculateFoodEntryMacros(entry);
    //   name = macroService.getFoodDataName(
    //     entry.foodDataId,
    //   ); // Auflösung des Namens
    // } else if (entry is RecipeEntry) {
    //   print('Recipe Entry found: ${entry.recipeId}');
    //   final recipe = recipeMap[entry.recipeId];
    //   if (recipe == null) {
    //     macros = MacroNutrients.zero();
    //     name = 'Unbekanntes Rezept';
    //   } else {
    //     // Komplexe Berechnung, die Recipe (vom zweiten Provider) und Entry kombiniert
    //     macros = macroService
    //         .calculateRecipeTotalMacros(recipe)
    //         .scale(entry.servings);
    //     name = recipe.name;
    //     print('Calculated macros for recipe: $macros');
    //   }
    // }

    final finalMacros = macroService.calculateMacrosForMealPlan(
      plan,
      recipeMap,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${plan.name} (${formatDateTime(plan.date)})',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        // Optional: Lösch-Button in der AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
            onPressed: () {
              // TODO: Implementierung Lösch-Logik
              notifier.remove(planId);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zusammenfassung (z.B. Makros)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Makro-Zusammenfassung:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('Makros: ${finalMacros.calories.toStringAsFixed(0)} kcal'),
              ],
            ),
          ),

          const Divider(),

          // Liste der Meal Entries
          Expanded(
            child: plan.entries.isEmpty
                ? const Center(
                    child: Text(
                      'Noch keine Einträge. Füge ein Food oder Rezept hinzu.',
                    ),
                  )
                : ListView.builder(
                    itemCount: plan.entries.length,
                    itemBuilder: (context, index) {
                      final entry = plan.entries[index];
                      return ListTile(
                        // Da entry AbstractMealEntry implementiert, hat es einen Namen
                        title: Text(
                          entry.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        // subtitle: Text(
                        //   'Makros: ${entry.totalMacros({}, {}).calories.toStringAsFixed(0)} kcal, Menge: ${entry.totalQuantity.toStringAsFixed(1)}g',
                        // ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            // Logik zum Entfernen des Eintrags aus dem Plan
                            // Beispiel: notifier.removeMealFromPlan(planId, entry.id);
                            ref
                                .read(mealPlanProvider.notifier)
                                .removeEntryFromPlan(planId, entry.id);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showAddMealEntryDialog(context, ref), // Aufruf des neuen Dialogs
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Hilfs-Widget für die Buttons im Modal-BottomSheet
class _ChoiceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
