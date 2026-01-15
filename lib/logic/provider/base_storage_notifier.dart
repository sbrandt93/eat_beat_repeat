import 'package:eat_beat_repeat/logic/interfaces/i_soft_deletable.dart';
import 'package:eat_beat_repeat/logic/interfaces/i_storage_service.dart';
import 'package:eat_beat_repeat/logic/utils/wrapper.dart';
import 'package:flutter_riverpod/legacy.dart';

abstract class BaseStorageNotifier<T extends ISoftDeletable<T>>
    extends StateNotifier<Map<String, T>> {
  final IStorageService storageService;
  final String storageKey;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;

  BaseStorageNotifier({
    required this.storageService,
    required this.storageKey,
    required this.fromJson,
    required this.toJson,
  }) : super({}) {
    _load();
  }

  Future<void> _load() async {
    final jsonMap = await storageService.loadJsonFromFile(storageKey);
    state = jsonMap.map((key, json) => MapEntry(key, fromJson(json)));
  }

  Future<void> _save() async {
    final jsonMap = state.map((key, item) => MapEntry(key, toJson(item)));
    await storageService.saveJsonToFile(storageKey, jsonMap);
  }

  void upsert(T item) {
    state = {...state, item.id: item};
    _save();
  }

  void moveToTrash(String id) {
    final item = state[id];
    if (item != null) {
      upsert(item.copyWith(deletedAt: Wrapper(DateTime.now())));
    }
  }

  void restore(String id) {
    final item = state[id];
    if (item != null) {
      upsert(item.copyWith(deletedAt: Wrapper(null)));
    }
  }

  void hardDelete(String id) {
    state = Map.from(state)..remove(id);
    _save();
  }

  void autoDeleteOldItems(Duration age) {
    final now = DateTime.now();
    final updatedState = Map<String, T>.from(state);
    state.forEach((id, item) {
      final deletedAt = item.deletedAt;
      if (deletedAt != null && now.difference(deletedAt) > age) {
        updatedState.remove(id);
      }
    });
    state = updatedState;
    _save();
  }
}
