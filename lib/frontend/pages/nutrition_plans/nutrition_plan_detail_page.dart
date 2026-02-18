import 'package:eat_beat_repeat/frontend/pages/nutrition_plans/add_meal_dialog.dart';
import 'package:eat_beat_repeat/logic/models/day_override.dart';
import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:eat_beat_repeat/logic/models/meal_entry.dart';
import 'package:eat_beat_repeat/logic/models/nutrition_plan.dart';
import 'package:eat_beat_repeat/logic/models/recurring_meal_template.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:eat_beat_repeat/logic/services/nutrition_plan_service.dart';
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
    showAddMealDialog(
      context: context,
      plan: plan,
      selectedDate: selectedDate,
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
    // Ensure initialDate is within valid range
    final firstDate = plan.startDate.isBefore(DateTime(2020))
        ? DateTime(2020)
        : plan.startDate;
    final lastDate = plan.endDate ?? DateTime(2030);
    DateTime initialDate = selectedDate;
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    }
    if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
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
                _removeMealFromPlan(context, ref);
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

  void _removeMealFromPlan(BuildContext context, WidgetRef ref) {
    // Find the template with this meal entry
    final templateIndex = plan.recurringMeals.indexWhere(
      (t) => t.mealEntry.id == meal.id,
    );

    if (templateIndex == -1) {
      // Meal not found in recurring meals, might be additional meal
      // Check in day overrides
      final service = ref.read(nutritionPlanServiceProvider);
      final dateKey = service.dateKey(selectedDate);
      final existingOverride = plan.dayOverrides[dateKey];

      if (existingOverride != null) {
        final updatedAdditionalMeals = existingOverride.additionalMeals
            .where((m) => m.id != meal.id)
            .toList();

        final newOverride = existingOverride.copyWith(
          additionalMeals: updatedAdditionalMeals,
        );

        final updatedPlan = plan.copyWith(
          dayOverrides: {...plan.dayOverrides, dateKey: newOverride},
        );

        ref.read(nutritionPlanProvider.notifier).update(updatedPlan);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${meal.name} entfernt')),
      );
      return;
    }

    // Remove from recurring meals
    final updatedRecurringMeals = List<RecurringMealTemplate>.from(
      plan.recurringMeals,
    )..removeAt(templateIndex);

    final updatedPlan = plan.copyWith(
      recurringMeals: updatedRecurringMeals,
    );

    ref.read(nutritionPlanProvider.notifier).update(updatedPlan);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${meal.name} aus Plan entfernt')),
    );
  }
}
