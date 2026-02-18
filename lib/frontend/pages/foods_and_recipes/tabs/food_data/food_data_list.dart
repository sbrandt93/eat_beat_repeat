// --- 1. FOOD DATA LISTE MIT DIALOG ---
import 'package:eat_beat_repeat/frontend/pages/foods_and_recipes/tabs/food_data/food_data_dialog.dart';
import 'package:eat_beat_repeat/frontend/pages/shared/custom_card.dart';
import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class FoodDataList extends ConsumerStatefulWidget {
  const FoodDataList({super.key});

  @override
  ConsumerState<FoodDataList> createState() => _FoodDataListState();
}

class _FoodDataListState extends ConsumerState<FoodDataList> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final activeFoodDataList = ref
        .watch(activeFoodDataProvider)
        .values
        .toList();

    // Filter by search query
    final filteredList = _searchQuery.isEmpty
        ? activeFoodDataList
        : activeFoodDataList.where((fd) {
            final query = _searchQuery.toLowerCase();
            return fd.name.toLowerCase().contains(query) ||
                fd.brandName.toLowerCase().contains(query);
          }).toList();

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
                        ? 'Keine Lebensmitteldaten vorhanden.'
                        : 'Keine Treffer für "$_searchQuery"',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final foodData = filteredList[index];
                    return CustomCard(
                      key: ValueKey(foodData.id),
                      avatarColor: Colors.teal.shade100,
                      avatarIcon: LucideIcons.notebookText,
                      avatarIconColor: Colors.teal,
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
                            '${foodData.macrosPer100unit.calories.toStringAsFixed(0)} Cal | ${foodData.macrosPer100unit.protein.toStringAsFixed(1)}g P | ${foodData.macrosPer100unit.carbs.toStringAsFixed(1)}g C | ${foodData.macrosPer100unit.fat.toStringAsFixed(1)}g F',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
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
                        ref
                            .read(foodDataMapProvider.notifier)
                            .moveToTrash(foodData.id);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showFoodDataDialog(
    BuildContext context,
    WidgetRef ref, {
    FoodData? existingFoodData,
  }) {
    showFoodDataDialog(
      context: context,
      existingFoodData: existingFoodData,
    );
  }
}
