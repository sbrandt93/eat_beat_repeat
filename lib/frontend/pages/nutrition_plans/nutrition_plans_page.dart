import 'package:eat_beat_repeat/frontend/pages/nutrition_plans/widgets/create_plan_dialog.dart';
import 'package:eat_beat_repeat/frontend/pages/nutrition_plans/widgets/edit_plan_dialog.dart';
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
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
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
    final targets = plan.dailyMacroTargets;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToDetail(context, plan.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Teal-Akzent-Streifen ────────────────────────────────────
            Container(
              height: 5,
              decoration: const BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),

            // ── Header: Name + Datum + Menu ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2332),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              size: 13,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDateRange(plan),
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
            ),

            // ── Abschnitt-Label "Tägliche Ziele" ────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Text(
                    'TÄGLICHE ZIELE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.teal.shade600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Divider(
                      height: 1,
                      color: Colors.teal.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),

            // ── Makro-Chips ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: Row(
                children: [
                  _buildMacroChip(
                    'kcal',
                    targets.calories.toStringAsFixed(0),
                    Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _buildMacroChip(
                    'Protein',
                    '${targets.protein.toStringAsFixed(0)}g',
                    Colors.red.shade400,
                  ),
                  const SizedBox(width: 8),
                  _buildMacroChip(
                    'Carbs',
                    '${targets.carbs.toStringAsFixed(0)}g',
                    Colors.blue.shade400,
                  ),
                  const SizedBox(width: 8),
                  _buildMacroChip(
                    'Fat',
                    '${targets.fat.toStringAsFixed(0)}g',
                    Colors.amber.shade600,
                  ),
                ],
              ),
            ),

            // ── Footer ─────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.repeat,
                    size: 13,
                    color: Colors.teal.withOpacity(0.6),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${plan.recurringMeals.length} Mahlzeit${plan.recurringMeals.length == 1 ? '' : 'en'} geplant',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const Spacer(),
                  Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.teal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(LucideIcons.chevronRight, size: 14, color: Colors.teal),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.75),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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
    } else if (action == 'edit') {
      _editPlan(context, ref);
    }
  }

  Future<void> _editPlan(BuildContext context, WidgetRef ref) async {
    final updatedPlan = await showEditPlanDialog(context, plan: plan);
    if (updatedPlan != null) {
      ref.read(nutritionPlanProvider.notifier).update(updatedPlan);
    }
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
