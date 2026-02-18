import 'package:eat_beat_repeat/frontend/pages/nutrition_plans/widgets/create_plan_dialog.dart';
import 'package:eat_beat_repeat/logic/models/nutrition_plan.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:eat_beat_repeat/logic/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NutritionPlansPage extends ConsumerWidget {
  const NutritionPlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(activeNutritionPlansProvider);

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/vion/vion_basic.png', height: 50),
            const SizedBox(width: 10),
            const Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ernährungspläne',
                  style: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: plans.isEmpty
          ? _buildEmptyState(context, ref)
          : _buildPlansList(context, ref, plans),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePlanDialog(context, ref),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Neuer Plan'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.calendar,
            size: 80,
            color: Colors.teal.shade200,
          ),
          const SizedBox(height: 20),
          Text(
            'Noch keine Ernährungspläne',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Erstelle deinen ersten Plan!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansList(
    BuildContext context,
    WidgetRef ref,
    List<NutritionPlan> plans,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return NutritionPlanCard(plan: plan);
      },
    );
  }

  Future<void> _showCreatePlanDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await showCreatePlanDialog(context);

    if (result != null) {
      ref.read(nutritionPlanProvider.notifier).add(result);
    }
  }
}

class NutritionPlanCard extends ConsumerWidget {
  final NutritionPlan plan;

  const NutritionPlanCard({super.key, required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(nutritionPlanServiceProvider);

    // Berechne Durchschnitts-Makros für die Anzeige
    final today = DateTime.now();
    final todayMacros = service.calculateMacrosForDay(plan, today);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDetail(context, plan.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateRange(plan),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleMenuAction(context, ref, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(LucideIcons.pencil, size: 18),
                            SizedBox(width: 8),
                            Text('Bearbeiten'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.trash2,
                              size: 18,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Löschen',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Makro-Übersicht (heute)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Heute (${formatDateTime(today)})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMacroChip(
                          'Kcal',
                          todayMacros.calories.toStringAsFixed(0),
                          Colors.orange,
                        ),
                        _buildMacroChip(
                          'Protein',
                          '${todayMacros.protein.toStringAsFixed(1)}g',
                          Colors.red,
                        ),
                        _buildMacroChip(
                          'Carbs',
                          '${todayMacros.carbs.toStringAsFixed(1)}g',
                          Colors.blue,
                        ),
                        _buildMacroChip(
                          'Fett',
                          '${todayMacros.fat.toStringAsFixed(1)}g',
                          Colors.amber,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Info-Zeile
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    LucideIcons.repeat,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${plan.recurringMeals.length} wiederkehrende Mahlzeiten',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _formatDateRange(NutritionPlan plan) {
    final start = formatDateTime(plan.startDate);
    if (plan.endDate != null) {
      return '$start - ${formatDateTime(plan.endDate!)}';
    }
    return 'Ab $start';
  }

  void _navigateToDetail(BuildContext context, String planId) {
    Navigator.of(context).pushNamed('nutritionPlanDetail', arguments: planId);
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    if (action == 'delete') {
      _confirmDelete(context, ref);
    }
    // TODO: edit action
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Plan löschen?'),
        content: Text('Möchtest du "${plan.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              ref.read(nutritionPlanProvider.notifier).remove(plan.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
