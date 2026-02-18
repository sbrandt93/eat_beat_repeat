import 'package:eat_beat_repeat/frontend/pages/foods_and_recipes/tabs/recipes/recipe_dialog.dart';
import 'package:eat_beat_repeat/frontend/pages/shared/custom_card.dart';
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

  @override
  Widget build(BuildContext context) {
    final activeRecipes = ref.watch(activeRecipesProvider);

    // Filter by search query
    final filteredList = _searchQuery.isEmpty
        ? activeRecipes
        : activeRecipes.where((recipe) {
            final query = _searchQuery.toLowerCase();
            return recipe.name.toLowerCase().contains(query);
          }).toList();

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
        Expanded(
          child: filteredList.isEmpty
              ? Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'Keine Rezepte vorhanden.'
                        : 'Keine Treffer für "$_searchQuery"',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final recipe = filteredList[index];
                    final macros = ref
                        .read(macroServiceProvider)
                        .calculateMacrosForRecipe(recipe);
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
                          const Text('Gesamtnährwerte:'),
                          Text(
                            '${macros.calories.toStringAsFixed(0)} Cal | ${macros.protein.toStringAsFixed(1)}g Protein | ${macros.carbs.toStringAsFixed(1)}g Carbs | ${macros.fat.toStringAsFixed(1)}g Fat',
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
