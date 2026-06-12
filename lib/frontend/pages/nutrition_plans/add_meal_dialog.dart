import 'dart:io';

import 'package:eat_beat_repeat/frontend/pages/shared/food_image_avatar.dart';
import 'package:flutter/foundation.dart';
import 'package:eat_beat_repeat/frontend/pages/shared/macro_sort_bar.dart';
import 'package:eat_beat_repeat/frontend/pages/shared/nutrition_scan_button.dart';
import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:eat_beat_repeat/logic/models/meal_entry.dart';
import 'package:eat_beat_repeat/logic/models/nutrition_plan.dart';
import 'package:eat_beat_repeat/logic/models/predefined_food.dart';
import 'package:eat_beat_repeat/logic/models/recipe.dart';
import 'package:eat_beat_repeat/logic/models/recipe_ingredient.dart';
import 'package:eat_beat_repeat/logic/models/recurrence_rule.dart';
import 'package:eat_beat_repeat/logic/models/recurring_meal_template.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:eat_beat_repeat/logic/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shows the Add Meal Dialog and returns true if a meal was added
Future<bool?> showAddMealDialog({
  required BuildContext context,
  required NutritionPlan plan,
  required DateTime selectedDate,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AddMealDialog(
      plan: plan,
      selectedDate: selectedDate,
    ),
  );
}

class AddMealDialog extends ConsumerStatefulWidget {
  final NutritionPlan plan;
  final DateTime selectedDate;

  const AddMealDialog({
    super.key,
    required this.plan,
    required this.selectedDate,
  });

  @override
  ConsumerState<AddMealDialog> createState() => _AddMealDialogState();
}

enum _DialogStep {
  selectType,
  selectPortion,
  selectRecipe,
  createPortion,
  createRecipe,
}

class _AddMealDialogState extends ConsumerState<AddMealDialog> {
  _DialogStep _currentStep = _DialogStep.selectType;

  // Recurring settings
  bool _isRecurring = true;
  RecurrencePattern _selectedPattern = RecurrencePattern.daily;
  final List<int> _selectedDays = [];

  // Search
  String _searchQuery = '';
  final List<MacroSortCriteria> _portionSortCriteria = [];
  final List<MacroSortCriteria> _recipeSortCriteria = [];

  void _togglePortionSort(MacroSortField field) {
    setState(() {
      final idx = _portionSortCriteria.indexWhere((c) => c.field == field);
      if (idx == -1) {
        _portionSortCriteria.add(MacroSortCriteria(field, descending: true));
      } else if (_portionSortCriteria[idx].descending) {
        _portionSortCriteria[idx] = MacroSortCriteria(field, descending: false);
      } else {
        _portionSortCriteria.removeAt(idx);
      }
    });
  }

  void _toggleRecipeSort(MacroSortField field) {
    setState(() {
      final idx = _recipeSortCriteria.indexWhere((c) => c.field == field);
      if (idx == -1) {
        _recipeSortCriteria.add(MacroSortCriteria(field, descending: true));
      } else if (_recipeSortCriteria[idx].descending) {
        _recipeSortCriteria[idx] = MacroSortCriteria(field, descending: false);
      } else {
        _recipeSortCriteria.removeAt(idx);
      }
    });
  }

  static double _macroValue(MacroNutrients m, MacroSortField field) =>
      switch (field) {
        MacroSortField.calories => m.calories,
        MacroSortField.protein => m.protein,
        MacroSortField.carbs => m.carbs,
        MacroSortField.fat => m.fat,
      };

  // Create portion form
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _brand = '';
  String _unit = FoodUnit.gramm.displayString;
  double _calories = 0;
  double _protein = 0;
  double _carbs = 0;
  double _fat = 0;
  double _portionQuantity = 100;

  late TextEditingController _caloriesCtrl;
  late TextEditingController _proteinCtrl;
  late TextEditingController _carbsCtrl;
  late TextEditingController _fatCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _brandCtrl;

