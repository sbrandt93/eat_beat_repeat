import 'package:eat_beat_repeat/frontend/pages/nutrition_plans/add_meal_dialog.dart';
import 'package:eat_beat_repeat/frontend/pages/nutrition_plans/widgets/widgets.dart';
import 'package:eat_beat_repeat/logic/models/nutrition_plan.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
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
          DateNavigator(
            selectedDate: selectedDate,
            plan: plan,
          ),

          // Makro-Zusammenfassung
          MacroSummaryCard(
            dayMacros: dayMacros,
            targets: targets,
          ),

          // Mahlzeiten-Liste
          Expanded(
            child: meals.isEmpty
                ? _buildEmptyMealsState()
                : MealsList(
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
