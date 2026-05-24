import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:eat_beat_repeat/logic/models/nutrition_plan.dart';
import 'package:eat_beat_repeat/logic/utils/helpers.dart';
import 'package:eat_beat_repeat/logic/utils/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Ã–ffnet den Plan-Formular-Dialog.
///
/// [existingPlan] null â†’ Anlegen-Modus; nicht-null â†’ Bearbeiten-Modus.
Future<NutritionPlan?> showPlanFormDialog(
  BuildContext context, {
  NutritionPlan? existingPlan,
}) {
  return showDialog<NutritionPlan>(
    context: context,
    barrierDismissible: false,
    builder: (context) => NutritionPlanFormDialog(existingPlan: existingPlan),
  );
}

/// Kurzform: Ã¶ffnet den Plan-Dialog im Anlegen-Modus.
Future<NutritionPlan?> showCreatePlanDialog(BuildContext context) =>
    showPlanFormDialog(context);

/// Universeller Plan-Dialog fÃ¼r Anlegen und Bearbeiten.
///
/// Im Anlegen-Modus ([existingPlan] == null) sind alle Felder leer mit
/// Standardwerten. Im Bearbeiten-Modus werden die Felder des bestehenden
/// Plans vorbelegt und beim Speichern ein aktualisiertes Objekt mit
/// unverÃ¤nderter ID zurÃ¼ckgegeben.
class NutritionPlanFormDialog extends ConsumerStatefulWidget {
  /// Bestehender Plan fÃ¼r den Bearbeiten-Modus; null fÃ¼r Anlegen-Modus.
  final NutritionPlan? existingPlan;

  const NutritionPlanFormDialog({super.key, this.existingPlan});

  @override
  ConsumerState<NutritionPlanFormDialog> createState() =>
      _NutritionPlanFormDialogState();
}

class _NutritionPlanFormDialogState
    extends ConsumerState<NutritionPlanFormDialog> {
  bool get _isEditMode => widget.existingPlan != null;

  late final TextEditingController _nameController;
  late DateTime _startDate;
  late DateTime? _endDate;
  late bool _hasEndDate;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;

  @override
  void initState() {
    super.initState();
    final p = widget.existingPlan;
    _nameController = TextEditingController(text: p?.name ?? '');
    _startDate = p?.startDate ?? DateTime.now();
    _endDate = p?.endDate;
    _hasEndDate = p?.endDate != null;
    _caloriesController = TextEditingController(
      text: p?.dailyMacroTargets.calories.toStringAsFixed(0) ?? '2000',
    );
    _proteinController = TextEditingController(
      text: p?.dailyMacroTargets.protein.toStringAsFixed(0) ?? '150',
    );
    _carbsController = TextEditingController(
      text: p?.dailyMacroTargets.carbs.toStringAsFixed(0) ?? '200',
    );
    _fatController = TextEditingController(
      text: p?.dailyMacroTargets.fat.toStringAsFixed(0) ?? '70',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: screenHeight * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(child: _buildContent()),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _isEditMode ? 'Plan bearbeiten' : 'Neuer ErnÃ¤hrungsplan',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () => Navigator.pop(context),
            tooltip: 'SchlieÃŸen',
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Plan-Name',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'z.B. "Definitionsphase"',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Zeitraum',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildDatePicker(
            label: 'Startdatum',
            date: _startDate,
            onTap: () => _selectDate(isStart: true),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: _hasEndDate,
                onChanged: (v) => setState(() => _hasEndDate = v ?? false),
              ),
              const Text('Enddatum festlegen'),
            ],
          ),
          if (_hasEndDate)
            _buildDatePicker(
              label: 'Enddatum',
              date: _endDate ?? _startDate.add(const Duration(days: 30)),
              onTap: () => _selectDate(isStart: false),
            ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'TÃ¤gliche Makro-Ziele',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMacroInput('Kcal', _caloriesController)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroInput('Protein (g)', _proteinController),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMacroInput('Carbs (g)', _carbsController)),
              const SizedBox(width: 12),
              Expanded(child: _buildMacroInput('Fett (g)', _fatController)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(LucideIcons.check),
              label: Text(_isEditMode ? 'Speichern' : 'Erstellen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(LucideIcons.calendar),
        ),
        child: Text(formatDateTime(date)),
      ),
    );
  }

  Widget _buildMacroInput(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Future<void> _selectDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? _startDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib einen Namen ein.')),
      );
      return;
    }

    final macros = MacroNutrients(
      calories: double.tryParse(_caloriesController.text) ?? 2000,
      protein: double.tryParse(_proteinController.text) ?? 150,
      carbs: double.tryParse(_carbsController.text) ?? 200,
      fat: double.tryParse(_fatController.text) ?? 70,
    );

    final result = _isEditMode
        ? widget.existingPlan!.copyWith(
            name: _nameController.text,
            startDate: _startDate,
            endDate: Wrapper(_hasEndDate ? _endDate : null),
            dailyMacroTargets: macros,
          )
        : NutritionPlan(
            name: _nameController.text,
            startDate: _startDate,
            endDate: _hasEndDate ? _endDate : null,
            dailyMacroTargets: macros,
          );

    Navigator.pop(context, result);
  }
}
