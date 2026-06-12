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

class _NutritionPlanDetailContent extends ConsumerStatefulWidget {
  final NutritionPlan plan;

  const _NutritionPlanDetailContent({required this.plan});

  @override
  ConsumerState<_NutritionPlanDetailContent> createState() =>
      _NutritionPlanDetailContentState();
}

class _NutritionPlanDetailContentState
    extends ConsumerState<_NutritionPlanDetailContent> {
  @override
  void initState() {
    super.initState();
    // Clamp the selected date to the plan's date range on first load.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final selectedDate = ref.read(selectedDateProvider);
      final clamped = _clampToRange(selectedDate, widget.plan);
      if (clamped != selectedDate) {
        ref.read(selectedDateProvider.notifier).state = clamped;
      }
    });
  }

  static DateTime _clampToRange(DateTime date, NutritionPlan plan) {
    final planStart = DateTime(
      plan.startDate.year,
      plan.startDate.month,
      plan.startDate.day,
    );
    final d = DateTime(date.year, date.month, date.day);
    if (d.isBefore(planStart)) return planStart;
    if (plan.endDate != null) {
      final planEnd = DateTime(
        plan.endDate!.year,
        plan.endDate!.month,
        plan.endDate!.day,
      );
      if (d.isAfter(planEnd)) return planEnd;
    }
    return date;
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final service = ref.watch(nutritionPlanServiceProvider);
    final plan = widget.plan;

    final meals = service.getMealsForDay(plan, selectedDate);
    final dayMacros = service.calculateMacrosForDay(plan, selectedDate);
    final checkedMacros = service.calculateMacrosForCheckedMeals(
      plan,
      selectedDate,
    );
    final targets = plan.dailyMacroTargets;
    final dateKey = service.dateKey(selectedDate);
    final burnedCalories = plan.dayOverrides[dateKey]?.burnedCalories ?? 0.0;

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
            targets: targets,
            plannedMacros: dayMacros,
            checkedMacros: checkedMacros,
            burnedCalories: burnedCalories,
            selectedDate: selectedDate,
          ),

          // Mahlzeiten-Header mit Hinzufügen-Button
          _MealsHeader(
            onAdd: () => _showAddMealOptions(context, ref, selectedDate),
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
    );
  }

  void _showAddMealOptions(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) {
    showAddMealDialog(
      context: context,
      plan: widget.plan,
      selectedDate: selectedDate,
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

  void _showPlanSettings(BuildContext context, WidgetRef ref) async {
    final updatedPlan = await showEditPlanDialog(context, plan: widget.plan);
    if (updatedPlan != null) {
      ref.read(nutritionPlanProvider.notifier).update(updatedPlan);
    }
  }
}

/// Header-Zeile über der Mahlzeitenliste mit Titel und Hinzufügen-Button.
class _MealsHeader extends StatelessWidget {
  final VoidCallback onAdd;

  const _MealsHeader({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          const Text(
            'Mahlzeiten',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Hinzufügen'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }
}
