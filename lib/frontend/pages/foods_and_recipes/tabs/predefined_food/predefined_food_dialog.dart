import 'package:eat_beat_repeat/logic/models/predefined_food.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PredefinedFoodDialog extends ConsumerStatefulWidget {
  final PredefinedFood? existingPredefinedFood;
  const PredefinedFoodDialog({super.key, this.existingPredefinedFood});

  @override
  ConsumerState<PredefinedFoodDialog> createState() =>
      _PredefinedFoodDialogState();
}

class _PredefinedFoodDialogState extends ConsumerState<PredefinedFoodDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedFoodDataId;
  double _quantity = 0;

  @override
  void initState() {
    super.initState();
    if (widget.existingPredefinedFood != null) {
      _selectedFoodDataId = widget.existingPredefinedFood!.foodDataId;
      _quantity = widget.existingPredefinedFood!.quantity;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeFoodData = ref.watch(activeFoodDataProvider);
    final selectedFoodData = activeFoodData[_selectedFoodDataId];
    final isEdit = widget.existingPredefinedFood != null;

    return AlertDialog(
      title: Text(
        isEdit ? 'Portion bearbeiten' : 'Portion anlegen',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Lebensmittel wählen',
                ),
                initialValue: selectedFoodData?.id,
                items: activeFoodData.values.map((foodData) {
                  return DropdownMenuItem(
                    value: foodData.id,
                    child: Text('${foodData.name} (${foodData.brandName})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFoodDataId = value;
                    // Auto-Name vorschlagen
                  });
                },
                validator: (value) =>
                    value == null ? 'Bitte wählen Sie ein Lebensmittel.' : null,
              ),
              // _buildTextFormField(
              //   'Name der Portion (z.B. "Standard Scoop")',
              //   (val) => _name = val,
              //   initialValue: _name,
              // ),
              _buildNumberFormField(
                label: 'Menge in ${selectedFoodData?.defaultUnit ?? 'g/ml'}',
                initialValue: isEdit ? _quantity.toStringAsFixed(1) : '',
                onSave: (val) => _quantity = val,
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
          onPressed: _savePredefinedFood,
          child: const Text('Speichern'),
        ),
      ],
    );
  }

  // Widget _buildTextFormField(
  //   String label,
  //   Function(String) onSave, {
  //   String initialValue = '',
  // }) {
  //   return Padding(
  //     padding: const EdgeInsets.only(top: 8.0),
  //     child: TextFormField(
  //       initialValue: initialValue,
  //       decoration: InputDecoration(labelText: label),
  //       validator: (value) {
  //         if (value == null || value.isEmpty) {
  //           return 'Bitte geben Sie einen Wert ein.';
  //         }
  //         return null;
  //       },
  //       onSaved: (value) => onSave(value ?? ''),
  //     ),
  //   );
  // }

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
              double.parse(value) <= 0) {
            return 'Bitte geben Sie eine gültige positive Zahl ein.';
          }
          return null;
        },
        onSaved: (value) => onSave(double.tryParse(value ?? '0') ?? 0),
      ),
    );
  }

  void _savePredefinedFood() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final predefinedFoodNotifier = ref.read(
        predefinedFoodProvider.notifier,
      );
      if (widget.existingPredefinedFood != null) {
        // Update existing
        final updatedPredefinedFood = widget.existingPredefinedFood!.copyWith(
          foodDataId: _selectedFoodDataId!,
          quantity: _quantity,
        );
        predefinedFoodNotifier.upsert(
          updatedPredefinedFood,
        );
      } else {
        // Create new
        final newPredefinedFood = PredefinedFood(
          foodDataId: _selectedFoodDataId!,
          quantity: _quantity,
        );
        predefinedFoodNotifier.upsert(
          newPredefinedFood,
        );
      }
      Navigator.of(context).pop();
    }
  }
}
