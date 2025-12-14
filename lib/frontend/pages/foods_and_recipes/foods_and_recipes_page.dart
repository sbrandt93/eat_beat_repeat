import 'package:eat_beat_repeat/frontend/pages/foods_and_recipes/tabs/food_data/food_data_list.dart';
import 'package:eat_beat_repeat/frontend/pages/foods_and_recipes/tabs/predefined_food/predefined_food_list.dart';
import 'package:eat_beat_repeat/frontend/pages/foods_and_recipes/tabs/recipes/recipes_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FooodsAndRecipesPage extends ConsumerWidget {
  const FooodsAndRecipesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Liste der Tabs
    const tabs = [
      Tab(text: 'FoodData', icon: Icon(Icons.food_bank_outlined)),
      Tab(
        text: 'Vordefinierte Portionen',
        icon: Icon(Icons.inventory_2_outlined),
      ),
      Tab(text: 'Rezepte', icon: Icon(Icons.restaurant_menu_outlined)),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lebensmittel- und Rezeptverwaltung'),
          backgroundColor: Colors.indigo.shade600,
          foregroundColor: Colors.white,
          bottom: TabBar(
            tabs: tabs,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.indigo.shade200,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: TabBarView(
          children: [
            FoodDataList(),
            PredefinedFoodList(),
            RecipeList(),
          ],
        ),
      ),
    );
  }
}
