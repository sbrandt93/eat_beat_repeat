// import 'package:eat_beat_repeat/logic/interfaces/i_storage_service.dart';
// import 'package:eat_beat_repeat/logic/models/meal_entry.dart';
// import 'package:eat_beat_repeat/logic/models/meal_plan.dart';
// import 'package:flutter_riverpod/legacy.dart';

// class MealPlanNotifier extends StateNotifier<Map<String, MealPlan>> {
//   final IStorageService _storageService;

//   MealPlanNotifier(this._storageService) : super({}) {
//     _load();
//   }

//   final String _storageKey = 'meal_plans.json';

//   Future<void> _save() async {
//     final jsonMap = state.map(
//       (key, plan) => MapEntry(key, plan.toJson()),
//     );
//     await _storageService.saveJsonToFile(_storageKey, jsonMap);
//   }

//   Future<void> _load() async {
//     final jsonMap = await _storageService.loadJsonFromFile(_storageKey);
//     final data = jsonMap.map(
//       (key, json) => MapEntry(key, MealPlan.fromJson(json)),
//     );
//     state = data;
//   }

//   void add(MealPlan plan) {
//     state = {...state, plan.id: plan};
//     _save();
//   }

//   void update(MealPlan updated) {
//     if (state.containsKey(updated.id)) {
//       state = {...state, updated.id: updated};
//       _save();
//     }
//   }

//   void remove(String id) {
//     state = {...state}..remove(id);
//     _save();
//   }

//   // Hilfsmethode: Füge MealEntry zu einem Plan hinzu
//   void addEntryToPlan(String planId, MealEntry entry) {
//     if (!state.containsKey(planId)) return;
//     final plan = state[planId];
//     final updatedEntries = [...plan!.entries, entry];
//     final updatedPlan = plan.copyWith(entries: updatedEntries);
//     update(updatedPlan);
//   }

//   /// Hilfsmethode: Aktualisiere MealEntry in einem Plan
//   void updateEntryInPlan(String planId, MealEntry updatedEntry) {
//     if (!state.containsKey(planId)) return;
//     final plan = state[planId];
//     final updatedEntries = plan!.entries.map((entry) {
//       if (entry.id == updatedEntry.id) {
//         return updatedEntry;
//       }
//       return entry;
//     }).toList();
//     final updatedPlan = plan.copyWith(entries: updatedEntries);
//     update(updatedPlan);
//   }

//   /// Hilfsmethode: Entferne MealEntry aus einem Plan
//   void removeEntryFromPlan(String planId, String entryId) {
//     if (!state.containsKey(planId)) return;
//     final plan = state[planId];
//     final updatedEntries = plan!.entries
//         .where((entry) => entry.id != entryId)
//         .toList();

//     final updatedPlan = plan.copyWith(entries: updatedEntries);
//     update(updatedPlan);
//   }
// }
