// lib/logic/providers/food_data_provider.dart

import 'package:eat_beat_repeat/logic/interfaces/i_storage_service.dart';
import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/provider/base_storage_notifier.dart';

class FoodDataNotifier extends BaseStorageNotifier<FoodData> {
  FoodDataNotifier(IStorageService storageService)
    : super(
        storageService: storageService,
        storageKey: 'food_data.json',
        fromJson: (json) => FoodData.fromJson(json),
        toJson: (item) => item.toJson(),
      );
}

// class FoodDataNotifier extends StateNotifier<Map<String, FoodData>> {
//   final IStorageService _storageService;

//   FoodDataNotifier(this._storageService) : super({}) {
//     _load();
//   }

//   final String _storageKey = 'food_data.json';

//   Future<void> _save() async {
//     final jsonMap = state.map(
//       (key, foodData) => MapEntry(key, foodData.toJson()),
//     );
//     await _storageService.saveJsonToFile(_storageKey, jsonMap);
//   }

//   Future<void> _load() async {
//     final jsonMap = await _storageService.loadJsonFromFile(_storageKey);
//     final data = jsonMap.map(
//       (key, json) => MapEntry(key, FoodData.fromJson(json)),
//     );
//     state = data;
//   }

//   void add(FoodData data) {
//     state = {...state, data.id: data};
//     _save();
//   }

//   void update(FoodData updated) {
//     if (state.containsKey(updated.id)) {
//       state = {...state, updated.id: updated};
//       _save();
//     }
//   }

//   void remove(String id) {
//     state = {...state}..remove(id);
//     _save();
//   }
// }
