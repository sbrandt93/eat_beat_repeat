# Plan: NutritionPlan mit Recurring Meals & Overrides vervollständigen

## Problemanalyse

### Das Problem mit `appliesToDate`

| Datei                                           | Status                                |
| ----------------------------------------------- | ------------------------------------- |
| `lib/logic/models/recurrence_rule.dart`         | ✅ Vollständig implementiert           |
| `lib/logic/models/recurring_meal_template.dart` | ❌ **Nur Methodensignatur ohne Body!** |

Die Idee war: `RecurringMealTemplate` enthält eine `RecurrenceRule` und delegiert an diese. Aber aktuell hat `RecurringMealTemplate` nur `RecurrencePattern pattern` (das Enum) statt `RecurrenceRule rule` (das Objekt mit der Logik).

### Aktueller vs. Ziel-Zustand

```
Current State:                     Draft Plan Target:
─────────────────                  ──────────────────
NutritionPlan (partial)     →      MealPlan (with dayTracking)
  ├─ recurringMeals               ├─ recurringTemplates
  ├─ dayOverrides (stub!)         ├─ dayOverrides (full)
  ├─ dailyMacroTargets            ├─ dailyCalorieGoal
  └─ (missing dayTracking)        └─ dayTracking

RecurringMealTemplate (broken) →   RecurringMealTemplate (working)
  ├─ pattern (enum)               ├─ recurrenceRule (object)
  ├─ time (string)                ├─ defaultDisplayOrder (int)
  └─ appliesToDate() (NO BODY!)   └─ appliesToDate() (delegated)

RecurrenceRule (working ✅)   →    RecurrenceRule (same)

DayOverride (stub)           →     DayOverride (full)
  ├─ date                         ├─ hiddenTemplateIds
  └─ note                         ├─ additionalMeals
                                  └─ templateOrderOverrides

(missing)                    →     DayTracking
                                  └─ mealCompletions

(missing)                    →     MealPlanService
                                  ├─ getMealsForDay()
                                  └─ getCalorieStatsForDay()
```

---

## Implementierungsschritte

### Schritt 1: Fix `RecurringMealTemplate`

**Datei:** `lib/logic/models/recurring_meal_template.dart`

**Änderungen:**
- Ersetze `RecurrencePattern pattern` durch `RecurrenceRule rule`
- Implementiere `appliesToDate()` als Delegation: `=> rule.appliesToDate(date)`
- Füge `toJson()` und `fromJson()` hinzu

### Schritt 2: Vervollständige `DayOverride`

**Datei:** `lib/logic/models/day_override.dart`

**Neue Felder:**
- `List<String> hiddenTemplateIds` - IDs der ausgeblendeten Templates für diesen Tag
- `List<AbstractMealEntry> additionalMeals` - Zusätzliche Mahlzeiten nur für diesen Tag
- `Map<String, int>? templateOrderOverrides` - Optionale Reihenfolge-Änderungen

### Schritt 3: Erstelle `DayTracking`-Klasse

**Neue Datei:** `lib/logic/models/day_tracking.dart`

```dart
class DayTracking {
  final DateTime date;
  final Map<String, bool> mealCompletions; // templateId -> completed

  DayTracking({required this.date, Map<String, bool>? mealCompletions})
      : mealCompletions = mealCompletions ?? {};

  bool isMealCompleted(String templateId) => mealCompletions[templateId] ?? false;

  DayTracking copyWith({Map<String, bool>? mealCompletions}) => DayTracking(
        date: date,
        mealCompletions: mealCompletions ?? this.mealCompletions,
      );
}
```

### Schritt 4: Erstelle `MealPlanService`

**Neue Datei:** `lib/logic/services/meal_plan_service.dart`

**Methoden:**
- `List<MealWithMeta> getMealsForDay(DateTime date)` - Merged Templates + Overrides
- `DayCalorieStats getCalorieStatsForDay(DateTime date)` - Kalorien-Fortschritt

**Algorithmus für `getMealsForDay`:**
```
1. Filtere recurringMeals wo template.appliesToDate(date) == true
2. Prüfe ob dayOverrides[date] existiert
3. Falls ja:
   - Entferne Mahlzeiten deren ID in hiddenTemplateIds ist
   - Füge additionalMeals hinzu
   - Wende templateOrderOverrides an (falls vorhanden)
4. Sortiere nach displayOrder
5. Wrappe jede Mahlzeit in MealWithMeta (für UI-Infos)
```

### Schritt 5: Erstelle Helper-Klassen

