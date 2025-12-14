// --- 3. REZEPT LISTE UND DETAILANSICHT ---
import 'package:eat_beat_repeat/frontend/pages/foods_and_recipes/tabs/recipes/recipe_detail_screen.dart';
import 'package:eat_beat_repeat/logic/models/recipe.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecipeList extends ConsumerWidget {
  const RecipeList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeMap = ref.watch(recipeProvider);
    final recipeList = recipeMap.values.toList();

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
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(
          child: recipeList.isEmpty
              ? const Center(child: Text('Keine Rezepte vorhanden.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: recipeList.length,
                  itemBuilder: (context, index) {
                    final recipe = recipeList[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.pink.shade100,
                          child: Icon(
                            Icons.local_dining,
                            color: Colors.pink.shade600,
                          ),
                        ),
                        title: Text(
                          recipe!.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${recipe.ingredients.length} Zutaten',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            _navigateToRecipeDetail(context, ref, recipe),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _startNewRecipe(BuildContext context, WidgetRef ref) {
    final newRecipe = Recipe(
      name: 'Neues Rezept',
      ingredients: [],
    );
    _navigateToRecipeDetail(context, ref, newRecipe);
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
