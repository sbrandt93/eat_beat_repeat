// --- REZEPT DETAIL SCREEN ---

import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/models/recipe.dart';
import 'package:eat_beat_repeat/logic/models/recipe_ingredient.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    String? selectedFoodDataId;
    double quantity = 0.0;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Zutat hinzufügen'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Lebensmittel wählen',
                  ),
                  items: foodDataMap.values.map((fd) {
                    return DropdownMenuItem(
                      value: fd.id,
                      child: Text('${fd.name} (${fd.brandName})'),
                    );
                  }).toList(),
                  onChanged: (value) => selectedFoodDataId = value,
                  validator: (value) => value == null
                      ? 'Bitte wählen Sie ein Lebensmittel.'
                      : null,
                ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Menge (in g/ml)',
                    hintText: 'Zahl',
                  ),
                  validator: (value) {
                    if (value == null ||
                        double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'Gültige positive Zahl erforderlich.';
                    }
                    return null;
                  },
                  onSaved: (value) =>
                      quantity = double.tryParse(value ?? '0') ?? 0,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  _addIngredient(selectedFoodDataId!, quantity);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Hinzufügen'),
            ),
          ],
        );
      },
    );
  }
}
