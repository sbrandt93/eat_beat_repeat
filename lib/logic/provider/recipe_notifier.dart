// lib/logic/providers/recipe_provider.dart

import 'package:eat_beat_repeat/logic/interfaces/i_storage_service.dart';
import 'package:eat_beat_repeat/logic/models/recipe.dart';
import 'package:eat_beat_repeat/logic/provider/base_storage_notifier.dart';

class RecipeNotifier extends BaseStorageNotifier<Recipe> {
  RecipeNotifier(IStorageService storageService)
    : super(
        storageService: storageService,
        storageKey: 'recipes.json',
        fromJson: (json) => Recipe.fromJson(json),
        toJson: (item) => item.toJson(),
      );
}

//   final IStorageService _storageService;

//   RecipeNotifier(this._storageService) : super({}) {
//     _load();
//   }

//   final String _storageKey = 'recipes.json';

//   Future<void> _load() async {
//     final jsonMap = await _storageService.loadJsonFromFile(_storageKey);
//     final data = jsonMap.map(
//       (key, json) => MapEntry(key, Recipe.fromJson(json)),
//     );
//     state = data;
//   }

//   Future<void> _save() async {
//     final jsonMap = state.map(
//       (key, recipe) => MapEntry(key, recipe.toJson()),
//     );
//     await _storageService.saveJsonToFile(_storageKey, jsonMap);
//   }

//   void add(Recipe recipe) {
//     state = {...state, recipe.id: recipe};
//     _save();
//   }

//   void addOrUpdate(Recipe updated) {
//     state = {...state, updated.id: updated};
//     _save();
//   }

//   void remove(String id) {
//     state = Map.from(state)..remove(id);
//     _save();
//   }
// }
