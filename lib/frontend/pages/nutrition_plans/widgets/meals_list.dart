import 'package:eat_beat_repeat/frontend/pages/nutrition_plans/widgets/meal_detail_dialog.dart';
import 'package:eat_beat_repeat/frontend/pages/shared/food_image_avatar.dart';
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
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];
        final macros = service.calculateMacrosForMealEntry(meal);
        // Determine whether this meal comes from a RecurringMealTemplate.
        final isRecurring = plan.recurringMeals.any(
          (t) => t.mealEntry.id == meal.id,
        );
        return MealCard(
          meal: meal,
          macros: macros,
          plan: plan,
          selectedDate: selectedDate,
          isRecurring: isRecurring,
        );
      },
    );
  }
}

/// Card-Widget für eine einzelne Mahlzeit.
///
/// Tap-Bereiche:
///   • [_EatenCheckButton]  → schaltet "gegessen" um
///   • Rest der Card        → öffnet Options-Sheet
class MealCard extends ConsumerWidget {
  final MealEntry meal;
  final MacroNutrients macros;
  final NutritionPlan plan;
  final DateTime selectedDate;

  /// True if this meal comes from a RecurringMealTemplate.
  final bool isRecurring;

  const MealCard({
    super.key,
    required this.meal,
    required this.macros,
    required this.plan,
    required this.selectedDate,
    required this.isRecurring,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFood = meal is FoodEntry;
    final icon = isFood ? LucideIcons.banana : LucideIcons.cookingPot;
    final subtitle = isFood
        ? '${(meal as FoodEntry).quantity.toStringAsFixed(0)}g'
        : '${(meal as RecipeEntry).servings} Portion(en)';

    // Look up image
    String? imagePath;
    if (isFood) {
      final foodDataMap = ref.watch(activeFoodDataProvider);
      imagePath = foodDataMap[(meal as FoodEntry).foodDataId]?.imagePath;
    } else {
      final recipes = ref.watch(activeRecipesProvider);
      for (final r in recipes) {
        if (r.id == (meal as RecipeEntry).recipeId) {
          imagePath = r.imagePath;
          break;
        }
      }
    }

    final key = _dateKey(selectedDate);
    final isChecked = (plan.dayOverrides[key]?.checkedMealIds ?? []).contains(
      meal.id,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: InkWell(
        onTap: () => _showMealOptions(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _EatenCheckButton(
                isChecked: isChecked,
                onTap: () => _toggleChecked(ref),
              ),
              const SizedBox(width: 10),
              FoodImageAvatar(
                imagePath: imagePath,
                fallbackIcon: icon,
                iconColor: isFood ? Colors.orange : Colors.teal,
                backgroundColor: isFood
                    ? Colors.orange.shade50
                    : Colors.teal.shade50,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${macros.calories.toStringAsFixed(0)} kcal',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                            children: [
                              const TextSpan(
                                text: 'P ',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              TextSpan(
                                text: '${macros.protein.toStringAsFixed(0)}g',
                              ),
                              const TextSpan(text: '  '),
                              const TextSpan(
                                text: 'C ',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              TextSpan(
                                text: '${macros.carbs.toStringAsFixed(0)}g',
                              ),
                              const TextSpan(text: '  '),
                              const TextSpan(
                                text: 'F ',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              TextSpan(
                                text: '${macros.fat.toStringAsFixed(0)}g',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Aktionen ──────────────────────────────────────────────────────────────

  void _toggleChecked(WidgetRef ref) {
    final service = ref.read(nutritionPlanServiceProvider);
    final updatedPlan = service.toggleMealChecked(plan, selectedDate, meal.id);
    ref.read(nutritionPlanProvider.notifier).update(updatedPlan);
  }

  void _showMealOptions(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => MealDetailDialog(
        meal: meal,
        macros: macros,
        plan: plan,
        selectedDate: selectedDate,
        isRecurring: isRecurring,
        onHideForToday: () => _hideMealForDay(context, ref),
        onRemoveFromPlan: () => _removeMealFromPlan(context, ref),
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

/// Runder Abhak-Button.
///
/// Nicht abgehakt: grauer Rand + graues Check-Icon  → "noch offen"
/// Abgehakt:       teal-Füllung + weißes Check-Icon → "erledigt"
class _EatenCheckButton extends StatelessWidget {
  final bool isChecked;
  final VoidCallback onTap;

  const _EatenCheckButton({required this.isChecked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isChecked
          ? 'Als nicht gegessen markieren'
          : 'Als gegessen markieren',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isChecked ? Colors.teal : Colors.white,
            border: Border.all(
              color: isChecked ? Colors.teal : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              LucideIcons.check,
              color: isChecked ? Colors.white : Colors.grey.shade400,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
