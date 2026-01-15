import 'package:eat_beat_repeat/frontend/pages/shared/custom_alert_dilaog.dart';
import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/models/predefined_food.dart';
import 'package:eat_beat_repeat/logic/models/recipe.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:eat_beat_repeat/logic/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TrashPage extends ConsumerStatefulWidget {
  const TrashPage({super.key});

  @override
  ConsumerState<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends ConsumerState<TrashPage> {
  bool _isCleaningUp = true;

  @override
  void initState() {
    super.initState();
    _performAutoCleanup();
  }

  Future<void> _performAutoCleanup() async {
    // Wir warten, bis der erste Frame gerendert wurde
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      const autoDeleteThreshold = Duration(days: 30);

      // Cleanup durchführen
      ref.read(recipeProvider.notifier).autoDeleteOldItems(autoDeleteThreshold);
      ref
          .read(predefinedFoodProvider.notifier)
          .autoDeleteOldItems(autoDeleteThreshold);
      ref
          .read(foodDataMapProvider.notifier)
          .autoDeleteOldItems(autoDeleteThreshold);

      // Kurze Verzögerung für den visuellen Effekt
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _isCleaningUp = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCleaningUp) {
      return Scaffold(
        backgroundColor: Colors.red.shade50,
        appBar: AppBar(
          title: const Text(
            'Papierkorb',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.red.shade100,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.red.shade700,
              ),
              const SizedBox(height: 16),
              Text(
                'Alte Einträge werden bereinigt...',
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // trashed lists
    final trashedRecipesList = ref.watch(
      trashedRecipesProvider,
    );
    final trashedPredefinedFoodsList = ref.watch(
      trashedPredefinedFoodsProvider,
    );
    final trashedFoodDataList = ref
        .watch(trashedFoodDataProvider)
        .values
        .toList();

    final Map<String, List> allTrashedLists = {
      'Recipes': trashedRecipesList,
      'PredefinedFoods': trashedPredefinedFoodsList,
      'FoodData': trashedFoodDataList,
    };
    final tabs = getActiveTabs(allTrashedLists);

    return DefaultTabController(
      length: tabs.isEmpty ? 1 : tabs.length,
      child: Scaffold(
        backgroundColor: Colors.red.shade50,
        appBar: AppBar(
          title: const Text(
            'Papierkorb',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.red.shade100,
          bottom: TabBar(
            tabs: tabs.isEmpty ? [Tab(text: 'Keine Einträge')] : tabs,
            indicatorColor: Colors.white,
            labelColor: Colors.red.shade700,
            unselectedLabelColor: Colors.black54,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: TabBarView(
          children: tabs.isEmpty
              ? [
                  const Center(
                    child: Text('Der Papierkorb ist leer.'),
                  ),
                ]
              : tabs.map((tab) {
                  switch (tab.text) {
                    case 'Rezepte':
                      return trashedRecipesList.isNotEmpty
                          ? ListView.builder(
                              itemCount: trashedRecipesList.length,
                              itemBuilder: (context, index) {
                                final trashedItem = trashedRecipesList[index];
                                return _buildTrashListTile(
                                  context,
                                  ref,
                                  trashedItem,
                                );
                              },
                            )
                          : const Center(
                              child: Text('Keine gelöschten Rezepte.'),
                            );
                    case 'Portionen':
                      return trashedPredefinedFoodsList.isNotEmpty
                          ? ListView.builder(
                              itemCount: trashedPredefinedFoodsList.length,
                              itemBuilder: (context, index) {
                                final trashedItem =
                                    trashedPredefinedFoodsList[index];
                                return _buildTrashListTile(
                                  context,
                                  ref,
                                  trashedItem,
                                );
                              },
                            )
                          : const Center(
                              child: Text('Keine gelöschten Portionen.'),
                            );
                    case 'Daten':
                      return trashedFoodDataList.isNotEmpty
                          ? ListView.builder(
                              itemCount: trashedFoodDataList.length,
                              itemBuilder: (context, index) {
                                final trashedItem = trashedFoodDataList[index];
                                return _buildTrashListTile(
                                  context,
                                  ref,
                                  trashedItem,
                                );
                              },
                            )
                          : const Center(
                              child: Text('Keine gelöschten Food Data.'),
                            );
                    default:
                      return Center(
                        child: Text('Kein Papierkorb Inhalt für ${tab.text}.'),
                      );
                  }
                }).toList(),
        ),
      ),
    );
  }
}

List<Tab> getActiveTabs(Map<String, List> allTrashedLists) {
  // check if there is any trashed item in each category
  final tabs = <Tab>[];
  if (allTrashedLists['Recipes']!.isNotEmpty) {
    tabs.add(
      Tab(
        text: 'Rezepte',
        icon: Icon(LucideIcons.cookingPot),
      ),
    );
  }
  if (allTrashedLists['PredefinedFoods']!.isNotEmpty) {
    tabs.add(
      Tab(
        text: 'Portionen',
        icon: Icon(LucideIcons.banana),
      ),
    );
  }
  if (allTrashedLists['FoodData']!.isNotEmpty) {
    tabs.add(Tab(text: 'Daten', icon: Icon(LucideIcons.notebookText)));
  }
  return tabs;
}

ListTile _buildTrashListTile(
  BuildContext context,
  WidgetRef ref,
  dynamic trashedItem,
) {
  final foodDataMap = ref.watch(foodDataMapProvider);
  switch (trashedItem.runtimeType) {
    // Recipe
    case const (Recipe):
      final recipe = trashedItem as Recipe;
      return ListTile(
        title: Text(recipe.name),
        subtitle: Text(
          'Verbleibend: ${timeDifference(DateTime.now(), recipe.deletedAt!.add(autoDeleteDuration))}',
          style: const TextStyle(fontSize: 12, color: Colors.redAccent),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.restore),
              onPressed: () {
                ref.read(recipeProvider.notifier).restore(recipe.id);
              },
            ),
            IconButton(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_forever),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return CustomAlertDialog(
                      title: 'Endgültig löschen',
                      content:
                          'Möchten Sie dieses Rezept wirklich endgültig löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
                      type: AlertType.delete,
                      actions: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Abbrechen'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            onPressed: () {
                              ref
                                  .read(recipeProvider.notifier)
                                  .hardDelete(recipe.id);
                              Navigator.of(context).pop();
                            },
                            child: const Text('Löschen'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      );
    // PredefinedFood
    case const (PredefinedFood):
      final predefinedFood = trashedItem as PredefinedFood;
      return ListTile(
        title: Text(
          '${foodDataMap[predefinedFood.foodDataId]?.name ?? '<Unknown>'} - ${predefinedFood.quantity.toStringAsFixed(1)}${foodDataMap[predefinedFood.foodDataId]?.defaultUnit ?? 'N/A'} ',
        ),
        subtitle: Text(
          'Verbleibend: ${timeDifference(DateTime.now(), predefinedFood.deletedAt!.add(autoDeleteDuration))}',
          style: const TextStyle(fontSize: 12, color: Colors.redAccent),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.restore),
              onPressed: () {
                ref
                    .read(predefinedFoodProvider.notifier)
                    .restore(predefinedFood.id);
              },
            ),
            IconButton(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_forever),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return CustomAlertDialog(
                      title: 'Endgültig löschen',
                      content:
                          'Möchten Sie diese vordefinierte Portion wirklich endgültig löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
                      type: AlertType.delete,
                      actions: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Abbrechen'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            onPressed: () {
                              ref
                                  .read(predefinedFoodProvider.notifier)
                                  .hardDelete(predefinedFood.id);
                              Navigator.of(context).pop();
                            },
                            child: const Text('Löschen'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      );
    case const (FoodData):
      final foodData = trashedItem as FoodData;
      return ListTile(
        title: Text(foodData.name),
        subtitle: Text(
          'Verbleibend: ${timeDifference(DateTime.now(), foodData.deletedAt!.add(autoDeleteDuration))}',
          style: const TextStyle(fontSize: 12, color: Colors.redAccent),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.restore),
              onPressed: () {
                ref.read(foodDataMapProvider.notifier).restore(foodData.id);
              },
            ),
            IconButton(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_forever),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return CustomAlertDialog(
                      title: 'Endgültig löschen',
                      content:
                          'Möchten Sie diese Lebensmitteldaten wirklich endgültig löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
                      type: AlertType.delete,
                      actions: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Abbrechen'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            onPressed: () {
                              ref
                                  .read(foodDataMapProvider.notifier)
                                  .hardDelete(foodData.id);
                              Navigator.of(context).pop();
                            },
                            child: const Text('Löschen'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      );
    default:
      return const ListTile(
        title: Text('Unknown trashed item'),
      );
  }
}
