import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/models/recipe.dart';
import 'package:eat_beat_repeat/logic/models/recipe_ingredient.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shows the Recipe Dialog and returns the created/updated Recipe
Future<Recipe?> showRecipeDialog({
  required BuildContext context,
  Recipe? existingRecipe,
}) {
  return showDialog<Recipe>(
    context: context,
    barrierDismissible: false,
    builder: (context) => RecipeDialog(existingRecipe: existingRecipe),
  );
}

class RecipeDialog extends ConsumerStatefulWidget {
  final Recipe? existingRecipe;

  const RecipeDialog({super.key, this.existingRecipe});

  @override
  ConsumerState<RecipeDialog> createState() => _RecipeDialogState();
}

class _RecipeDialogState extends ConsumerState<RecipeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late List<RecipeIngredient> _ingredients;

  bool get _isEdit => widget.existingRecipe != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingRecipe;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _ingredients = existing != null
        ? List<RecipeIngredient>.from(existing.ingredients)
        : [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: screenHeight * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                child: _buildContent(),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _isEdit ? 'Rezept bearbeiten' : 'Neues Rezept',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Schließen',
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final foodDataMap = ref.watch(activeFoodDataProvider);
    final macros = ref
        .read(macroServiceProvider)
        .calculateMacrosForRecipe(
          Recipe(
            name: _nameController.text,
            ingredients: _ingredients,
          ),
        );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Recipe name
            const Text(
              'Rezept Name',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte einen Namen eingeben';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Macro summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gesamtnährwerte:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${macros.calories.toStringAsFixed(0)} kcal | '
                    '${macros.protein.toStringAsFixed(1)}g P | '
                    '${macros.carbs.toStringAsFixed(1)}g K | '
                    '${macros.fat.toStringAsFixed(1)}g F',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Ingredients header with add button
            Row(
              children: [
                const Text(
                  'Zutaten',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddIngredientDialog(foodDataMap),
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('Hinzufügen'),
                  style: TextButton.styleFrom(foregroundColor: Colors.teal),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Info if no food data exists
            if (foodDataMap.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.circleAlert,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bitte zuerst Lebensmittel-Daten anlegen.',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Ingredients list
            if (_ingredients.isEmpty && foodDataMap.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Keine Zutaten hinzugefügt',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ..._ingredients.asMap().entries.map((entry) {
                final index = entry.key;
                final ingredient = entry.value;
                final foodData = foodDataMap[ingredient.foodDataId];

                return _buildIngredientItem(index, ingredient, foodData);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientItem(
    int index,
    RecipeIngredient ingredient,
    FoodData? foodData,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  foodData?.name ?? 'Unbekanntes Lebensmittel',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: foodData == null ? Colors.red.shade300 : null,
                  ),
                ),
                Text(
                  '${ingredient.quantity.toStringAsFixed(1)} ${foodData?.defaultUnit ?? 'g'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              LucideIcons.trash2,
              color: Colors.red.shade400,
              size: 18,
            ),
            onPressed: () => _removeIngredient(index),
            tooltip: 'Entfernen',
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
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
              onPressed: _saveRecipe,
              icon: const Icon(LucideIcons.check),
              label: const Text('Speichern'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addIngredient(String foodDataId, double quantity) {
    setState(() {
      _ingredients.add(
        RecipeIngredient(foodDataId: foodDataId, quantity: quantity),
      );
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _showAddIngredientDialog(Map<String, FoodData> foodDataMap) {
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
    final formKey = GlobalKey<FormState>();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Filter food data by search query
            final filteredFoodData = foodDataMap.values.where((fd) {
              final query = searchQuery.toLowerCase();
              return fd.name.toLowerCase().contains(query) ||
                  fd.brandName.toLowerCase().contains(query);
            }).toList();

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
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Lebensmittel suchen',
                          prefixIcon: const Icon(LucideIcons.search),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
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

                    // Food data list
                    Flexible(
                      child: filteredFoodData.isEmpty
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
                              itemCount: filteredFoodData.length,
                              itemBuilder: (context, index) {
                                final fd = filteredFoodData[index];
                                final isSelected = selectedFoodDataId == fd.id;

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
                                  subtitle: fd.brandName.isNotEmpty
                                      ? Text(fd.brandName)
                                      : null,
                                  trailing: Text(
                                    '${fd.macrosPer100unit.calories.toStringAsFixed(0)} kcal',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  onTap: () {
                                    setDialogState(
                                      () => selectedFoodDataId = fd.id,
                                    );
                                  },
                                );
                              },
                            ),
                    ),

                    // Quantity input (only when food is selected)
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

  void _saveRecipe() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final recipeNotifier = ref.read(recipeProvider.notifier);

    if (_isEdit) {
      final updatedRecipe = widget.existingRecipe!.copyWith(
        name: _nameController.text.trim(),
        ingredients: _ingredients,
      );
      recipeNotifier.upsert(updatedRecipe);
      Navigator.of(context).pop(updatedRecipe);
    } else {
      final newRecipe = Recipe(
        name: _nameController.text.trim(),
        ingredients: _ingredients,
      );
      recipeNotifier.upsert(newRecipe);
      Navigator.of(context).pop(newRecipe);
    }
  }
}
