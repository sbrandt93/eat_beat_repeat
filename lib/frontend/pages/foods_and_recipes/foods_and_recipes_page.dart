import 'package:eat_beat_repeat/frontend/pages/foods_and_recipes/tabs/food_data/food_data_list.dart';
import 'package:eat_beat_repeat/frontend/pages/foods_and_recipes/tabs/predefined_food/predefined_food_list.dart';
import 'package:eat_beat_repeat/frontend/pages/foods_and_recipes/tabs/recipes/recipes_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class FooodsAndRecipesPage extends ConsumerWidget {
  const FooodsAndRecipesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Liste der Tabs
    const tabs = [
      Tab(text: 'Rezepte', icon: Icon(LucideIcons.cookingPot)),
      Tab(
        text: 'Portionen',
        icon: Icon(LucideIcons.banana),
      ),
      Tab(text: 'Daten', icon: Icon(LucideIcons.notebookText)),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: Colors.teal.shade50,
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(
                'assets/vion/vion_lick.png',
                height: 50,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Lebensmittel & Rezepte',
                    style: TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // backgroundColor: Colors.white54,
          bottom: TabBar(
            tabs: tabs,
            indicatorColor: Colors.white,
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.black54,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: TabBarView(
          children: [
            RecipeList(),
            PredefinedFoodList(),
            FoodDataList(),
          ],
        ),
      ),
    );
  }
}
