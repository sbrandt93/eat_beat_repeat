import 'package:eat_beat_repeat/logic/interfaces/i_storage_service.dart';
import 'package:eat_beat_repeat/logic/models/nutrition_plan.dart';
import 'package:flutter_riverpod/legacy.dart';

class NutritionPlanNotifier extends StateNotifier<Map<String, NutritionPlan>> {
  final IStorageService _storageService;

  NutritionPlanNotifier(this._storageService) : super({}) {
    _load();
  }

  final String _storageKey = 'nutrition_plans.json';

  Future<void> _save() async {
    final jsonMap = state.map(
      (key, plan) => MapEntry(key, plan.toJson()),
    );
    await _storageService.saveJsonToFile(_storageKey, jsonMap);
  }

  Future<void> _load() async {
    final jsonMap = await _storageService.loadJsonFromFile(_storageKey);
    final data = jsonMap.map(
      (key, json) => MapEntry(key, NutritionPlan.fromJson(json)),
    );
    state = data;
  }

  void add(NutritionPlan plan) {
    state = {...state, plan.id: plan};
    _save();
  }

  void update(NutritionPlan updated) {
    if (state.containsKey(updated.id)) {
      state = {...state, updated.id: updated};
      _save();
    }
  }

  void remove(String id) {
    state = {...state}..remove(id);
    _save();
  }
}