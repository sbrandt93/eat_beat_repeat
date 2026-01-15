// --- 2. PREDEFINED FOOD LISTE MIT DIALOG ---
import 'package:eat_beat_repeat/frontend/pages/foods_and_recipes/tabs/predefined_food/predefined_food_dialog.dart';
import 'package:eat_beat_repeat/frontend/pages/shared/custom_card.dart';
import 'package:eat_beat_repeat/logic/models/predefined_food.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PredefinedFoodList extends ConsumerWidget {
  const PredefinedFoodList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final predefinedFoodMap = ref.watch(predefinedFoodProvider);
    // final predefinedFoodList = predefinedFoodMap.values.toList();
    final activePredefinedFoods = ref.watch(activePredefinedFoodsProvider);
    final activeFoodData = ref.watch(activeFoodDataProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showPredefinedFoodDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Vordefinierte Portion anlegen'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(
          child: activePredefinedFoods.isEmpty
              ? const Center(
                  child: Text('Keine vordefinierten Portionen vorhanden.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: activePredefinedFoods.length,
                  itemBuilder: (context, index) {
                    final predefinedFood = activePredefinedFoods[index];
                    final foodData = activeFoodData[predefinedFood.foodDataId];
                    final macros = ref
                        .read(macroServiceProvider)
                        .calculateMacrosForPredefinedFood(predefinedFood);
                    return CustomCard(
                      key: ValueKey(predefinedFood.id),
                      avatarColor: Colors.teal.shade100,
                      avatarIcon: LucideIcons.banana,
                      avatarIconColor: Colors.teal,
                      title: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  foodData?.name ??
                                  '<Lebensmitteldaten gelöscht>',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: foodData == null
                                    ? Colors.red.shade300
                                    : Colors.black,
                              ),
                            ),
                            if (foodData?.brandName.isNotEmpty ?? false)
                              TextSpan(
                                text: ' (${foodData?.brandName})',
                                style: TextStyle(
                                  color: Colors.grey.shade900,
                                ),
                              ),
                          ],
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Menge: ${predefinedFood.quantity.toStringAsFixed(1)}${foodData?.defaultUnit ?? 'N/A'} | Nährwerte:',
                          ),
                          // macros berechnen using calculateMacrosForPredefinedFood
                          Text(
                            '${macros.calories.toStringAsFixed(0)} Cal | ${macros.protein.toStringAsFixed(1)}g Protein | ${macros.carbs.toStringAsFixed(1)}g Carbs | ${macros.fat.toStringAsFixed(1)}g Fat',
                          ),
                        ],
                      ),
                      // Text(
                      //   'Menge: ${predefinedFood.quantity.toStringAsFixed(1)} ${foodData?.defaultUnit ?? 'N/A'}',
                      // ),
                      onTap: () {
                        _showPredefinedFoodDialog(
                          context,
                          ref,
                          existingPredefinedFood: predefinedFood,
                        );
                      },
                      onDiscarding: () {
                        ref
                            .read(predefinedFoodProvider.notifier)
                            .moveToTrash(predefinedFood.id);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

void _showPredefinedFoodDialog(
  BuildContext context,
  WidgetRef ref, {
  PredefinedFood? existingPredefinedFood,
}) {
  final foodDataList = ref.read(foodDataMapProvider);
  if (foodDataList.isEmpty) {
    // Benutzerfreundliche Meldung, falls keine FoodData existiert
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Bitte zuerst FoodData-Einträge anlegen, um vordefinierte Portionen zu erstellen.',
        ),
      ),
    );
    return;
  }
  showDialog(
    context: context,
    builder: (context) =>
        PredefinedFoodDialog(existingPredefinedFood: existingPredefinedFood),
  );
}
