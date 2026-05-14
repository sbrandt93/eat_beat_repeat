// --- 2. PREDEFINED FOOD LISTE MIT DIALOG ---
import 'package:eat_beat_repeat/frontend/pages/foods_and_recipes/tabs/predefined_food/predefined_food_dialog.dart';
import 'package:eat_beat_repeat/frontend/pages/shared/custom_card.dart';
import 'package:eat_beat_repeat/frontend/pages/shared/macro_sort_bar.dart';
import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
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
  final List<MacroSortCriteria> _sortCriteria = [];

  void _toggleSort(MacroSortField field) {
    setState(() {
      final idx = _sortCriteria.indexWhere((c) => c.field == field);
      if (idx == -1) {
        // New field: becomes primary (prepend)
        _sortCriteria.add(MacroSortCriteria(field, descending: true));
      } else if (_sortCriteria[idx].descending) {
        _sortCriteria[idx] = MacroSortCriteria(field, descending: false);
      } else {
        _sortCriteria.removeAt(idx);
      }
    });
  }

  void _resetSort() => setState(() => _sortCriteria.clear());

  double _macroValue(MacroNutrients m, MacroSortField field) => switch (field) {
    MacroSortField.calories => m.calories,
    MacroSortField.protein => m.protein,
    MacroSortField.carbs => m.carbs,
    MacroSortField.fat => m.fat,
  };

  @override
  Widget build(BuildContext context) {
    final activePredefinedFoods = ref.watch(activePredefinedFoodsProvider);
    final activeFoodData = ref.watch(activeFoodDataProvider);
    final macroService = ref.watch(macroServiceProvider);

    // Filter by search query
    final filteredList = _searchQuery.isEmpty
        ? activePredefinedFoods
        : activePredefinedFoods.where((pf) {
            final foodData = activeFoodData[pf.foodDataId];
            final query = _searchQuery.toLowerCase();
            return (foodData?.name.toLowerCase().contains(query) ?? false) ||
                (foodData?.brandName.toLowerCase().contains(query) ?? false);
          }).toList();

    // Pre-calculate macros for sorting
    final macrosCache = {
      for (final pf in filteredList)
        pf.id: macroService.calculateMacrosForPredefinedFood(pf),
    };

    // Multi-column sort
    final sortedList = List<PredefinedFood>.from(filteredList);
    if (_sortCriteria.isNotEmpty) {
      sortedList.sort((a, b) {
        for (final c in _sortCriteria) {
          final aVal = _macroValue(macrosCache[a.id]!, c.field);
          final bVal = _macroValue(macrosCache[b.id]!, c.field);
          final cmp = c.descending
              ? bVal.compareTo(aVal)
              : aVal.compareTo(bVal);
          if (cmp != 0) return cmp;
        }
        return 0;
      });
    }

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
        MacroSortBar(
          sortCriteria: _sortCriteria,
          onToggle: _toggleSort,
          onReset: _resetSort,
        ),
        const SizedBox(height: 4),
        Expanded(
          child: sortedList.isEmpty
              ? Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'Keine vordefinierten Portionen vorhanden.'
                        : 'Keine Treffer für "$_searchQuery"',
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
                  itemCount: sortedList.length,
                  itemBuilder: (context, index) {
                    final predefinedFood = sortedList[index];
                    final foodData = activeFoodData[predefinedFood.foodDataId];
                    final macros = macrosCache[predefinedFood.id]!;
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
                            'Menge: ${predefinedFood.quantity.toStringAsFixed(1)} ${foodData?.defaultUnit ?? 'N/A'}',
                          ),
                          Text(
                            '${macros.calories.toStringAsFixed(0)} kcal  |  ${macros.protein.toStringAsFixed(1)}g P  |  ${macros.carbs.toStringAsFixed(1)}g K  |  ${macros.fat.toStringAsFixed(1)}g F',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
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
