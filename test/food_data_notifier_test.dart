import 'package:eat_beat_repeat/logic/interfaces/i_storage_service.dart';
import 'package:eat_beat_repeat/logic/models/food_data.dart';
import 'package:eat_beat_repeat/logic/models/macro_nutrients.dart';
import 'package:eat_beat_repeat/logic/provider/food_data_notifier.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';

// 1. Mock-Implementierung des Storage-Services, falls nötig (für _save())
// Dies stellt sicher, dass _save() im Test nicht auf Flutter-Plattformcode zugreift.
class MockStorageService implements IStorageService {
  final Map<String, dynamic> _testStorage = {};

  @override
  Future<void> saveJsonToFile(
    String fileName,
    Map<String, dynamic> jsonData,
  ) async {
    _testStorage[fileName] = jsonData;
  }

  @override
  Future<Map<String, dynamic>> loadJsonFromFile(String fileName) async {
    if (_testStorage.containsKey(fileName)) {
      return _testStorage[fileName];
    } else {
      return {};
    }
  }
}

// 2. Mock-Provider für den Storage Service, falls er im Notifier verwendet wird
// final storageServiceProvider = Provider((ref) => MockStorageService());

void main() {
  // WICHTIG: Bindings initialisieren
  TestWidgetsFlutterBinding.ensureInitialized();

  // Deklariere den Provider Container für die gesamte Testgruppe
  late ProviderContainer container;

  final mockStorageService = MockStorageService();

  // Fiktive FoodDataNotifier, falls er keine externen Dependencies hat (nicht empfohlen)
  final foodDataNotifierProvider =
      StateNotifierProvider<FoodDataNotifier, Map<String, FoodData>>((ref) {
        return FoodDataNotifier(mockStorageService);
      });

  // WICHTIG: setUp wird VOR JEDEM Test ausgeführt
  setUp(() {
    // ARRANGE: Erstelle einen neuen Container für jeden Test
    container = ProviderContainer(
      // Hier können Sie Provider überschreiben, die der Notifier braucht (z.B. Storage)
      overrides: [
        storageServiceProvider.overrideWithValue(mockStorageService),
      ],
    );
  });

  // WICHTIG: tearDown wird NACH JEDEM Test ausgeführt
  tearDown(() {
    // Aufräumen des Containers nach jedem Test
    container.dispose();
  });

  group('FoodDataNotifier Tests', () {
    test('Adding a FoodData updates the state correctly', () async {
      // ARRANGE: Hole den Notifier (ACT ist das Holen der Instanz in Riverpod)
      final notifier = container.read(foodDataNotifierProvider.notifier);
      final foodData = FoodData(
        name: 'Orange',
        brandName: 'Citrus World',
        macrosPer100unit: MacroNutrients(
          calories: 47.0,
          protein: 0.9,
          carbs: 12.0,
          fat: 0.1,
        ),
        defaultUnit: 'grams',
      );

      // ACT - Führe die Methode aus
      notifier.upsert(foodData);

      // HINWEIS: Man kann den Zustand auch direkt lesen:
      final stateMap = container.read(foodDataNotifierProvider);

      // TODO: ASSERT - Überprüfe, ob die Map den Eintrag enthält
      expect(stateMap.containsKey(foodData.id), isTrue);

      // TODO: ASSERT - Überprüfe, ob der gespeicherte Wert identisch ist
      expect(stateMap[foodData.id]!.name, equals('Orange'));
      expect(
        stateMap[foodData.id]!.macrosPer100unit.calories,
        closeTo(47.0, 0.01),
      );
      expect(mockStorageService._testStorage['food_data.json'], isNotEmpty);
    });

    test('Removing a FoodData updates the state correctly', () async {
      // ARRANGE: Bereite den Container mit einem initialen Zustand vor
      final notifier = container.read(foodDataNotifierProvider.notifier);
      final initialFoodData = FoodData(
        name: 'TestItem',
        brandName: 'TestBrand',
        macrosPer100unit: MacroNutrients.zero(),
        defaultUnit: 'grams',
      );

      // VORBEREITUNG: Füge das Element hinzu
      notifier.upsert(initialFoodData);
      expect(
        container
            .read(foodDataNotifierProvider)
            .containsKey(initialFoodData.id),
        isTrue,
      );

      // ACT - Element entfernen
      notifier.hardDelete(initialFoodData.id);

      final stateMap = container.read(foodDataNotifierProvider);

      // TODO: ASSERT - Überprüfe, ob es nicht mehr in der Map ist
      expect(stateMap.containsKey(initialFoodData.id), isFalse);
    });
  });
}
