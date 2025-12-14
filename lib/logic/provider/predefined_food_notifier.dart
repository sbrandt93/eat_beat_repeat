// lib/logic/providers/predefined_food_provider.dart

import 'package:eat_beat_repeat/logic/interfaces/i_storage_service.dart';
import 'package:eat_beat_repeat/logic/models/predefined_food.dart';
import 'package:flutter_riverpod/legacy.dart';

class PredefinedFoodNotifier
    extends StateNotifier<Map<String, PredefinedFood>> {
  final IStorageService _storageService;

  PredefinedFoodNotifier(this._storageService) : super({}) {
    _load();
  }

  final String _storageKey = 'predefined_foods.json';

  Future<void> _load() async {
    final jsonMap = await _storageService.loadJsonFromFile(_storageKey);
    final data = jsonMap.map(
      (key, json) => MapEntry(key, PredefinedFood.fromJson(json)),
    );
    state = data;
  }

  Future<void> _save() async {
    final jsonMap = state.map(
      (key, food) => MapEntry(key, food.toJson()),
    );
    await _storageService.saveJsonToFile(_storageKey, jsonMap);
  }

  void add(PredefinedFood food) {
    state = {...state, food.id: food};
    _save();
  }

  void update(PredefinedFood updated) {
    if (state.containsKey(updated.id)) {
      state = {...state, updated.id: updated};
      _save();
    }
  }

  void remove(String id) {
    state = Map.from(state)..remove(id);
    _save();
  }
}
