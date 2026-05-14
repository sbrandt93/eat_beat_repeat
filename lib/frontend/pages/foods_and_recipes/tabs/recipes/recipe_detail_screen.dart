// --- REZEPT DETAIL SCREEN ---

import 'package:eat_beat_repeat/frontend/pages/shared/macro_sort_bar.dart';
import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/models/recipe.dart';
import 'package:eat_beat_repeat/logic/models/recipe_ingredient.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  late TextEditingController _nameController;
  late Recipe _currentRecipe;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _currentRecipe = widget.recipe;
    _nameController = TextEditingController(text: widget.recipe.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveRecipe() {
    final updatedRecipe = _currentRecipe.copyWith(
      name: _nameController.text,
    );
    ref.read(recipeProvider.notifier).upsert(updatedRecipe);
    Navigator.of(context).pop();
  }

  void _addIngredient(String foodDataId, double quantity) {
    setState(() {
      _currentRecipe = _currentRecipe.copyWith(
        ingredients: [
          ..._currentRecipe.ingredients,
          RecipeIngredient(foodDataId: foodDataId, quantity: quantity),
        ],
      );
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      final newIngredients = List<RecipeIngredient>.from(
        _currentRecipe.ingredients,
      );
      newIngredients.removeAt(index);
      _currentRecipe = _currentRecipe.copyWith(ingredients: newIngredients);
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final foodDataMap = ref.watch(foodDataMapProvider);
    final macros = ref
        .read(macroServiceProvider)
        .calculateMacrosForRecipe(_currentRecipe);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentRecipe.name.isEmpty ? 'Neues Rezept' : 'Rezept bearbeiten',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white54,
        foregroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveRecipe,
            tooltip: 'Rezept speichern',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Rezept Name',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gesamtnährwerte:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${macros.calories.toStringAsFixed(0)} Cal | ${macros.protein.toStringAsFixed(1)}g Protein | ${macros.carbs.toStringAsFixed(1)}g Carbs | ${macros.fat.toStringAsFixed(1)}g Fat',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Zutaten',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    _toggleEditMode();
                  },
                  tooltip: _isEditMode
                      ? 'Zutaten löschen beenden'
                      : 'Zutaten löschen',
                ),
              ],
            ),
            const Divider(),

            // Dialog zum Hinzufügen von Zutaten
            ElevatedButton.icon(
              onPressed: () => _showAddIngredientDialog(context, foodDataMap),
              icon: const Icon(Icons.add),
              label: const Text('Zutat hinzufügen'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),
            // Zutaten Liste
            if (_currentRecipe.ingredients.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Center(child: Text('Fügen Sie Zutaten hinzu.')),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _currentRecipe.ingredients.length,
                  itemBuilder: (context, index) {
                    final ing = _currentRecipe.ingredients[index];
                    final fd = foodDataMap[ing.foodDataId];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      // Hier steuerst du den Abstand nach oben/unten
                      child: Row(
                        children: [
                          // Name und Menge
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fd?.name ?? 'Unbekanntes Lebensmittel',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${ing.quantity.toStringAsFixed(1)} ${fd?.defaultUnit ?? 'N/A'}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                                Builder(
                                  builder: (_) {
                                    final m = ing.getMacros(foodDataMap);
                                    return Text(
                                      '${m.calories.toStringAsFixed(0)} kcal  |  ${m.protein.toStringAsFixed(1)}g P  |  ${m.carbs.toStringAsFixed(1)}g K  |  ${m.fat.toStringAsFixed(1)}g F',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 11,
                                      ),
                                    );
                                  },
                                ),
                                const Divider(
                                  thickness: 0.5,
                                ),
                              ],
                            ),
                          ),
                          // Löschen Button (nur im Edit-Mode)
                          if (_isEditMode)
                            SizedBox(
                              height: 30, // Begrenzt die Höhe des Buttons
                              width: 30,
                              child: IconButton(
                                padding: EdgeInsets
                                    .zero, // Entfernt das interne Padding des Icons
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.red.shade700,
                                  size: 24,
                                ),
                                onPressed: () => _removeIngredient(index),
                              ),
                            ),
                        ],
                      ),
                    );

                    // ListTile(
                    //   dense: true,
                    //   title: Text(fd?.name ?? 'Unbekanntes Lebensmittel'),
                    //   subtitle: Text(
                    //     '${ing.quantity.toStringAsFixed(1)} ${fd?.defaultUnit ?? 'N/A'}',
                    //   ),
                    //   trailing: _isEditMode
                    //       ? IconButton(
                    //           icon: const Icon(Icons.delete, color: Colors.red),
                    //           onPressed: () => _removeIngredient(index),
                    //         )
                    //       : null,
                    // );

                    // ListTile(
                    //   title: Text(fd?.name ?? 'Unbekanntes Lebensmittel'),
                    //   subtitle: Text(
                    //     '${ing.quantity.toStringAsFixed(1)} ${fd?.defaultUnit ?? 'N/A'}',
                    //   ),
                    //   trailing: IconButton(
                    //     icon: const Icon(Icons.delete, color: Colors.red),
                    //     onPressed: () => _removeIngredient(index),
                    //   ),
                    // );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddIngredientDialog(
    BuildContext context,
    Map<String, FoodData> foodDataMap,
  ) {
    if (foodDataMap.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte zuerst Lebensmittel-Daten anlegen.'),
        ),
      );
      return;
    }

    String? selectedFoodDataId;
    double quantity = 0.0;
    String searchQuery = '';
    final List<MacroSortCriteria> sortCriteria = [];
    final formKey = GlobalKey<FormState>();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredFoodData = foodDataMap.values.where((fd) {
              final query = searchQuery.toLowerCase();
              return fd.name.toLowerCase().contains(query) ||
                  fd.brandName.toLowerCase().contains(query);
            }).toList();

            // Multi-column sort on macrosPer100unit
            final sortedFoodData = List.of(filteredFoodData);
            if (sortCriteria.isNotEmpty) {
              sortedFoodData.sort((a, b) {
                for (final c in sortCriteria) {
                  final double aVal;
                  final double bVal;
                  switch (c.field) {
                    case MacroSortField.calories:
                      aVal = a.macrosPer100unit.calories;
                      bVal = b.macrosPer100unit.calories;
                    case MacroSortField.protein:
                      aVal = a.macrosPer100unit.protein;
                      bVal = b.macrosPer100unit.protein;
                    case MacroSortField.carbs:
                      aVal = a.macrosPer100unit.carbs;
                      bVal = b.macrosPer100unit.carbs;
                    case MacroSortField.fat:
                      aVal = a.macrosPer100unit.fat;
                      bVal = b.macrosPer100unit.fat;
                  }
                  final cmp = c.descending
                      ? bVal.compareTo(aVal)
                      : aVal.compareTo(bVal);
                  if (cmp != 0) return cmp;
                }
                return 0;
              });
            }

            final selectedFoodData = selectedFoodDataId != null
                ? foodDataMap[selectedFoodDataId]
                : null;

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: Container(
                width: 450,
                constraints: BoxConstraints(
                  maxWidth: 450,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Zutat hinzufügen',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.x),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Search field
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Lebensmittel suchen...',
                          prefixIcon: const Icon(LucideIcons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(LucideIcons.x),
                                  onPressed: () {
                                    setDialogState(() => searchQuery = '');
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setDialogState(() => searchQuery = value);
                        },
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Sort bar
                    MacroSortBar(
                      sortCriteria: sortCriteria,
                      onToggle: (field) {
                        setDialogState(() {
                          final idx = sortCriteria.indexWhere(
                            (c) => c.field == field,
                          );
                          if (idx == -1) {
                            sortCriteria.add(
                              MacroSortCriteria(field, descending: true),
                            );
                          } else if (sortCriteria[idx].descending) {
                            sortCriteria[idx] = MacroSortCriteria(
                              field,
                              descending: false,
                            );
                          } else {
                            sortCriteria.removeAt(idx);
                          }
                        });
                      },
                      onReset: () => setDialogState(() => sortCriteria.clear()),
                    ),
                    const SizedBox(height: 4),

                    // Food list
                    Flexible(
                      child: sortedFoodData.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  searchQuery.isEmpty
                                      ? 'Keine Lebensmittel vorhanden'
                                      : 'Keine Treffer für "$searchQuery"',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: sortedFoodData.length,
                              itemBuilder: (context, index) {
                                final fd = sortedFoodData[index];
                                final isSelected = selectedFoodDataId == fd.id;
                                final m = fd.macrosPer100unit;
                                return ListTile(
                                  dense: true,
                                  selected: isSelected,
                                  selectedTileColor: Colors.teal.shade50,
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? Colors.teal
                                        : Colors.grey.shade200,
                                    radius: 16,
                                    child: Icon(
                                      isSelected
                                          ? LucideIcons.check
                                          : LucideIcons.apple,
                                      size: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  title: Text(
                                    fd.name,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${m.calories.toStringAsFixed(0)} kcal'
                                    '  |  ${m.protein.toStringAsFixed(1)}g P'
                                    '  |  ${m.carbs.toStringAsFixed(1)}g K'
                                    '  |  ${m.fat.toStringAsFixed(1)}g F'
                                    '${fd.brandName.isNotEmpty ? '\n${fd.brandName}' : ''}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  isThreeLine: fd.brandName.isNotEmpty,
                                  onTap: () {
                                    setDialogState(
                                      () => selectedFoodDataId = fd.id,
                                    );
                                  },
                                );
                              },
                            ),
                    ),

                    // Quantity input (shown when food is selected)
                    if (selectedFoodDataId != null) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ausgewählt: ${selectedFoodData?.name ?? ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: quantityController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText:
                                      'Menge (in ${selectedFoodData?.defaultUnit ?? 'g/ml'})',
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                validator: (value) {
                                  final parsed = double.tryParse(value ?? '');
                                  if (parsed == null || parsed <= 0) {
                                    return 'Gültige positive Zahl erforderlich';
                                  }
                                  return null;
                                },
                                onSaved: (value) => quantity =
                                    double.tryParse(value ?? '0') ?? 0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Footer buttons
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Abbrechen'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: selectedFoodDataId == null
                                  ? null
                                  : () {
                                      if (formKey.currentState!.validate()) {
                                        formKey.currentState!.save();
                                        _addIngredient(
                                          selectedFoodDataId!,
                                          quantity,
                                        );
                                        Navigator.of(context).pop();
                                      }
                                    },
                              icon: const Icon(LucideIcons.plus),
                              label: const Text('Hinzufügen'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
