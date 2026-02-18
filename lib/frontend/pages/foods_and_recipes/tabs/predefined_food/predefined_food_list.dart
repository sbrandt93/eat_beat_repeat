// --- 2. PREDEFINED FOOD LISTE MIT DIALOG ---
import 'package:eat_beat_repeat/frontend/pages/foods_and_recipes/tabs/predefined_food/predefined_food_dialog.dart';
import 'package:eat_beat_repeat/frontend/pages/shared/custom_card.dart';
import 'package:eat_beat_repeat/logic/models/predefined_food.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PredefinedFoodList extends ConsumerStatefulWidget {
  const PredefinedFoodList({super.key});

  @override
  ConsumerState<PredefinedFoodList> createState() => _PredefinedFoodListState();
}

class _PredefinedFoodListState extends ConsumerState<PredefinedFoodList> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final activePredefinedFoods = ref.watch(activePredefinedFoodsProvider);
    final activeFoodData = ref.watch(activeFoodDataProvider);

    // Filter by search query
    final filteredList = _searchQuery.isEmpty
        ? activePredefinedFoods
        : activePredefinedFoods.where((pf) {
            final foodData = activeFoodData[pf.foodDataId];
            final query = _searchQuery.toLowerCase();
            return (foodData?.name.toLowerCase().contains(query) ?? false) ||
                (foodData?.brandName.toLowerCase().contains(query) ?? false);
          }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showPredefinedFoodDialog(context),
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
        // Search field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Suchen...',
              prefixIcon: const Icon(LucideIcons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filteredList.isEmpty
              ? Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'Keine vordefinierten Portionen vorhanden.'
                        : 'Keine Treffer für "$_searchQuery"',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final predefinedFood = filteredList[index];
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
                          Text(
                            '${macros.calories.toStringAsFixed(0)} Cal | ${macros.protein.toStringAsFixed(1)}g Protein | ${macros.carbs.toStringAsFixed(1)}g Carbs | ${macros.fat.toStringAsFixed(1)}g Fat',
                          ),
                        ],
                      ),
                      onTap: () {
                        _showPredefinedFoodDialog(
                          context,
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

  void _showPredefinedFoodDialog(
    BuildContext context, {
    PredefinedFood? existingPredefinedFood,
  }) {
    final foodDataList = ref.read(foodDataMapProvider);
    if (foodDataList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bitte zuerst FoodData-Einträge anlegen, um vordefinierte Portionen zu erstellen.',
          ),
        ),
      );
      return;
    }
    showPredefinedFoodDialog(
      context: context,
      existingPredefinedFood: existingPredefinedFood,
    );
  }
}
