// --- 1. FOOD DATA LISTE MIT DIALOG ---
import 'package:eat_beat_repeat/frontend/pages/foods_and_recipes/tabs/food_data/food_data_dialog.dart';
import 'package:eat_beat_repeat/frontend/pages/shared/custom_card.dart';
import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FoodDataList extends ConsumerWidget {
  const FoodDataList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodDataMap = ref.watch(foodDataProvider);
    final foodDataList = foodDataMap.values.toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showFoodDataDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Neues FoodData anlegen'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(
          child: foodDataList.isEmpty
              ? const Center(child: Text('Keine Lebensmitteldaten vorhanden.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: foodDataList.length,
                  itemBuilder: (context, index) {
                    final foodData = foodDataList[index];
                    return CustomCard(
                      key: ValueKey(foodData.id),
                      avatarColor: Colors.indigo.shade100,
                      avatarIcon: Icons.list_alt,
                      title: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(
                              text: foodData.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (foodData.brandName.isNotEmpty)
                              TextSpan(
                                text: ' (${foodData.brandName})',
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
                          Text('Nährwerte pro 100${foodData.defaultUnit}:'),

                          Text(
                            '${foodData.macrosPer100unit.calories.toStringAsFixed(0)} Cal | ${foodData.macrosPer100unit.protein.toStringAsFixed(1)}${foodData.defaultUnit} Protein | ${foodData.macrosPer100unit.carbs.toStringAsFixed(1)}${foodData.defaultUnit} Carbs | ${foodData.macrosPer100unit.fat.toStringAsFixed(1)}${foodData.defaultUnit} Fat',
                          ),
                        ],
                      ),
                      onTap: () {
                        _showFoodDataDialog(
                          context,
                          ref,
                          existingFoodData: foodData,
                        );
                      },
                      onDiscarding: () {
                        ref.read(foodDataProvider.notifier).remove(foodData.id);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

void _showFoodDataDialog(
  BuildContext context,
  WidgetRef ref, {
  FoodData? existingFoodData,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return FoodDataDialog(existingFoodData: existingFoodData);
    },
  );
}
