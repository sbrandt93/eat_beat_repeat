import 'package:eat_beat_repeat/frontend/pages/foods_and_recipes/tabs/recipes/recipe_detail_screen.dart';
import 'package:eat_beat_repeat/frontend/pages/shared/custom_card.dart';
import 'package:eat_beat_repeat/logic/models/recipe.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class RecipeList extends ConsumerWidget {
  const RecipeList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRecipes = ref.watch(activeRecipesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _startNewRecipe(context, ref),
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
        Expanded(
          child: activeRecipes.isEmpty
              ? const Center(child: Text('Keine Rezepte vorhanden.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: activeRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = activeRecipes[index];
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
                          Text(
                            'Gesamnährwerte:',
                          ),
                          Text(
                            '${macros.calories.toStringAsFixed(0)} Cal | ${macros.protein.toStringAsFixed(1)}g Protein | ${macros.carbs.toStringAsFixed(1)}g Carbs | ${macros.fat.toStringAsFixed(1)}g Fat',
                          ),
                        ],
                      ),
                      onTap: () => _editRecipe(context, ref, recipe),
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

  void _startNewRecipe(BuildContext context, WidgetRef ref) {
    final newRecipe = Recipe(
      name: '',
      ingredients: [],
    );
    _navigateToRecipeDetail(context, ref, newRecipe);
  }

  void _editRecipe(
    BuildContext context,
    WidgetRef ref,
    Recipe currentRecipe,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: currentRecipe),
      ),
    );
  }

  void _navigateToRecipeDetail(
    BuildContext context,
    WidgetRef ref,
    Recipe recipe,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    );
  }
}
