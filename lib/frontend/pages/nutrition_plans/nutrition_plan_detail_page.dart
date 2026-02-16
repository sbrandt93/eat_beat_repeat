import 'package:eat_beat_repeat/logic/models/day_override.dart';
import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:eat_beat_repeat/logic/models/meal_entry.dart';
import 'package:eat_beat_repeat/logic/models/nutrition_plan.dart';
import 'package:eat_beat_repeat/logic/models/recurrence_rule.dart';
import 'package:eat_beat_repeat/logic/models/recurring_meal_template.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:eat_beat_repeat/logic/services/nutrition_plan_service.dart';
import 'package:eat_beat_repeat/logic/utils/enums.dart';
import 'package:eat_beat_repeat/logic/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Provider für den ausgewählten Tag
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

class NutritionPlanDetailPage extends ConsumerWidget {
  final String planId;

  const NutritionPlanDetailPage({super.key, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansMap = ref.watch(nutritionPlanProvider);
    final plan = plansMap[planId];

    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Plan nicht gefunden')),
        body: const Center(child: Text('Dieser Plan existiert nicht mehr.')),
      );
    }

    return _NutritionPlanDetailContent(plan: plan);
  }
}

class _NutritionPlanDetailContent extends ConsumerWidget {
  final NutritionPlan plan;

  const _NutritionPlanDetailContent({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final service = ref.watch(nutritionPlanServiceProvider);

    final meals = service.getMealsForDay(plan, selectedDate);
    final dayMacros = service.calculateMacrosForDay(plan, selectedDate);
    final targets = plan.dailyMacroTargets;

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: Text(plan.name),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => _showPlanSettings(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Datums-Navigation
          _DateNavigator(
            selectedDate: selectedDate,
            plan: plan,
          ),

          // Makro-Zusammenfassung
          _MacroSummaryCard(
            dayMacros: dayMacros,
            targets: targets,
          ),

          // Mahlzeiten-Liste
          Expanded(
            child: meals.isEmpty
                ? _buildEmptyMealsState()
                : _MealsList(
                    meals: meals,
                    plan: plan,
                    selectedDate: selectedDate,
                    service: service,
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMealOptions(context, ref, selectedDate),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Mahlzeit'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyMealsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.utensils, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Keine Mahlzeiten für diesen Tag',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Füge eine neue Mahlzeit hinzu!',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  void _showPlanSettings(BuildContext context, WidgetRef ref) {
    // TODO: Implement plan settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Einstellungen - coming soon!')),
    );
  }

  void _showAddMealOptions(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _AddMealBottomSheet(
        plan: plan,
        selectedDate: selectedDate,
      ),
    );
  }
}

// ============================================================================
// DATE NAVIGATOR
// ============================================================================

class _DateNavigator extends ConsumerWidget {
  final DateTime selectedDate;
  final NutritionPlan plan;

  const _DateNavigator({
    required this.selectedDate,
    required this.plan,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Navigation Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.chevronLeft),
                onPressed: () => _changeDate(ref, -1),
              ),
              GestureDetector(
                onTap: () => _selectDate(context, ref),
                child: Column(
                  children: [
                    Text(
                      _getWeekdayName(selectedDate),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      formatDateTime(selectedDate),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.chevronRight),
                onPressed: () => _changeDate(ref, 1),
              ),
            ],
          ),

          // Quick-Navigation Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _QuickDateButton(
                  label: 'Heute',
                  isSelected: _isToday(selectedDate),
                  onTap: () => ref.read(selectedDateProvider.notifier).state =
                      DateTime.now(),
                ),
                const SizedBox(width: 8),
                _QuickDateButton(
                  label: 'Morgen',
                  isSelected: _isTomorrow(selectedDate),
                  onTap: () => ref.read(selectedDateProvider.notifier).state =
                      DateTime.now().add(const Duration(days: 1)),
                ),
                const SizedBox(width: 8),
                _QuickDateButton(
                  label: 'Diese Woche',
                  isSelected: false,
                  onTap: () => _showWeekPicker(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _changeDate(WidgetRef ref, int days) {
    ref.read(selectedDateProvider.notifier).state = selectedDate.add(
      Duration(days: days),
    );
  }

  Future<void> _selectDate(BuildContext context, WidgetRef ref) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: plan.startDate,
      lastDate: plan.endDate ?? DateTime(2030),
    );
    if (picked != null) {
      ref.read(selectedDateProvider.notifier).state = picked;
    }
  }

  void _showWeekPicker(BuildContext context, WidgetRef ref) {
    // TODO: Implement week view
  }

  String _getWeekdayName(DateTime date) {
    const weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return weekdays[date.weekday - 1];
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }
}

class _QuickDateButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickDateButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected ? Colors.teal : Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onPressed: onTap,
    );
  }
}

