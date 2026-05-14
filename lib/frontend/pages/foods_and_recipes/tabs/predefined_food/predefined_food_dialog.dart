import 'package:eat_beat_repeat/frontend/pages/shared/macro_sort_bar.dart';
import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/models/predefined_food.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shows the PredefinedFood Dialog and returns the created/updated PredefinedFood
Future<PredefinedFood?> showPredefinedFoodDialog({
  required BuildContext context,
  PredefinedFood? existingPredefinedFood,
}) {
  return showDialog<PredefinedFood>(
    context: context,
    barrierDismissible: false,
    builder: (context) =>
        PredefinedFoodDialog(existingPredefinedFood: existingPredefinedFood),
  );
}

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
  late double _quantity;
  String _searchQuery = '';
  final List<MacroSortCriteria> _sortCriteria = [];
  final _quantityController = TextEditingController();

  void _toggleSort(MacroSortField field) {
    setState(() {
      final idx = _sortCriteria.indexWhere((c) => c.field == field);
      if (idx == -1) {
        _sortCriteria.add(MacroSortCriteria(field, descending: true));
      } else if (_sortCriteria[idx].descending) {
        _sortCriteria[idx] = MacroSortCriteria(field, descending: false);
      } else {
        _sortCriteria.removeAt(idx);
      }
    });
  }

  bool get _isEdit => widget.existingPredefinedFood != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingPredefinedFood;
    _selectedFoodDataId = existing?.foodDataId;
    _quantity = existing?.quantity ?? 100;
    _quantityController.text = _isEdit ? _quantity.toStringAsFixed(1) : '';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final activeFoodData = ref.watch(activeFoodDataProvider);
    final selectedFoodData = activeFoodData[_selectedFoodDataId];

    // Filter food data by search query
    final filteredFoodData = _searchQuery.isEmpty
        ? activeFoodData.values.toList()
        : activeFoodData.values.where((fd) {
            final query = _searchQuery.toLowerCase();
            return fd.name.toLowerCase().contains(query) ||
                fd.brandName.toLowerCase().contains(query);
          }).toList();

    // Multi-column sort
    final sortedFoodData = List.of(filteredFoodData);
    if (_sortCriteria.isNotEmpty) {
      sortedFoodData.sort((a, b) {
        for (final c in _sortCriteria) {
          final double aVal;
          final double bVal;
          switch (c.field) {
            case MacroSortField.calories:
              aVal = a.macrosPer100unit.calories;
              bVal = b.macrosPer100unit.calories;
            case MacroSortField.protein:
              aVal = a.macrosPer100unit.protein;
              bVal = b.macrosPer100unit.protein;
            case MacroSortField.carbs:
              aVal = a.macrosPer100unit.carbs;
              bVal = b.macrosPer100unit.carbs;
            case MacroSortField.fat:
              aVal = a.macrosPer100unit.fat;
              bVal = b.macrosPer100unit.fat;
          }
          final cmp = c.descending
              ? bVal.compareTo(aVal)
              : aVal.compareTo(bVal);
          if (cmp != 0) return cmp;
        }
        return 0;
      });
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 500,
        height: screenHeight * 0.85,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: screenHeight * 0.85,
        ),
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1),
            Expanded(
              child: _buildContent(
                activeFoodData,
                sortedFoodData,
                selectedFoodData,
              ),
            ),
            _buildFooter(activeFoodData),
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
              _isEdit ? 'Portion bearbeiten' : 'Neue Portion anlegen',
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

  Widget _buildContent(
    Map<String, FoodData> activeFoodData,
    List<FoodData> sortedFoodData,
    FoodData? selectedFoodData,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info when no FoodData exists
        if (activeFoodData.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.circleAlert,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bitte zuerst Lebensmittel-Daten anlegen.',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // Search field
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: !_isEdit,
              decoration: InputDecoration(
                hintText: 'Lebensmittel suchen...',
                prefixIcon: const Icon(LucideIcons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          MacroSortBar(
            sortCriteria: _sortCriteria,
            onToggle: _toggleSort,
            onReset: () => setState(() => _sortCriteria.clear()),
          ),
          const SizedBox(height: 4),

          // Food data list
          Expanded(
            child: sortedFoodData.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'Keine Lebensmittel vorhanden'
                          : 'Keine Treffer für "$_searchQuery"',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    itemCount: sortedFoodData.length,
                    itemBuilder: (context, index) {
                      final fd = sortedFoodData[index];
                      final isSelected = _selectedFoodDataId == fd.id;

                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        selectedTileColor: Colors.teal.shade50,
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? Colors.teal
                              : Colors.grey.shade200,
                          radius: 16,
                          child: Icon(
                            isSelected ? LucideIcons.check : LucideIcons.apple,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                        title: Text(
                          fd.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          '${fd.macrosPer100unit.calories.toStringAsFixed(0)} kcal'
                          '  |  ${fd.macrosPer100unit.protein.toStringAsFixed(1)}g P'
                          '  |  ${fd.macrosPer100unit.carbs.toStringAsFixed(1)}g K'
                          '  |  ${fd.macrosPer100unit.fat.toStringAsFixed(1)}g F'
                          '${fd.brandName.isNotEmpty ? '\n${fd.brandName}' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        isThreeLine: fd.brandName.isNotEmpty,
                        onTap: () {
                          setState(() => _selectedFoodDataId = fd.id);
                        },
                      );
                    },
                  ),
          ),

          // Quantity input (only when food is selected)
          if (_selectedFoodDataId != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ausgewählt: ${selectedFoodData?.name ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText:
                            'Portionsmenge in ${selectedFoodData?.defaultUnit ?? 'g/ml'}',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      validator: (value) {
                        final parsed = double.tryParse(value ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Gültige positive Zahl erforderlich';
                        }
                        return null;
                      },
                      onSaved: (value) =>
                          _quantity = double.tryParse(value ?? '0') ?? 0,
                    ),

                    // Show macro preview
                    if (selectedFoodData != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nährwerte pro 100g:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${selectedFoodData.macrosPer100unit.calories.toStringAsFixed(0)} kcal | '
                              '${selectedFoodData.macrosPer100unit.protein.toStringAsFixed(1)}g P | '
                              '${selectedFoodData.macrosPer100unit.carbs.toStringAsFixed(1)}g K | '
                              '${selectedFoodData.macrosPer100unit.fat.toStringAsFixed(1)}g F',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildFooter(Map<String, FoodData> activeFoodData) {
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
              onPressed: (activeFoodData.isEmpty || _selectedFoodDataId == null)
                  ? null
                  : _savePredefinedFood,
              icon: const Icon(LucideIcons.check),
              label: const Text('Speichern'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _savePredefinedFood() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    final predefinedFoodNotifier = ref.read(predefinedFoodProvider.notifier);

    if (_isEdit) {
      final updatedPredefinedFood = widget.existingPredefinedFood!.copyWith(
        foodDataId: _selectedFoodDataId!,
        quantity: _quantity,
      );
      predefinedFoodNotifier.upsert(updatedPredefinedFood);
      Navigator.of(context).pop(updatedPredefinedFood);
    } else {
      final newPredefinedFood = PredefinedFood(
        foodDataId: _selectedFoodDataId!,
        quantity: _quantity,
      );
      predefinedFoodNotifier.upsert(newPredefinedFood);
      Navigator.of(context).pop(newPredefinedFood);
    }
  }
}
