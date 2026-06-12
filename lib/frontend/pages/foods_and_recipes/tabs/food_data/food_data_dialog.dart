import 'dart:io';

import 'package:eat_beat_repeat/frontend/pages/shared/food_image_avatar.dart';
import 'package:eat_beat_repeat/frontend/pages/shared/nutrition_scan_button.dart';
import 'package:flutter/foundation.dart';
import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:eat_beat_repeat/logic/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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

  late TextEditingController _caloriesCtrl;
  late TextEditingController _proteinCtrl;
  late TextEditingController _carbsCtrl;
  late TextEditingController _fatCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _brandCtrl;
  String? _imagePath;

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

    _caloriesCtrl = TextEditingController(
      text: _isEdit ? _calories.toString() : '',
    );
    _proteinCtrl = TextEditingController(
      text: _isEdit ? _protein.toString() : '',
    );
    _carbsCtrl = TextEditingController(text: _isEdit ? _carbs.toString() : '');
    _fatCtrl = TextEditingController(text: _isEdit ? _fat.toString() : '');
    _nameCtrl = TextEditingController(text: _name);
    _brandCtrl = TextEditingController(text: _brand);
    _imagePath = widget.existingFoodData?.imagePath;
  }

  @override
  void dispose() {
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _nameCtrl.dispose();
    _brandCtrl.dispose();
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
            // Image picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  image: _imagePath != null
                      ? DecorationImage(
                          image:
                              (_imagePath!.startsWith('http://') ||
                                  _imagePath!.startsWith('https://'))
                              ? NetworkImage(_imagePath!) as ImageProvider
                              : kIsWeb
                              ? NetworkImage(_imagePath!)
                              : FileImage(File(_imagePath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imagePath != null
                    ? null
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.camera,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Foto hinzufügen',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),
            _buildTextFormField(
              label: 'Name des Lebensmittels',
              controller: _nameCtrl,
              onSave: (val) => _name = val,
            ),
            const SizedBox(height: 8),
            _buildTextFormField(
              label: 'Marke / Quelle (optional)',
              controller: _brandCtrl,
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
            SizedBox(
              width: double.infinity,
              child: NutritionScanButton(
                onResult: (nutrients) {
                  if (nutrients.calories != null) {
                    _caloriesCtrl.text = nutrients.calories!.toStringAsFixed(1);
                  }
                  if (nutrients.protein != null) {
                    _proteinCtrl.text = nutrients.protein!.toStringAsFixed(1);
                  }
                  if (nutrients.carbs != null) {
                    _carbsCtrl.text = nutrients.carbs!.toStringAsFixed(1);
                  }
                  if (nutrients.fat != null) {
                    _fatCtrl.text = nutrients.fat!.toStringAsFixed(1);
                  }
                  if (nutrients.name != null && nutrients.name!.isNotEmpty) {
                    _nameCtrl.text = nutrients.name!;
                  }
                  if (nutrients.brand != null && nutrients.brand!.isNotEmpty) {
                    _brandCtrl.text = nutrients.brand!;
                  }
                  if (nutrients.imageUrl != null &&
                      nutrients.imageUrl!.isNotEmpty) {
                    setState(() => _imagePath = nutrients.imageUrl);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildNumberFormField(
                    label: 'Kalorien',
                    controller: _caloriesCtrl,
                    onSave: (val) => _calories = val,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNumberFormField(
                    label: 'Protein (g)',
                    controller: _proteinCtrl,
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
                    controller: _carbsCtrl,
                    onSave: (val) => _carbs = val,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNumberFormField(
                    label: 'Fett (g)',
                    controller: _fatCtrl,
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
    String? initialValue,
    TextEditingController? controller,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: controller != null ? null : initialValue,
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
    required Function(double) onSave,
    String? initialValue,
    TextEditingController? controller,
  }) {
    assert(
      controller != null || initialValue != null,
      'Either controller or initialValue must be provided',
    );
    return TextFormField(
      controller: controller,
      initialValue: controller != null ? null : initialValue,
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _imagePath = picked.path);
    }
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
        imagePath: _imagePath,
      );
      ref.read(foodDataMapProvider.notifier).upsert(updatedFood);
      Navigator.of(context).pop(updatedFood);
    } else {
      final newFood = FoodData(
        name: _name,
        brandName: _brand,
        defaultUnit: _unit,
        macrosPer100unit: macros,
        imagePath: _imagePath,
      );
      ref.read(foodDataMapProvider.notifier).upsert(newFood);
      Navigator.of(context).pop(newFood);
    }
  }
}
