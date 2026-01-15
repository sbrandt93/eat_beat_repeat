import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:eat_beat_repeat/logic/utils/enums.dart';
import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FoodDataDialog extends ConsumerStatefulWidget {
  final FoodData? existingFoodData;
  const FoodDataDialog({super.key, this.existingFoodData});

  @override
  ConsumerState<FoodDataDialog> createState() => _FoodDataDialogState();
}

class _FoodDataDialogState extends ConsumerState<FoodDataDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _brand = '';
  String _unit = FoodUnit.gramm.displayString;
  double _calories = 0;
  double _protein = 0;
  double _carbs = 0;
  double _fat = 0;

  @override
  void initState() {
    super.initState();
    if (widget.existingFoodData != null) {
      _name = widget.existingFoodData!.name;
      _brand = widget.existingFoodData!.brandName;
      _unit = widget.existingFoodData!.defaultUnit;
      _calories = widget.existingFoodData!.macrosPer100unit.calories;
      _protein = widget.existingFoodData!.macrosPer100unit.protein;
      _carbs = widget.existingFoodData!.macrosPer100unit.carbs;
      _fat = widget.existingFoodData!.macrosPer100unit.fat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingFoodData != null;
    return AlertDialog(
      title: Text(
        isEdit ? 'Lebensmittel bearbeiten' : 'Neues Lebensmittel anlegen',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildTextFormField(
                label: 'Name des Lebensmittels',
                initialValue: _name,
                onSave: (val) => _name = val,
              ),
              _buildTextFormField(
                label: 'Marke / Quelle (optional)',
                initialValue: _brand,
                onSave: (val) => _brand = val,
                isRequired: false,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Einheit wählen',
                ),
                initialValue: _unit,
                items: FoodUnit.displayValues.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(unit),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _unit = value ?? _unit;
                    // Auto-Name vorschlagen
                    // _name = '${foodDataMap[value]?.name ?? ''} Portion';
                  });
                },
                validator: (value) =>
                    value == null ? 'Bitte wählen Sie eine Einheit.' : null,
              ),
              // _buildTextFormField(
              //   label: 'Einheit (g/ml)',
              //   initialValue: _unit,
              //   onSave: (val) => _unit = val,
              // ),
              const SizedBox(height: 12),
              const Divider(height: 24),
              Text(
                'Nährwertangaben (pro 100 $_unit)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              _buildNumberFormField(
                label: 'Kalorien',
                initialValue: isEdit ? _calories.toString() : '',
                onSave: (val) => _calories = val,
              ),
              _buildNumberFormField(
                label: 'Protein',
                initialValue: isEdit ? _protein.toString() : '',
                onSave: (val) => _protein = val,
                step: 0.1,
              ),
              _buildNumberFormField(
                label: 'Kohlenhydrate',
                initialValue: isEdit ? _carbs.toString() : '',
                onSave: (val) => _carbs = val,
                step: 0.1,
              ),
              _buildNumberFormField(
                label: 'Fett',
                initialValue: isEdit ? _fat.toString() : '',
                onSave: (val) => _fat = val,
                step: 0.1,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _saveFoodData,
          child: const Text('Speichern'),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required String label,
    required Function(String) onSave,
    required String initialValue,
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'Bitte geben Sie einen Wert ein.';
          }
          return null;
        },
        onSaved: (value) => onSave(value ?? ''),
      ),
    );
  }

  Widget _buildNumberFormField({
    required String label,
    required String initialValue,
    required Function(double) onSave,
    double step = 1.0,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          if (value == null ||
              double.tryParse(value) == null ||
              double.parse(value) < 0) {
            return 'Bitte geben Sie eine gültige positive Zahl ein.';
          }
          return null;
        },
        onSaved: (value) => onSave(double.tryParse(value ?? '0') ?? 0),
      ),
    );
  }

  void _saveFoodData() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final macros = MacroNutrients(
        calories: _calories,
        protein: _protein,
        carbs: _carbs,
        fat: _fat,
      );

      if (widget.existingFoodData != null) {
        // Aktualisiere bestehendes FoodData
        final updatedFood = widget.existingFoodData!.copyWith(
          name: _name,
          brandName: _brand,
          defaultUnit: _unit,
          macrosPer100unit: macros,
        );
        ref.read(foodDataMapProvider.notifier).upsert(updatedFood);
        Navigator.of(context).pop();
        return;
      } else {
        // Erstelle neues FoodData
        final newFood = FoodData(
          name: _name,
          brandName: _brand,
          defaultUnit: _unit,
          macrosPer100unit: macros,
        );
        ref.read(foodDataMapProvider.notifier).upsert(newFood);
      }
      Navigator.of(context).pop();
    }
  }
}