// ============================================================================
// MACRO SUMMARY CARD
// ============================================================================

class _MacroSummaryCard extends StatelessWidget {
  final MacroNutrients dayMacros;
  final MacroNutrients targets;

  const _MacroSummaryCard({
    required this.dayMacros,
    required this.targets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Kalorien-Anzeige (groß)
          _CalorieDisplay(
            current: dayMacros.calories,
            target: targets.calories,
          ),
          const SizedBox(height: 16),

          // Makro-Balken
          Row(
            children: [
              Expanded(
                child: _MacroProgressBar(
                  label: 'Protein',
                  current: dayMacros.protein,
                  target: targets.protein,
                  color: Colors.red.shade400,
                  unit: 'g',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MacroProgressBar(
                  label: 'Carbs',
                  current: dayMacros.carbs,
                  target: targets.carbs,
                  color: Colors.blue.shade400,
                  unit: 'g',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MacroProgressBar(
                  label: 'Fett',
                  current: dayMacros.fat,
                  target: targets.fat,
                  color: Colors.amber.shade600,
                  unit: 'g',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalorieDisplay extends StatelessWidget {
  final double current;
  final double target;

  const _CalorieDisplay({required this.current, required this.target});

  @override
  Widget build(BuildContext context) {
    final percentage = target > 0 ? (current / target).clamp(0.0, 1.5) : 0.0;
    final remaining = target - current;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              current.toStringAsFixed(0),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '/ ${target.toStringAsFixed(0)} kcal',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage.toDouble(),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(
              percentage > 1 ? Colors.orange : Colors.teal,
            ),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          remaining > 0
              ? '${remaining.toStringAsFixed(0)} kcal übrig'
              : '${(-remaining).toStringAsFixed(0)} kcal über Ziel',
          style: TextStyle(
            fontSize: 12,
            color: remaining > 0 ? Colors.grey.shade600 : Colors.orange,
          ),
        ),
      ],
    );
  }
}

class _MacroProgressBar extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;
  final String unit;

  const _MacroProgressBar({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          '${current.toStringAsFixed(1)}$unit',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: percentage.toDouble(),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '/ ${target.toStringAsFixed(0)}$unit',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

// ============================================================================
// MEALS LIST
// ============================================================================

class _MealsList extends ConsumerWidget {
  final List<MealEntry> meals;
  final NutritionPlan plan;
  final DateTime selectedDate;
  final NutritionPlanService service;

  const _MealsList({
    required this.meals,
    required this.plan,
    required this.selectedDate,
    required this.service,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];
        final macros = service.calculateMacrosForMealEntry(meal);
        return _MealCard(
          meal: meal,
          macros: macros,
          plan: plan,
          selectedDate: selectedDate,
        );
      },
    );
  }
}

class _MealCard extends ConsumerWidget {
  final MealEntry meal;
  final MacroNutrients macros;
  final NutritionPlan plan;
  final DateTime selectedDate;

  const _MealCard({
    required this.meal,
    required this.macros,
    required this.plan,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFood = meal is FoodEntry;
    final icon = isFood ? LucideIcons.banana : LucideIcons.cookingPot;
    final subtitle = isFood
        ? '${(meal as FoodEntry).quantity.toStringAsFixed(0)}g'
        : '${(meal as RecipeEntry).servings} Portion(en)';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade100,
          child: Icon(icon, color: Colors.teal),
        ),
        title: Text(
          meal.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(subtitle),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${macros.calories.toStringAsFixed(0)} kcal',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            Text(
              'P: ${macros.protein.toStringAsFixed(0)}g',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        onTap: () => _showMealOptions(context, ref),
      ),
    );
  }

  void _showMealOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.eyeOff),
              title: const Text('Für heute ausblenden'),
              onTap: () {
                _hideMealForDay(context, ref);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: Colors.red),
              title: const Text(
                'Aus Plan entfernen',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                // TODO: Remove from recurring meals
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _hideMealForDay(BuildContext context, WidgetRef ref) {
    // Find the template ID for this meal
    final template = plan.recurringMeals.firstWhere(
      (t) => t.mealEntry.id == meal.id,
      orElse: () => plan.recurringMeals.first,
    );

    final service = ref.read(nutritionPlanServiceProvider);
    final dateKey = service.dateKey(selectedDate);

    final existingOverride = plan.dayOverrides[dateKey];
    final hiddenIds = [
      ...?existingOverride?.hiddenRecurringMealTemplateIds,
      template.id,
    ];

    final newOverride = DayOverride(
      dateKey: dateKey,
      hiddenRecurringMealTemplateIds: hiddenIds,
      additionalMeals: existingOverride?.additionalMeals ?? [],
    );

    final updatedPlan = plan.copyWith(
      dayOverrides: {...plan.dayOverrides, dateKey: newOverride},
    );

    ref.read(nutritionPlanProvider.notifier).update(updatedPlan);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${meal.name} für heute ausgeblendet')),
    );
  }
}

// ============================================================================
// ADD MEAL BOTTOM SHEET
// ============================================================================

class _AddMealBottomSheet extends ConsumerStatefulWidget {
  final NutritionPlan plan;
  final DateTime selectedDate;

  const _AddMealBottomSheet({
    required this.plan,
    required this.selectedDate,
  });

  @override
  ConsumerState<_AddMealBottomSheet> createState() =>
      _AddMealBottomSheetState();
}

class _AddMealBottomSheetState extends ConsumerState<_AddMealBottomSheet> {
  bool _isRecurring = true;
  RecurrencePattern _selectedPattern = RecurrencePattern.daily;
  final List<int> _selectedDays = [];

  @override
  Widget build(BuildContext context) {
    final predefinedFoods = ref.watch(activePredefinedFoodsProvider);
    final recipes = ref.watch(activeRecipesProvider);
    final foodDataMap = ref.watch(activeFoodDataProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Mahlzeit hinzufügen',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // Recurring Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
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
                ),
              ),

              // Recurrence Pattern (if recurring)
              if (_isRecurring) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _RecurrenceSelector(
                    selectedPattern: _selectedPattern,
                    selectedDays: _selectedDays,
                    onPatternChanged: (p) =>
                        setState(() => _selectedPattern = p),
                    onDaysChanged: (days) => setState(
                      () => _selectedDays
                        ..clear()
                        ..addAll(days),
                    ),
                  ),
                ),
              ],

              const Divider(height: 24),

              // Food/Recipe List
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: Colors.teal,
                        unselectedLabelColor: Colors.grey,
                        tabs: [
                          Tab(text: 'Portionen'),
                          Tab(text: 'Rezepte'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Predefined Foods
                            ListView.builder(
                              controller: scrollController,
                              itemCount: predefinedFoods.length,
                              itemBuilder: (context, index) {
                                final food = predefinedFoods[index];
                                final foodData = foodDataMap[food.foodDataId];
                                final foodName = foodData?.name ?? 'Unbekannt';
                                return ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.orange,
                                    child: Icon(
                                      LucideIcons.banana,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(foodName),
                                  subtitle: Text('${food.quantity}g'),
                                  onTap: () => _addFoodEntry(
                                    foodName,
                                    food.foodDataId,
                                    food.quantity,
                                  ),
                                );
                              },
                            ),

                            // Recipes
                            ListView.builder(
                              controller: scrollController,
                              itemCount: recipes.length,
                              itemBuilder: (context, index) {
                                final recipe = recipes[index];
                                return ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.teal,
                                    child: Icon(
                                      LucideIcons.cookingPot,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(recipe.name),
                                  subtitle: Text(
                                    '${recipe.ingredients.length} Zutaten',
                                  ),
                                  onTap: () =>
                                      _addRecipeEntry(recipe.name, recipe.id),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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

    Navigator.pop(context);
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
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
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

        // Day selector for specific days
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
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Colors.teal.shade100,
      checkmarkColor: Colors.teal,
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected ? Colors.teal : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _days[index],
                style: TextStyle(
                  fontSize: 12,
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
