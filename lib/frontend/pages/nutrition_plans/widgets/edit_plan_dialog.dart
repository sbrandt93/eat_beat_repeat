import 'package:eat_beat_repeat/frontend/pages/nutrition_plans/widgets/create_plan_dialog.dart';
import 'package:eat_beat_repeat/logic/models/nutrition_plan.dart';
import 'package:flutter/material.dart';

/// �ffnet den Plan-Formular-Dialog im Bearbeiten-Modus.
///
/// Delegiert an [showPlanFormDialog]. Backward-kompatibler Wrapper.
Future<NutritionPlan?> showEditPlanDialog(
  BuildContext context, {
  required NutritionPlan plan,
}) => showPlanFormDialog(context, existingPlan: plan);
