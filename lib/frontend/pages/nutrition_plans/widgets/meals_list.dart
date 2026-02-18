import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:eat_beat_repeat/logic/models/meal_entry.dart';
import 'package:eat_beat_repeat/logic/models/nutrition_plan.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:eat_beat_repeat/logic/services/nutrition_plan_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Liste der Mahlzeiten für einen Tag.
class MealsList extends ConsumerWidget {
  final List<MealEntry> meals;
  final NutritionPlan plan;
  final DateTime selectedDate;
  final NutritionPlanService service;

  const MealsList({
    super.key,
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
        return MealCard(
          meal: meal,
          macros: macros,
          plan: plan,
          selectedDate: selectedDate,
        );
      },
    );
  }
}

/// Card-Widget für eine einzelne Mahlzeit.
class MealCard extends ConsumerWidget {
  final MealEntry meal;
  final MacroNutrients macros;
  final NutritionPlan plan;
  final DateTime selectedDate;

  const MealCard({
    super.key,
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
    final service = ref.read(nutritionPlanServiceProvider);
    final updatedPlan = service.hideMealForDay(plan, selectedDate, meal.id);

    ref.read(nutritionPlanProvider.notifier).update(updatedPlan);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${meal.name} für heute ausgeblendet')),
    );
  }

  void _removeMealFromPlan(BuildContext context, WidgetRef ref) {
    final service = ref.read(nutritionPlanServiceProvider);
    final result = service.removeMealFromPlan(plan, selectedDate, meal.id);

    if (result != null) {
      ref.read(nutritionPlanProvider.notifier).update(result.plan);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${meal.name} entfernt')),
    );
  }
}
