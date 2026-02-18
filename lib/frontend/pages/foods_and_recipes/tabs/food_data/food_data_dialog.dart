import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:eat_beat_repeat/logic/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shows the FoodData Dialog and returns the created/updated FoodData
Future<FoodData?> showFoodDataDialog({
  required BuildContext context,
  FoodData? existingFoodData,
}) {
  return showDialog<FoodData>(
    context: context,
    barrierDismissible: false,
    builder: (context) => FoodDataDialog(existingFoodData: existingFoodData),
  );
}

class FoodDataDialog extends ConsumerStatefulWidget {
  final FoodData? existingFoodData;

  const FoodDataDialog({super.key, this.existingFoodData});

  @override
  ConsumerState<FoodDataDialog> createState() => _FoodDataDialogState();
}

class _FoodDataDialogState extends ConsumerState<FoodDataDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _brand;
  late String _unit;
  late double _calories;
  late double _protein;
  late double _carbs;
  late double _fat;

  bool get _isEdit => widget.existingFoodData != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingFoodData;
    _name = existing?.name ?? '';
    _brand = existing?.brandName ?? '';
    _unit = existing?.defaultUnit ?? FoodUnit.gramm.displayString;
    _calories = existing?.macrosPer100unit.calories ?? 0;
    _protein = existing?.macrosPer100unit.protein ?? 0;
    _carbs = existing?.macrosPer100unit.carbs ?? 0;
    _fat = existing?.macrosPer100unit.fat ?? 0;
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
          Expanded(
            child: Text(
              _isEdit
                  ? 'Lebensmittel bearbeiten'
                  : 'Neues Lebensmittel anlegen',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Schließen',
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Basic info section
            const Text(
              'Grunddaten',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildTextFormField(
              label: 'Name des Lebensmittels',
              initialValue: _name,
              onSave: (val) => _name = val,
            ),
            const SizedBox(height: 8),
            _buildTextFormField(
              label: 'Marke / Quelle (optional)',
              initialValue: _brand,
              onSave: (val) => _brand = val,
              isRequired: false,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Einheit',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              value: _unit,
              items: FoodUnit.displayValues.map((unit) {
                return DropdownMenuItem(
                  value: unit,
                  child: Text(unit),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _unit = value ?? _unit;
                });
              },
              validator: (value) =>
                  value == null ? 'Bitte wählen Sie eine Einheit.' : null,
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Macros section
            Text(
              'Nährwerte pro 100 $_unit',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildNumberFormField(
                    label: 'Kalorien',
                    initialValue: _isEdit ? _calories.toString() : '',
                    onSave: (val) => _calories = val,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNumberFormField(
                    label: 'Protein (g)',
                    initialValue: _isEdit ? _protein.toString() : '',
                    onSave: (val) => _protein = val,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildNumberFormField(
                    label: 'Kohlenhydrate (g)',
                    initialValue: _isEdit ? _carbs.toString() : '',
                    onSave: (val) => _carbs = val,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNumberFormField(
                    label: 'Fett (g)',
                    initialValue: _isEdit ? _fat.toString() : '',
                    onSave: (val) => _fat = val,
                  ),
                ),
              ],
            ),
          ],
        ),
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saveFoodData,
              icon: const Icon(LucideIcons.check),
              label: const Text('Speichern'),
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

  Widget _buildTextFormField({
    required String label,
    required Function(String) onSave,
    required String initialValue,
    bool isRequired = true,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Bitte ausfüllen';
        }
        return null;
      },
      onSaved: (value) => onSave(value ?? ''),
    );
  }

  Widget _buildNumberFormField({
    required String label,
    required String initialValue,
    required Function(double) onSave,
  }) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      validator: (value) {
        final parsed = double.tryParse(value ?? '');
        if (parsed == null || parsed < 0) {
          return 'Ungültige Zahl';
        }
        return null;
      },
      onSaved: (value) => onSave(double.tryParse(value ?? '0') ?? 0),
    );
  }

  void _saveFoodData() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    final macros = MacroNutrients(
      calories: _calories,
      protein: _protein,
      carbs: _carbs,
      fat: _fat,
    );

    if (_isEdit) {
      final updatedFood = widget.existingFoodData!.copyWith(
        name: _name,
        brandName: _brand,
        defaultUnit: _unit,
        macrosPer100unit: macros,
      );
      ref.read(foodDataMapProvider.notifier).upsert(updatedFood);
      Navigator.of(context).pop(updatedFood);
    } else {
      final newFood = FoodData(
        name: _name,
        brandName: _brand,
        defaultUnit: _unit,
        macrosPer100unit: macros,
      );
      ref.read(foodDataMapProvider.notifier).upsert(newFood);
      Navigator.of(context).pop(newFood);
    }
  }
}
