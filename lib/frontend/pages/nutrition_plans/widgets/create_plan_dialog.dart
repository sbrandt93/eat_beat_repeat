import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:eat_beat_repeat/logic/models/nutrition_plan.dart';
import 'package:eat_beat_repeat/logic/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shows the Create Nutrition Plan Dialog and returns the created plan
Future<NutritionPlan?> showCreatePlanDialog(BuildContext context) {
  return showDialog<NutritionPlan>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const CreateNutritionPlanDialog(),
  );
}

class CreateNutritionPlanDialog extends ConsumerStatefulWidget {
  const CreateNutritionPlanDialog({super.key});

  @override
  ConsumerState<CreateNutritionPlanDialog> createState() =>
      _CreateNutritionPlanDialogState();
}

class _CreateNutritionPlanDialogState
    extends ConsumerState<CreateNutritionPlanDialog> {
  final _nameController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _hasEndDate = false;

  // Makro-Ziele
  final _caloriesController = TextEditingController(text: '2000');
  final _proteinController = TextEditingController(text: '150');
  final _carbsController = TextEditingController(text: '200');
  final _fatController = TextEditingController(text: '70');

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
              child: SingleChildScrollView(
                child: _buildContent(),
              ),
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
          const Expanded(
            child: Text(
              'Neuer Ernährungsplan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Schließen',
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
          // Name
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

          // Startdatum
          const Text(
            'Zeitraum',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildDatePicker(
            label: 'Startdatum',
            date: _startDate,
            onTap: () => _selectDate(true),
          ),
          const SizedBox(height: 12),

          // Enddatum (optional)
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
              onTap: () => _selectDate(false),
            ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Makro-Ziele
          const Text(
            'Tägliche Makro-Ziele',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildMacroInput('Kcal', _caloriesController),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroInput('Protein (g)', _proteinController),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMacroInput('Carbs (g)', _carbsController),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroInput('Fett (g)', _fatController),
              ),
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
              onPressed: _createPlan,
              icon: const Icon(LucideIcons.check),
              label: const Text('Erstellen'),
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

  Future<void> _selectDate(bool isStart) async {
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

  void _createPlan() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib einen Namen ein.')),
      );
      return;
    }

    final plan = NutritionPlan(
      name: _nameController.text,
      startDate: _startDate,
      endDate: _hasEndDate ? _endDate : null,
      dailyMacroTargets: MacroNutrients(
        calories: double.tryParse(_caloriesController.text) ?? 2000,
        protein: double.tryParse(_proteinController.text) ?? 150,
        carbs: double.tryParse(_carbsController.text) ?? 200,
        fat: double.tryParse(_fatController.text) ?? 70,
      ),
    );

    Navigator.pop(context, plan);
  }
}
