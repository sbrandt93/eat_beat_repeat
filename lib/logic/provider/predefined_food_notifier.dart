import 'package:eat_beat_repeat/logic/interfaces/i_storage_service.dart';
import 'package:eat_beat_repeat/logic/models/predefined_food.dart';
import 'package:eat_beat_repeat/logic/provider/base_storage_notifier.dart';

class PredefinedFoodNotifier extends BaseStorageNotifier<PredefinedFood> {
  PredefinedFoodNotifier(IStorageService storageService)
    : super(
        storageService: storageService,
        storageKey: 'predefined_foods.json',
        fromJson: (json) => PredefinedFood.fromJson(json),
        toJson: (item) => item.toJson(),
      );
}