**`MealWithMeta`** - UI-Helper:
```dart
class MealWithMeta {
  final AbstractMealEntry mealEntry;
  final String? templateId; // null wenn additionalMeal
  final bool isRecurring;
  final bool isAdditional;
  final bool isCompleted;
  final int displayOrder;
}
```

**`DayCalorieStats`** - Statistik-Helper:
```dart
class DayCalorieStats {
  final double targetKcal;
  final double plannedKcal;
  final double completedKcal;
  
  double get remainingKcal => targetKcal - completedKcal;
  double get progressPercent => (completedKcal / targetKcal).clamp(0.0, 1.0);
}
```

### Schritt 6: Vervollständige `NutritionPlan`

**Datei:** `lib/logic/models/nutrition_plan.dart`

**Neue Felder:**
- `Map<DateTime, DayTracking> dayTracking` - Tracking-Daten pro Tag

**Fehlende Methoden:**
- `toJson()` und `fromJson()` vollständig implementieren

### Schritt 7: Fix `NutritionPlanNotifier`

**Datei:** `lib/logic/provider/nutrition_plan_notifier.dart`

- Ruft aktuell `NutritionPlan.fromJson()` auf, das nicht existiert
- Nach Schritt 6 automatisch behoben

---

## Beispiel Unit Test

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MealPlanService.getMealsForDay', () {
    late NutritionPlan plan;
    late MealPlanService service;

    setUp(() {
      plan = NutritionPlan(
        dailyMacroTargets: MacroNutrients(kcal: 2000, protein: 150, carbs: 200, fat: 70),
        recurringMeals: [
          RecurringMealTemplate(
            id: 'oatmeal',
            mealEntry: PredefinedMealEntry(food: oatmeal, grams: 100),
            rule: RecurrenceRule(pattern: RecurrencePattern.daily),09
          ),
          RecurringMealTemplate(
            id: 'steak',
            mealEntry: PredefinedMealEntry(food: steak, grams: 200),
            rule: RecurrenceRule(pattern: RecurrencePattern.weekends),
          ),
        ],
        dayOverrides: {
          DateTime(2026, 2, 7): DayOverride(
            date: DateTime(2026, 2, 7),
            hiddenTemplateIds: ['oatmeal'], // Samstag: kein Haferbrei
            additionalMeals: [pancakeMeal], // Stattdessen Pancakes
          ),
        },
      );
      service = MealPlanService(plan);
    });

    test('gibt wiederkehrende Mahlzeiten für passende Tage zurück', () {
      // Dienstag (Wochentag): nur Oatmeal
      final tuesdayMeals = service.getMealsForDay(DateTime(2026, 2, 3));
      expect(tuesdayMeals.length, 1);
      expect(tuesdayMeals.first.templateId, 'oatmeal');
    });

    test('wendet Overrides korrekt an', () {
      // Samstag (mit Override): Steak + Pancakes, KEIN Oatmeal
      final saturdayMeals = service.getMealsForDay(DateTime(2026, 2, 7));
      expect(saturdayMeals.any((m) => m.templateId == 'oatmeal'), false);
      expect(saturdayMeals.any((m) => m.templateId == 'steak'), true);
      expect(saturdayMeals.any((m) => m.isAdditional), true); // Pancakes
    });

    test('berechnet Kalorien-Fortschritt für einen Tag', () {
      final stats = service.getCalorieStatsForDay(DateTime(2026, 2, 3));
      
      expect(stats.targetKcal, 2000);
      expect(stats.plannedKcal, greaterThan(0)); // Oatmeal kcal
      expect(stats.completedKcal, 0); // noch nichts gegessen
      expect(stats.remainingKcal, 2000);
    });

    test('berücksichtigt abgehakte Mahlzeiten in completedKcal', () {
      // Mahlzeit als gegessen markieren
      plan = plan.copyWith(
        dayTracking: {
          DateTime(2026, 2, 3): DayTracking(
            date: DateTime(2026, 2, 3),
            mealCompletions: {'oatmeal': true},
          ),
        },
      );
      service = MealPlanService(plan);

      final stats = service.getCalorieStatsForDay(DateTime(2026, 2, 3));
      expect(stats.completedKcal, stats.plannedKcal); // Alles gegessen
    });
  });
}
```

---

## Weitere Überlegungen

1. **Soll `DayTracking` separat oder in `DayOverride` integriert werden?**
   - Empfehlung: Separat halten für Klarheit

2. **Wie sollen Overrides in der UI erstellt werden?**
   - Long-Press auf Mahlzeit → "Nur für diesen Tag ausblenden" / "Ersetzen"

3. **DateTime-Normalisierung:**
   - Alle DateTimes sollten auf Mitternacht normalisiert werden für Map-Keys
   - Hilfsfunktion: `DateTime normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);`
