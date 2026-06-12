import 'package:eat_beat_repeat/frontend/pages/shared/food_image_avatar.dart';
import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:eat_beat_repeat/logic/models/meal_entry.dart';
import 'package:eat_beat_repeat/logic/models/nutrition_plan.dart';
import 'package:eat_beat_repeat/logic/models/recipe.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Dialog that shows full details of a single meal and provides actions.
///
/// Shows image/icon, name, brand (food) or portion count (recipe), macros,
/// and for recipes an expandable ingredient list.
/// Action buttons: "Für heute ausblenden" (recurring only), "Aus Plan entfernen".
class MealDetailDialog extends ConsumerStatefulWidget {
  final MealEntry meal;
  final MacroNutrients macros;
  final NutritionPlan plan;
  final DateTime selectedDate;

  /// True if this meal comes from a RecurringMealTemplate (not an additional meal).
  final bool isRecurring;

  /// Called (after dialog is closed) to hide the meal for today.
  final VoidCallback onHideForToday;

  /// Called (after dialog is closed) to remove the meal from the plan.
  final VoidCallback onRemoveFromPlan;

  const MealDetailDialog({
    super.key,
    required this.meal,
    required this.macros,
    required this.plan,
    required this.selectedDate,
    required this.isRecurring,
    required this.onHideForToday,
    required this.onRemoveFromPlan,
  });

  @override
  ConsumerState<MealDetailDialog> createState() => _MealDetailDialogState();
}

class _MealDetailDialogState extends ConsumerState<MealDetailDialog> {
  bool _showIngredients = false;

  @override
  Widget build(BuildContext context) {
    final isFood = widget.meal is FoodEntry;
    final foodDataMap = ref.watch(activeFoodDataProvider);
    final recipeMap = ref.watch(recipeProvider);

    // Resolve data based on meal type
    String? imagePath;
    String? brand;
    String subtitle;
    Recipe? recipe;

    if (isFood) {
      final entry = widget.meal as FoodEntry;
      final foodData = foodDataMap[entry.foodDataId];
      imagePath = foodData?.imagePath;
      brand = foodData?.brandName.isNotEmpty == true
          ? foodData!.brandName
          : null;
      final unit = foodData?.defaultUnit ?? 'g';
      subtitle = '${entry.quantity.toStringAsFixed(0)} $unit';
    } else {
      final entry = widget.meal as RecipeEntry;
      recipe = recipeMap[entry.recipeId];
      imagePath = recipe?.imagePath;
      final portionStr = entry.servings == entry.servings.roundToDouble()
          ? entry.servings.toStringAsFixed(0)
          : entry.servings.toStringAsFixed(1);
      subtitle = '$portionStr Portion(en)';
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FoodImageAvatar(
                    imagePath: imagePath,
                    fallbackIcon: isFood
                        ? LucideIcons.banana
                        : LucideIcons.cookingPot,
                    iconColor: isFood ? Colors.orange : Colors.teal,
                    backgroundColor: isFood
                        ? Colors.orange.shade50
                        : Colors.teal.shade50,
                    radius: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.meal.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (brand != null)
                          Text(
                            brand,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
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
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Schließen',
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Makros ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  _MacroBox(
                    label: 'kcal',
                    value: widget.macros.calories.toStringAsFixed(0),
                    color: Colors.teal,
                    isBold: true,
                  ),
                  const SizedBox(width: 8),
                  _MacroBox(
                    label: 'Protein',
                    value: '${widget.macros.protein.toStringAsFixed(1)}g',
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  _MacroBox(
                    label: 'Kohlenhy.',
                    value: '${widget.macros.carbs.toStringAsFixed(1)}g',
                    color: Colors.amber.shade800,
                  ),
                  const SizedBox(width: 8),
                  _MacroBox(
                    label: 'Fett',
                    value: '${widget.macros.fat.toStringAsFixed(1)}g',
                    color: Colors.red.shade400,
                  ),
                ],
              ),
            ),

            // ── Zutaten (nur für Rezepte) ────────────────────────────
            if (recipe != null) ...[
              const Divider(height: 1),
              InkWell(
                onTap: () =>
                    setState(() => _showIngredients = !_showIngredients),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.list, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Zutaten (${recipe.ingredients.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _showIngredients
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _buildIngredientList(
                  recipe,
                  ref.watch(activeFoodDataProvider),
                ),
                crossFadeState: _showIngredients
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],

            const Divider(height: 1),

            // ── Aktions-Buttons ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.isRecurring)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onHideForToday();
                      },
                      icon: const Icon(LucideIcons.eyeOff, size: 16),
                      label: const Text('Für heute ausblenden'),
                    ),
                  if (widget.isRecurring) const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onRemoveFromPlan();
                    },
                    icon: Icon(
                      LucideIcons.trash2,
                      size: 16,
                      color: Colors.red.shade600,
                    ),
                    label: Text(
                      'Aus Plan entfernen',
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.shade300),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientList(
    Recipe recipe,
    Map<String, FoodData> foodDataMap,
  ) {
    if (recipe.ingredients.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Text(
          'Keine Zutaten',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        itemCount: recipe.ingredients.length,
        itemBuilder: (_, i) {
          final ing = recipe.ingredients[i];
          final foodData = foodDataMap[ing.foodDataId];
          final unit = foodData?.defaultUnit ?? 'g';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                const Icon(LucideIcons.dot, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    foodData?.name ?? 'Unbekannt',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  '${ing.quantity.toStringAsFixed(0)} $unit',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting widgets
// ─────────────────────────────────────────────────────────────────────────────

class _MacroBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _MacroBox({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: isBold ? 16 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
