import 'package:eat_beat_repeat/logic/models/day_override.dart';
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

  // Create recipe form
  final _recipeFormKey = GlobalKey<FormState>();
  String _recipeName = '';
  List<RecipeIngredient> _recipeIngredients = [];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 500,
        height: screenHeight * 0.9,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: screenHeight * 0.9,
        ),
        child: Column(
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
        return _buildCreatePortionForm();
      case _DialogStep.createRecipe:
        return _buildCreateRecipeForm();
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
    return Padding(
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

    // Filter by search
    final filteredFoods = predefinedFoods.where((food) {
      final foodData = foodDataMap[food.foodDataId];
      final name = foodData?.name.toLowerCase() ?? '';
      final brand = foodData?.brandName.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || brand.contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search field
          TextField(
            decoration: InputDecoration(
              hintText: 'Portion suchen...',
              prefixIcon: const Icon(LucideIcons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),

          // Create new button
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _currentStep = _DialogStep.createPortion;
              // Pre-fill name from search query
              _name = _searchQuery;
            }),
            icon: const Icon(LucideIcons.plus),
            label: const Text('Neue Portion anlegen'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // List
          if (filteredFoods.isEmpty)
            _buildEmptyState()
          else
            ...filteredFoods.map((food) {
              final foodData = foodDataMap[food.foodDataId];
              final foodName = foodData?.name ?? 'Unbekannt';
              final brandName = foodData?.brandName;
              return _PortionListTile(
                name: foodName,
                brand: brandName,
                quantity: food.quantity,
                unit: foodData?.defaultUnit ?? 'g',
                onTap: () => _addFoodEntry(
                  foodName,
                  food.foodDataId,
                  food.quantity,
                ),
              );
            }),
        ],
      ),
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

    // Filter by search
    final filteredRecipes = recipes.where((recipe) {
      final name = recipe.name.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search field
          TextField(
            decoration: InputDecoration(
              hintText: 'Rezept suchen...',
              prefixIcon: const Icon(LucideIcons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),

          // Create new button (navigates to recipe detail screen)
          OutlinedButton.icon(
            onPressed: _createNewRecipe,
            icon: const Icon(LucideIcons.plus),
            label: const Text('Neues Rezept anlegen'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // List
          if (filteredRecipes.isEmpty)
            _buildEmptyRecipeState()
          else
            ...filteredRecipes.map(
              (recipe) => _RecipeListTile(
                recipe: recipe,
                onTap: () => _addRecipeEntry(recipe.name, recipe.id),
              ),
            ),
        ],
      ),
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

            // Basic info
            const Text(
              'Lebensmittel-Infos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildTextFormField(
              label: 'Name des Lebensmittels',
              initialValue: _name,
              onSave: (val) => _name = val,
            ),
            _buildTextFormField(
              label: 'Marke / Quelle (optional)',
              initialValue: _brand,
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
              value: _unit,
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
            Row(
              children: [
                Expanded(
                  child: _buildNumberFormField(
                    label: 'Kalorien',
                    initialValue: _calories > 0 ? _calories.toString() : '',
                    onSave: (val) => _calories = val,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNumberFormField(
                    label: 'Protein (g)',
                    initialValue: _protein > 0 ? _protein.toString() : '',
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
                    initialValue: _carbs > 0 ? _carbs.toString() : '',
                    onSave: (val) => _carbs = val,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNumberFormField(
                    label: 'Fett (g)',
                    initialValue: _fat > 0 ? _fat.toString() : '',
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
    required String initialValue,
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        initialValue: initialValue,
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
    required String initialValue,
    required Function(double) onSave,
    bool isPositiveRequired = false,
  }) {
    return TextFormField(
      initialValue: initialValue,
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
    final macroService = ref.read(macroServiceProvider);

    // Calculate current recipe macros
    MacroNutrients recipeMacros = MacroNutrients.zero();
    for (final ingredient in _recipeIngredients) {
      final foodData = foodDataMap[ingredient.foodDataId];
      if (foodData != null) {
        final ingredientMacros = ingredient.getMacros(foodDataMap);
        recipeMacros = recipeMacros + ingredientMacros;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _recipeFormKey,
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
    );

    ref.read(recipeProvider.notifier).upsert(newRecipe);

    // Add as meal entry
    _addRecipeEntry(_recipeName, newRecipe.id);
  }

  // ============================================================================
  // Add Meal Entry Logic
  // ============================================================================

  void _addFoodEntry(String name, String foodDataId, double quantity) {
    final entry = FoodEntry(
      name: name,
      foodDataId: foodDataId,
      quantity: quantity,
    );
    _addMealEntry(entry);
  }

  void _addRecipeEntry(String name, String recipeId) {
    final entry = RecipeEntry(
      name: name,
      recipeId: recipeId,
      servings: 1,
    );
    _addMealEntry(entry);
  }

  void _addMealEntry(MealEntry entry) {
    final service = ref.read(nutritionPlanServiceProvider);

    if (_isRecurring) {
      // Add as recurring meal
      final rule = _buildRecurrenceRule();
      final template = RecurringMealTemplate(
        mealEntry: entry,
        rule: rule,
      );

      final updatedPlan = widget.plan.copyWith(
        recurringMeals: [...widget.plan.recurringMeals, template],
      );

      ref.read(nutritionPlanProvider.notifier).update(updatedPlan);
    } else {
      // Add as day-specific meal
      final dateKey = service.dateKey(widget.selectedDate);
      final existingOverride = widget.plan.dayOverrides[dateKey];

      final newOverride = DayOverride(
        dateKey: dateKey,
        hiddenRecurringMealTemplateIds:
            existingOverride?.hiddenRecurringMealTemplateIds ?? [],
        additionalMeals: [
          ...?existingOverride?.additionalMeals,
          entry,
        ],
      );

      final updatedPlan = widget.plan.copyWith(
        dayOverrides: {...widget.plan.dayOverrides, dateKey: newOverride},
      );

      ref.read(nutritionPlanProvider.notifier).update(updatedPlan);
    }

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${entry.name} hinzugefügt')),
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
  final VoidCallback onTap;

  const _PortionListTile({
    required this.name,
    this.brand,
    required this.quantity,
    required this.unit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(LucideIcons.banana, color: Colors.white, size: 20),
        ),
        title: Text(name),
        subtitle: Text(
          brand != null && brand!.isNotEmpty
              ? '$brand • ${quantity.toStringAsFixed(0)} $unit'
              : '${quantity.toStringAsFixed(0)} $unit',
        ),
        trailing: const Icon(LucideIcons.plus),
        onTap: onTap,
      ),
    );
  }
}

class _RecipeListTile extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const _RecipeListTile({
    required this.recipe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.teal,
          child: Icon(LucideIcons.cookingPot, color: Colors.white, size: 20),
        ),
        title: Text(recipe.name),
        subtitle: Text('${recipe.ingredients.length} Zutaten'),
        trailing: const Icon(LucideIcons.plus),
        onTap: onTap,
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
