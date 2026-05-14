import 'package:eat_beat_repeat/frontend/pages/foods_and_recipes/tabs/recipes/recipe_dialog.dart';
import 'package:eat_beat_repeat/frontend/pages/shared/custom_card.dart';
import 'package:eat_beat_repeat/frontend/pages/shared/macro_sort_bar.dart';
import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:eat_beat_repeat/logic/models/recipe.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class RecipeList extends ConsumerStatefulWidget {
  const RecipeList({super.key});

  @override
  ConsumerState<RecipeList> createState() => _RecipeListState();
}

class _RecipeListState extends ConsumerState<RecipeList> {
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
    final activeRecipes = ref.watch(activeRecipesProvider);
    final macroService = ref.watch(macroServiceProvider);

    // Filter by search query
    final filteredList = _searchQuery.isEmpty
        ? activeRecipes
        : activeRecipes.where((recipe) {
            final query = _searchQuery.toLowerCase();
            return recipe.name.toLowerCase().contains(query);
          }).toList();

    // Pre-calculate macros for sorting
    final macrosCache = {
      for (final r in filteredList)
        r.id: macroService.calculateMacrosForRecipe(r),
    };

    // Multi-column sort
    final sortedList = List<Recipe>.from(filteredList);
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
            onPressed: () => showRecipeDialog(context: context),
            icon: const Icon(Icons.add),
            label: const Text('Neues Rezept anlegen'),
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
                        ? 'Keine Rezepte vorhanden.'
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
                    final recipe = sortedList[index];
                    final macros = macrosCache[recipe.id]!;
                    return CustomCard(
                      key: ValueKey(recipe.id),
                      avatarColor: Colors.teal.shade100,
                      avatarIcon: LucideIcons.cookingPot,
                      avatarIconColor: Colors.teal,
                      title: Text(
                        recipe.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${recipe.ingredients.length} Zutat(en):'),
                          Text(
                            '${macros.calories.toStringAsFixed(0)} kcal  |  ${macros.protein.toStringAsFixed(1)}g P  |  ${macros.carbs.toStringAsFixed(1)}g K  |  ${macros.fat.toStringAsFixed(1)}g F',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => showRecipeDialog(
                        context: context,
                        existingRecipe: recipe,
                      ),
                      onDiscarding: () {
                        ref
                            .read(recipeProvider.notifier)
                            .moveToTrash(recipe.id);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