  // Image paths for create forms
  String? _portionImagePath;
  String? _recipeImagePath;

  // Create recipe form
  String _recipeName = '';
  List<RecipeIngredient> _recipeIngredients = [];

  @override
  void initState() {
    super.initState();
    _caloriesCtrl = TextEditingController();
    _proteinCtrl = TextEditingController();
    _carbsCtrl = TextEditingController();
    _fatCtrl = TextEditingController();
    _nameCtrl = TextEditingController(text: _name);
    _brandCtrl = TextEditingController(text: _brand);
  }

  @override
  void dispose() {
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = (screenHeight * 0.9 - viewInsets.bottom).clamp(
      300.0,
      screenHeight * 0.9,
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 500,
        height: availableHeight,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: availableHeight,
        ),
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1),
            Expanded(
              child: _buildContent(),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    // Only show cancel button on type selection
    if (_currentStep == _DialogStep.selectType) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentStep != _DialogStep.selectType)
                IconButton(
                  icon: const Icon(LucideIcons.arrowLeft),
                  onPressed: _goBack,
                  tooltip: 'Zurück',
                ),
              Expanded(
                child: Text(
                  _getTitle(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: _currentStep == _DialogStep.selectType
                      ? TextAlign.center
                      : TextAlign.left,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => Navigator.of(context).pop(false),
                tooltip: 'Schließen',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Recurring Toggle
          _buildRecurringToggle(),
          if (_isRecurring) ...[
            const SizedBox(height: 12),
            _RecurrenceSelector(
              selectedPattern: _selectedPattern,
              selectedDays: _selectedDays,
              onPatternChanged: (p) => setState(() => _selectedPattern = p),
              onDaysChanged: (days) => setState(() {
                _selectedDays
                  ..clear()
                  ..addAll(days);
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecurringToggle() {
    return Row(
      children: [
        Expanded(
          child: _TabButton(
            label: 'Wiederkehrend',
            isSelected: _isRecurring,
            onTap: () => setState(() => _isRecurring = true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TabButton(
            label: 'Nur heute',
            isSelected: !_isRecurring,
            onTap: () => setState(() => _isRecurring = false),
          ),
        ),
      ],
    );
  }

  String _getTitle() {
    switch (_currentStep) {
      case _DialogStep.selectType:
        return 'Mahlzeit hinzufügen';
      case _DialogStep.selectPortion:
        return 'Portion wählen';
      case _DialogStep.selectRecipe:
        return 'Rezept wählen';
      case _DialogStep.createPortion:
        return 'Neue Portion anlegen';
      case _DialogStep.createRecipe:
        return 'Neues Rezept anlegen';
    }
  }

  Widget _buildContent() {
    switch (_currentStep) {
      case _DialogStep.selectType:
        return _buildTypeSelection();
      case _DialogStep.selectPortion:
        return _buildPortionSelection();
      case _DialogStep.selectRecipe:
        return _buildRecipeSelection();
      case _DialogStep.createPortion:
        return SingleChildScrollView(child: _buildCreatePortionForm());
      case _DialogStep.createRecipe:
        return SingleChildScrollView(child: _buildCreateRecipeForm());
    }
  }

  void _goBack() {
    setState(() {
      switch (_currentStep) {
        case _DialogStep.selectType:
          break;
        case _DialogStep.selectPortion:
        case _DialogStep.selectRecipe:
          _currentStep = _DialogStep.selectType;
          _searchQuery = '';
        case _DialogStep.createPortion:
          _currentStep = _DialogStep.selectPortion;
        case _DialogStep.createRecipe:
          _currentStep = _DialogStep.selectRecipe;
          _recipeName = '';
          _recipeIngredients = [];
      }
    });
  }

  // ============================================================================
  // STEP 1: Type Selection
  // ============================================================================

  Widget _buildTypeSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _TypeCard(
            icon: LucideIcons.banana,
            title: 'Einzelne Portion',
            subtitle: 'Ein Lebensmittel mit fester Menge',
            color: Colors.orange,
            onTap: () => setState(() {
              _currentStep = _DialogStep.selectPortion;
              _searchQuery = '';
            }),
          ),
          const SizedBox(height: 12),
          _TypeCard(
            icon: LucideIcons.cookingPot,
            title: 'Rezept',
            subtitle: 'Eine Kombination aus mehreren Zutaten',
            color: Colors.teal,
            onTap: () => setState(() {
              _currentStep = _DialogStep.selectRecipe;
              _searchQuery = '';
            }),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // STEP 2a: Portion Selection
  // ============================================================================

  Widget _buildPortionSelection() {
    final predefinedFoods = ref.watch(activePredefinedFoodsProvider);
    final foodDataMap = ref.watch(activeFoodDataProvider);
    final macroService = ref.watch(macroServiceProvider);

    // Filter by search
    final filteredFoods = predefinedFoods.where((food) {
      final foodData = foodDataMap[food.foodDataId];
      final name = foodData?.name.toLowerCase() ?? '';
      final brand = foodData?.brandName.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || brand.contains(query);
    }).toList();

    // Pre-calculate macros for sorting
    final macrosCache = {
      for (final f in filteredFoods)
        f.id: macroService.calculateMacrosForPredefinedFood(f),
    };

    // Multi-column sort
    final sortedFoods = List.of(filteredFoods);
    if (_portionSortCriteria.isNotEmpty) {
      sortedFoods.sort((a, b) {
        for (final c in _portionSortCriteria) {
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Portion suchen...',
              prefixIcon: const Icon(LucideIcons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
        const SizedBox(height: 6),
        MacroSortBar(
          sortCriteria: _portionSortCriteria,
          onToggle: _togglePortionSort,
          onReset: () => setState(() => _portionSortCriteria.clear()),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: OutlinedButton.icon(
            onPressed: () => setState(() {
              _currentStep = _DialogStep.createPortion;
              _name = _searchQuery;
            }),
            icon: const Icon(LucideIcons.plus),
            label: const Text('Neue Portion anlegen'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: sortedFoods.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: sortedFoods.length,
                  itemBuilder: (context, index) {
                    final food = sortedFoods[index];
                    final foodData = foodDataMap[food.foodDataId];
                    final macros = macrosCache[food.id]!;
                    return _PortionListTile(
                      name: foodData?.name ?? 'Unbekannt',
                      brand: foodData?.brandName,
                      quantity: food.quantity,
                      unit: foodData?.defaultUnit ?? 'g',
                      macros: macros,
                      imagePath: foodData?.imagePath,
                      onAdd: () => _addFoodEntry(
                        foodData?.name ?? 'Unbekannt',
                        food.foodDataId,
                        food.quantity,
                        stayInList: true,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            LucideIcons.searchX,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isEmpty
                ? 'Noch keine Portionen vorhanden'
                : 'Keine Ergebnisse für "$_searchQuery"',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Erstelle eine neue Portion!',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // STEP 2b: Recipe Selection
  // ============================================================================

  Widget _buildRecipeSelection() {
    final recipes = ref.watch(activeRecipesProvider);
    final macroService = ref.watch(macroServiceProvider);

    // Filter by search
    final filteredRecipes = recipes.where((recipe) {
      final name = recipe.name.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query);
    }).toList();

    // Pre-calculate macros for sorting
    final macrosCache = {
      for (final r in filteredRecipes)
        r.id: macroService.calculateMacrosForRecipe(r),
    };

    // Multi-column sort
    final sortedRecipes = List.of(filteredRecipes);
    if (_recipeSortCriteria.isNotEmpty) {
      sortedRecipes.sort((a, b) {
        for (final c in _recipeSortCriteria) {
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Rezept suchen...',
              prefixIcon: const Icon(LucideIcons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
        const SizedBox(height: 6),
        MacroSortBar(
          sortCriteria: _recipeSortCriteria,
          onToggle: _toggleRecipeSort,
          onReset: () => setState(() => _recipeSortCriteria.clear()),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: OutlinedButton.icon(
            onPressed: _createNewRecipe,
            icon: const Icon(LucideIcons.plus),
            label: const Text('Neues Rezept anlegen'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: sortedRecipes.isEmpty
              ? _buildEmptyRecipeState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: sortedRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = sortedRecipes[index];
                    final macros = macrosCache[recipe.id]!;
                    return _RecipeListTile(
                      recipe: recipe,
                      macros: macros,
                      onAdd: () => _promptServingsAndAddRecipe(
                        recipe.name,
                        recipe.id,
                        stayInList: true,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyRecipeState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            LucideIcons.searchX,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isEmpty
                ? 'Noch keine Rezepte vorhanden'
                : 'Keine Ergebnisse für "$_searchQuery"',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Erstelle ein neues Rezept!',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _createNewRecipe() {
    setState(() {
      _currentStep = _DialogStep.createRecipe;
      _recipeName = _searchQuery;
      _recipeIngredients = [];
    });
  }

  // ============================================================================
  // STEP 3: Create Portion Form
  // ============================================================================

  Widget _buildCreatePortionForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.info, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Die Lebensmitteldaten werden gespeichert und als Portion zum Plan hinzugefügt.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Image picker for portion
            GestureDetector(
              onTap: () async {
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                );
                if (picked != null && mounted) {
                  setState(() => _portionImagePath = picked.path);
                }
              },
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  image: _portionImagePath != null
                      ? DecorationImage(
                          image:
                              (_portionImagePath!.startsWith('http://') ||
                                  _portionImagePath!.startsWith('https://'))
                              ? NetworkImage(_portionImagePath!)
                                    as ImageProvider
                              : kIsWeb
                              ? NetworkImage(_portionImagePath!)
                              : FileImage(File(_portionImagePath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _portionImagePath != null
                    ? null
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.camera,
                            color: Colors.grey.shade500,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Foto hinzufügen (optional)',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),

            // Basic info
            const Text(
              'Lebensmittel-Infos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildTextFormField(
              label: 'Name des Lebensmittels',
              controller: _nameCtrl,
              onSave: (val) => _name = val,
            ),
            _buildTextFormField(
              label: 'Marke / Quelle (optional)',
              controller: _brandCtrl,
              onSave: (val) => _brand = val,
              isRequired: false,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Einheit',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              initialValue: _unit,
              items: FoodUnit.displayValues.map((unit) {
                return DropdownMenuItem(
                  value: unit,
                  child: Text(unit),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _unit = value ?? _unit;
                });
              },
              validator: (value) =>
                  value == null ? 'Bitte wählen Sie eine Einheit.' : null,
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Macros
            Text(
              'Nährwerte pro 100 $_unit',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: NutritionScanButton(
                onResult: (nutrients) {
                  if (nutrients.calories != null) {
                    _caloriesCtrl.text = nutrients.calories!.toStringAsFixed(1);
                  }
                  if (nutrients.protein != null) {
                    _proteinCtrl.text = nutrients.protein!.toStringAsFixed(1);
                  }
                  if (nutrients.carbs != null) {
                    _carbsCtrl.text = nutrients.carbs!.toStringAsFixed(1);
                  }
                  if (nutrients.fat != null) {
                    _fatCtrl.text = nutrients.fat!.toStringAsFixed(1);
                  }
                  if (nutrients.name != null && nutrients.name!.isNotEmpty) {
                    _nameCtrl.text = nutrients.name!;
                  }
                  if (nutrients.brand != null && nutrients.brand!.isNotEmpty) {
                    _brandCtrl.text = nutrients.brand!;
                  }
                  if (nutrients.imageUrl != null &&
                      nutrients.imageUrl!.isNotEmpty) {
                    setState(() => _portionImagePath = nutrients.imageUrl);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildNumberFormField(
                    label: 'Kalorien',
                    controller: _caloriesCtrl,
                    onSave: (val) => _calories = val,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNumberFormField(
                    label: 'Protein (g)',
                    controller: _proteinCtrl,
                    onSave: (val) => _protein = val,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildNumberFormField(
                    label: 'Kohlenhydrate (g)',
                    controller: _carbsCtrl,
                    onSave: (val) => _carbs = val,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNumberFormField(
                    label: 'Fett (g)',
                    controller: _fatCtrl,
                    onSave: (val) => _fat = val,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Portion quantity
            const Text(
              'Portionsmenge',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildNumberFormField(
              label: 'Menge in $_unit',
              initialValue: _portionQuantity > 0
                  ? _portionQuantity.toString()
                  : '',
              onSave: (val) => _portionQuantity = val,
              isPositiveRequired: true,
            ),

            const SizedBox(height: 24),

            // Save button
            ElevatedButton.icon(
              onPressed: _saveAndAddPortion,
              icon: const Icon(LucideIcons.check),
              label: const Text('Speichern & hinzufügen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    required Function(String) onSave,
    String? initialValue,
    TextEditingController? controller,
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        initialValue: controller != null ? null : initialValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'Bitte ausfüllen';
          }
          return null;
        },
        onSaved: (value) => onSave(value ?? ''),
      ),
    );
  }

  Widget _buildNumberFormField({
    required String label,
    required Function(double) onSave,
    String? initialValue,
    TextEditingController? controller,
    bool isPositiveRequired = false,
  }) {
    assert(
      controller != null || initialValue != null,
      'Either controller or initialValue must be provided',
    );
    return TextFormField(
      controller: controller,
      initialValue: controller != null ? null : initialValue,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      validator: (value) {
        final parsed = double.tryParse(value ?? '');
        if (parsed == null || parsed < 0) {
          return 'Ungültige Zahl';
        }
        if (isPositiveRequired && parsed <= 0) {
          return 'Muss > 0 sein';
        }
        return null;
      },
      onSaved: (value) => onSave(double.tryParse(value ?? '0') ?? 0),
    );
  }

  void _saveAndAddPortion() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    // 1. Create FoodData
    final macros = MacroNutrients(
      calories: _calories,
      protein: _protein,
      carbs: _carbs,
      fat: _fat,
    );

    final newFoodData = FoodData(
      name: _name,
      brandName: _brand,
      defaultUnit: _unit,
      macrosPer100unit: macros,
      imagePath: _portionImagePath,
    );

    ref.read(foodDataMapProvider.notifier).upsert(newFoodData);

    // 2. Create PredefinedFood (Portion)
    final newPortion = PredefinedFood(
      foodDataId: newFoodData.id,
      quantity: _portionQuantity,
    );

    ref.read(predefinedFoodProvider.notifier).upsert(newPortion);

    // 3. Add as meal entry
    _addFoodEntry(_name, newFoodData.id, _portionQuantity);
  }

  // ============================================================================
  // STEP 4: Create Recipe Form
  // ============================================================================

  Widget _buildCreateRecipeForm() {
    final foodDataMap = ref.watch(activeFoodDataProvider);

    // Calculate current recipe macros
    MacroNutrients recipeMacros = MacroNutrients.zero();
    for (final ingredient in _recipeIngredients) {
      final ingMacros = ingredient.getMacros(foodDataMap);
      recipeMacros = recipeMacros + ingMacros;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Das Rezept wird gespeichert und zum Plan hinzugefügt.',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Image picker for recipe
          GestureDetector(
            onTap: () async {
              final picked = await ImagePicker().pickImage(
                source: ImageSource.gallery,
              );
              if (picked != null && mounted) {
                setState(() => _recipeImagePath = picked.path);
              }
            },
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                image: _recipeImagePath != null
                    ? DecorationImage(
                        image:
                            (_recipeImagePath!.startsWith('http://') ||
                                _recipeImagePath!.startsWith('https://'))
                            ? NetworkImage(_recipeImagePath!) as ImageProvider
                            : kIsWeb
                            ? NetworkImage(_recipeImagePath!)
                            : FileImage(File(_recipeImagePath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _recipeImagePath != null
                  ? null
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.camera,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Foto hinzufügen (optional)',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Recipe name
          TextFormField(
            initialValue: _recipeName,
            decoration: const InputDecoration(
              labelText: 'Rezept Name',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bitte einen Namen eingeben';
              }
              return null;
            },
            onChanged: (value) => _recipeName = value,
          ),

          const SizedBox(height: 16),

          // Macro summary
          if (_recipeIngredients.isNotEmpty)
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${recipeMacros.calories.toStringAsFixed(0)} kcal | '
                    '${recipeMacros.protein.toStringAsFixed(1)}g P | '
                    '${recipeMacros.carbs.toStringAsFixed(1)}g K | '
                    '${recipeMacros.fat.toStringAsFixed(1)}g F',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
          const Divider(),

          // Ingredients section
          Row(
            children: [
              const Text(
                'Zutaten',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showAddIngredientDialog(foodDataMap),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Hinzufügen'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Ingredients list
          if (_recipeIngredients.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Noch keine Zutaten hinzugefügt',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ...List.generate(_recipeIngredients.length, (index) {
              final ing = _recipeIngredients[index];
              final foodData = foodDataMap[ing.foodDataId];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  title: Text(foodData?.name ?? 'Unbekannt'),
                  subtitle: Text(
                    '${ing.quantity.toStringAsFixed(1)} ${foodData?.defaultUnit ?? 'g'}',
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      LucideIcons.trash2,
                      color: Colors.red.shade400,
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() {
                        _recipeIngredients = List.from(_recipeIngredients)
                          ..removeAt(index);
                      });
                    },
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          // Save button
          ElevatedButton.icon(
            onPressed: _recipeIngredients.isEmpty ? null : _saveAndAddRecipe,
            icon: const Icon(LucideIcons.check),
            label: const Text('Speichern & hinzufügen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
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
    final List<MacroSortCriteria> sortCriteria = [];
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

            // Multi-column sort on macrosPer100unit
            final sortedFoodData = List.of(filteredFoodData);
            if (sortCriteria.isNotEmpty) {
              sortedFoodData.sort((a, b) {
                for (final c in sortCriteria) {
                  final aVal = _macroValue(a.macrosPer100unit, c.field);
                  final bVal = _macroValue(b.macrosPer100unit, c.field);
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

                    // Food data list
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
                                        setState(() {
                                          _recipeIngredients = [
                                            ..._recipeIngredients,
                                            RecipeIngredient(
                                              foodDataId: selectedFoodDataId!,
                                              quantity: quantity,
                                            ),
                                          ];
                                        });
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

  void _saveAndAddRecipe() {
    if (_recipeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte einen Rezeptnamen eingeben')),
      );
      return;
    }

    if (_recipeIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte mindestens eine Zutat hinzufügen')),
      );
      return;
    }

    // Create and save Recipe
    final newRecipe = Recipe(
      name: _recipeName,
      ingredients: _recipeIngredients,
      imagePath: _recipeImagePath,
    );

    ref.read(recipeProvider.notifier).upsert(newRecipe);

    // Add as meal entry
    _addRecipeEntry(_recipeName, newRecipe.id);
  }

  // ============================================================================
  // Add Meal Entry Logic
  // ============================================================================

  void _addFoodEntry(
    String name,
    String foodDataId,
    double quantity, {
    bool stayInList = false,
  }) {
    final entry = FoodEntry(
      name: name,
      foodDataId: foodDataId,
      quantity: quantity,
    );
    _addMealEntry(entry, stayInList: stayInList);
  }

  void _addRecipeEntry(
    String name,
    String recipeId, {
    double servings = 1.0,
    bool stayInList = false,
  }) {
    final entry = RecipeEntry(
      name: name,
      recipeId: recipeId,
      servings: servings,
    );
    _addMealEntry(entry, stayInList: stayInList);
  }

  /// Shows a servings picker and then adds the recipe entry.
  void _promptServingsAndAddRecipe(
    String name,
    String recipeId, {
    bool stayInList = false,
  }) {
    double servings = 1.0;
    final ctrl = TextEditingController(text: '1');
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Portionsgröße'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Wie viele Portionen möchtest du von "$name" hinzufügen?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StatefulBuilder(
                  builder: (_, setS) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.minus),
                        onPressed: servings > 0.5
                            ? () => setS(() {
                                servings = double.parse(
                                  (servings - 0.5).toStringAsFixed(1),
                                );
                                ctrl.text = servings.toStringAsFixed(
                                  servings % 1 == 0 ? 0 : 1,
                                );
                              })
                            : null,
                      ),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: ctrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (v) {
                            final parsed = double.tryParse(v);
                            if (parsed != null && parsed > 0) {
                              servings = parsed;
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.plus),
                        onPressed: () => setS(() {
                          servings = double.parse(
                            (servings + 0.5).toStringAsFixed(1),
                          );
                          ctrl.text = servings.toStringAsFixed(
                            servings % 1 == 0 ? 0 : 1,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _addRecipeEntry(
          name,
          recipeId,
          servings: servings,
          stayInList: stayInList,
        );
      }
    });
  }

  void _addMealEntry(MealEntry entry, {bool stayInList = false}) {
    final service = ref.read(nutritionPlanServiceProvider);
    // Always read the CURRENT plan state to avoid stale-data overwrites when
    // adding multiple meals without leaving the list.
    final currentPlan =
        ref.read(nutritionPlanProvider)[widget.plan.id] ?? widget.plan;

    NutritionPlan updatedPlan;
    if (_isRecurring) {
      final rule = _buildRecurrenceRule();
      final template = RecurringMealTemplate(
        mealEntry: entry,
        rule: rule,
        startDate: widget.selectedDate,
      );
      updatedPlan = service.addRecurringMeal(currentPlan, template);
    } else {
      updatedPlan = service.addAdditionalMealToDay(
        currentPlan,
        widget.selectedDate,
        entry,
      );
    }

    ref.read(nutritionPlanProvider.notifier).update(updatedPlan);

    if (!stayInList) {
      Navigator.of(context).pop(true);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${entry.name} hinzugefügt'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  RecurrenceRule _buildRecurrenceRule() {
    switch (_selectedPattern) {
      case RecurrencePattern.daily:
        return RecurrenceRule.daily();
      case RecurrencePattern.weekdays:
        return RecurrenceRule.weekdays();
      case RecurrencePattern.weekends:
        return RecurrenceRule.weekends();
      case RecurrencePattern.specificDaysOfWeek:
        return RecurrenceRule.specificDaysOfWeek(
          _selectedDays.isEmpty ? [DateTime.now().weekday] : _selectedDays,
        );
    }
  }
}

// ============================================================================
// Supporting Widgets
// ============================================================================

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.2),
                radius: 24,
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _PortionListTile extends StatelessWidget {
  final String name;
  final String? brand;
  final double quantity;
  final String unit;
  final MacroNutrients macros;
  final String? imagePath;
  final VoidCallback onAdd;

  const _PortionListTile({
    required this.name,
    this.brand,
    required this.quantity,
    required this.unit,
    required this.macros,
    this.imagePath,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: FoodImageAvatar(
          imagePath: imagePath,
          fallbackIcon: LucideIcons.banana,
          iconColor: Colors.white,
          backgroundColor: Colors.orange,
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              brand != null && brand!.isNotEmpty
                  ? '$brand • ${quantity.toStringAsFixed(0)} $unit'
                  : '${quantity.toStringAsFixed(0)} $unit',
            ),
            Text(
              '${macros.calories.toStringAsFixed(0)} kcal  |  ${macros.protein.toStringAsFixed(1)}g P  |  ${macros.carbs.toStringAsFixed(1)}g K  |  ${macros.fat.toStringAsFixed(1)}g F',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(LucideIcons.plus),
          onPressed: onAdd,
          tooltip: 'Hinzufügen',
        ),
      ),
    );
  }
}

class _RecipeListTile extends StatelessWidget {
  final Recipe recipe;
  final MacroNutrients macros;
  final VoidCallback onAdd;

  const _RecipeListTile({
    required this.recipe,
    required this.macros,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: FoodImageAvatar(
          imagePath: recipe.imagePath,
          fallbackIcon: LucideIcons.cookingPot,
          iconColor: Colors.white,
          backgroundColor: Colors.teal,
        ),
        title: Text(
          recipe.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${recipe.ingredients.length} Zutat(en)'),
            Text(
              '${macros.calories.toStringAsFixed(0)} kcal  |  ${macros.protein.toStringAsFixed(1)}g P  |  ${macros.carbs.toStringAsFixed(1)}g K  |  ${macros.fat.toStringAsFixed(1)}g F',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(LucideIcons.plus),
          onPressed: onAdd,
          tooltip: 'Hinzufügen',
        ),
      ),
    );
  }
}

class _RecurrenceSelector extends StatelessWidget {
  final RecurrencePattern selectedPattern;
  final List<int> selectedDays;
  final ValueChanged<RecurrencePattern> onPatternChanged;
  final ValueChanged<List<int>> onDaysChanged;

  const _RecurrenceSelector({
    required this.selectedPattern,
    required this.selectedDays,
    required this.onPatternChanged,
    required this.onDaysChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Wiederholung:',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _PatternChip(
              label: 'Täglich',
              isSelected: selectedPattern == RecurrencePattern.daily,
              onTap: () => onPatternChanged(RecurrencePattern.daily),
            ),
            _PatternChip(
              label: 'Wochentags',
              isSelected: selectedPattern == RecurrencePattern.weekdays,
              onTap: () => onPatternChanged(RecurrencePattern.weekdays),
            ),
            _PatternChip(
              label: 'Wochenende',
              isSelected: selectedPattern == RecurrencePattern.weekends,
              onTap: () => onPatternChanged(RecurrencePattern.weekends),
            ),
            _PatternChip(
              label: 'Bestimmte Tage',
              isSelected:
                  selectedPattern == RecurrencePattern.specificDaysOfWeek,
              onTap: () =>
                  onPatternChanged(RecurrencePattern.specificDaysOfWeek),
            ),
          ],
        ),
        if (selectedPattern == RecurrencePattern.specificDaysOfWeek) ...[
          const SizedBox(height: 12),
          _DaySelector(
            selectedDays: selectedDays,
            onChanged: onDaysChanged,
          ),
        ],
      ],
    );
  }
}

class _PatternChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PatternChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Colors.teal.shade100,
      checkmarkColor: Colors.teal,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _DaySelector extends StatelessWidget {
  final List<int> selectedDays;
  final ValueChanged<List<int>> onChanged;

  const _DaySelector({
    required this.selectedDays,
    required this.onChanged,
  });

  static const _days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final dayNumber = index + 1;
        final isSelected = selectedDays.contains(dayNumber);
        return GestureDetector(
          onTap: () {
            final newDays = List<int>.from(selectedDays);
            if (isSelected) {
              newDays.remove(dayNumber);
            } else {
              newDays.add(dayNumber);
            }
            onChanged(newDays);
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected ? Colors.teal : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _days[index],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
