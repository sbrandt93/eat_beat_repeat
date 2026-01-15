# Plan: Multi-Day Meal Planning mit Tracking & Kalorienziel-System

## Anforderungen

### Kernfunktionen
1. **MealPlan mit Zeitraum:** Start- und Enddatum (1 Woche bis mehrere Monate)
2. **Mahlzeiten-Management:**
   - Einzelne Mahlzeiten für spezifische Tage
   - Wiederkehrende Mahlzeiten (täglich, Mo/Mi/Fr, etc.)
   - Freie Reihenfolge (keine festen Kategorien wie Frühstück/Mittag/Abend)
   - Reihenfolge pro Tag individuell anpassbar
3. **Kalorienziel-System:**
   - Tägliches Kalorienziel festlegbar (z.B. 3000 kcal)
   - Fortschrittsbalken: Geplante Mahlzeiten vs. Ziel
   - Fortschrittsbalken: Abgehakte Mahlzeiten vs. Ziel
4. **Tracking:**
   - Mahlzeiten abhakbar
   - Tracking pro Tag (später auswertbar: "Ziel erreicht?")
5. **Flexibilität bei Wiederholungen:**
   - Wiederkehrende Mahlzeit an spezifischem Tag löschbar
   - Reihenfolge pro Tag änderbar ohne globale Auswirkung

### Technische Herausforderungen
- **Problem 1:** Wiederkehrende Mahlzeit löschen an einem Tag, ohne andere Tage zu beeinflussen
- **Problem 2:** Speicher-Effizienz (nicht jeden Tag voll materialisieren)
- **Problem 3:** Reihenfolge pro Tag individuell anpassbar
- **Problem 4:** Balance zwischen Dynamik und Performance

## Architektur-Entscheidung: Hybrid Template-Override Pattern

### Konzept: Das Beste aus beiden Welten

**Ansatz:** Template-basiert mit Day-specific Overrides

#### Varianten-Vergleich

| Ansatz | Speicher | Flexibilität | Komplexität |
|--------|----------|--------------|-------------|
| **Fully Materialized** | ❌ Hoch (alle Tage vollständig) | ✅ Sehr einfach | ✅ Niedrig |
| **Fully Virtual** | ✅ Minimal (nur Templates) | ❌ Schwierig (Ausnahmen) | ❌ Hoch |
| **Hybrid (gewählt)** | ✅ Optimal | ✅ Sehr gut | ⚠️ Mittel |

### Gewählte Lösung: Hybrid Template-Override Pattern ⭐

**Prinzip:**
1. **Templates** definieren wiederkehrende Mahlzeiten (täglich, wöchentlich, etc.)
2. **Day-Overrides** speichern Ausnahmen und Anpassungen für einzelne Tage
3. **Rendering-Engine** kombiniert Templates + Overrides zur Laufzeit

**Vorteile:**
- ✅ Minimaler Speicher (nur Templates + Deltas)
- ✅ Wiederkehrende Mahlzeit an einem Tag löschbar (Override: "hide template X")
- ✅ Reihenfolge pro Tag anpassbar (Override: "template X order = 3")
- ✅ Skaliert gut (3-Monats-Plan kein Problem)
- ✅ Einfache Auswertung ("Welche Tage Ziel erreicht?")

**Nachteile:**
- ⚠️ Komplexere Rendering-Logik
- ⚠️ Merge-Logik nötig beim Anzeigen

## Datenmodell-Architektur

### Core Models (lib/logic/models/)

#### 1. `meal_plan.dart` - Hauptmodell

```dart
/// Meal Plan mit Template-Override Pattern
class MealPlan {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final double dailyCalorieGoal;  // z.B. 3000 kcal
  
  /// Templates für wiederkehrende Mahlzeiten
  final List<RecurringMealTemplate> recurringTemplates;
  
  /// Overrides für spezifische Tage (nur Deltas!)
  final Map<String, DayOverride> dayOverrides;  // key: "2026-01-15"
  
  /// Tracking-Daten pro Tag
  final Map<String, DayTracking> dayTracking;   // key: "2026-01-15"
  
  // Helper properties
  int get totalDays => endDate.difference(startDate).inDays + 1;
  
  // Methods
  Map<String, dynamic> toJson();
  static MealPlan fromJson(Map<String, dynamic> json);
  MealPlan copyWith({...});
  
  /// Helper: Konvertiert DateTime zu dateKey "YYYY-MM-DD"
  static String getDateKey(DateTime date);
}
```

**Speicher-Effizienz Beispiel:**
- 90-Tage-Plan mit 3 wiederkehrenden Mahlzeiten: **3 Templates** statt 270 Einträge
- 5 day-specific Änderungen: **5 kleine Overrides**
- Total: ~8 Objekte statt 270 ✅

#### 2. `recurring_meal_template.dart` - Wiederholungs-Templates

```dart
/// Template für wiederkehrende Mahlzeiten
class RecurringMealTemplate {
  final String id;  // UUID für Referenzierung
  
  /// Die eigentliche Mahlzeit (FoodEntry oder RecipeEntry)
  final AbstractMealEntry mealEntry;
  
  /// Wann gilt dieses Template?
  final RecurrencePattern pattern;
  
  /// Standard-Reihenfolge für diese Mahlzeit
  /// (kann pro Tag via DayOverride überschrieben werden)
  final int defaultDisplayOrder;
  
  // Methods
  Map<String, dynamic> toJson();
  static RecurringMealTemplate fromJson(Map<String, dynamic> json);
  RecurringMealTemplate copyWith({...});
  
  /// Prüft ob dieses Template am gegebenen Datum gilt
  bool appliesToDate(DateTime date);
}

/// Wiederholungs-Muster
enum RecurrencePattern {
  daily,              // Jeden Tag
  weekdays,           // Mo-Fr
  weekends,           // Sa-So
  specificDaysOfWeek, // z.B. Mo, Mi, Fr
}

/// Detaillierte Regel für specificDaysOfWeek
class RecurrenceRule {
  final RecurrencePattern pattern;
  final List<int>? daysOfWeek;  // 1=Mo, 2=Di, ..., 7=So (nur bei specificDaysOfWeek)
  
  bool appliesToDate(DateTime date) {
    switch (pattern) {
      case RecurrencePattern.daily:
        return true;
      case RecurrencePattern.weekdays:
        return date.weekday >= 1 && date.weekday <= 5;
      case RecurrencePattern.weekends:
        return date.weekday == 6 || date.weekday == 7;
      case RecurrencePattern.specificDaysOfWeek:
        return daysOfWeek?.contains(date.weekday) ?? false;
    }
  }
}
```

**Verwendungsbeispiele:**
```dart
// Täglich Haferflocken
RecurringMealTemplate(
  pattern: RecurrenceRule(pattern: RecurrencePattern.daily),
  defaultDisplayOrder: 1,  // Morgens zuerst
  mealEntry: FoodEntry(...),
)

// Mo, Mi, Fr Hähnchen
RecurringMealTemplate(
  pattern: RecurrenceRule(
    pattern: RecurrencePattern.specificDaysOfWeek,
    daysOfWeek: [1, 3, 5],  // Mo=1, Mi=3, Fr=5
  ),
  defaultDisplayOrder: 10,
  mealEntry: RecipeEntry(...),
)
```

#### 3. `day_override.dart` - Tages-spezifische Anpassungen

```dart
/// Speichert ALLE Änderungen/Ausnahmen für einen spezifischen Tag
class DayOverride {
  final String dateKey;  // "2026-01-15"
  
  /// Templates die an diesem Tag NICHT angezeigt werden sollen
  final List<String> hiddenTemplateIds;
  
  /// Zusätzliche Mahlzeiten nur für diesen Tag
  final List<MealEntry> additionalMeals;
  
  /// Überschreibt die Reihenfolge von Templates für diesen Tag
  /// Map: templateId -> neue Reihenfolge
  final Map<String, int> templateOrderOverrides;
  
  // Methods
  Map<String, dynamic> toJson();
  static DayOverride fromJson(Map<String, dynamic> json);
  DayOverride copyWith({...});
  
  /// Helper: Ist dieses Override leer? (kann gelöscht werden)
  bool get isEmpty => 
      hiddenTemplateIds.isEmpty && 
      additionalMeals.isEmpty && 
      templateOrderOverrides.isEmpty;
}
```

**Anwendungsfälle:**

**Fall 1: Wiederkehrende Mahlzeit an einem Tag löschen**
```dart
// User löscht "Haferflocken" am 15.01.2026
dayOverrides["2026-01-15"] = DayOverride(
  hiddenTemplateIds: ["haferflocken-template-id"],
  additionalMeals: [],
  templateOrderOverrides: {},
);
// → Haferflocken-Template gilt weiterhin für alle anderen Tage!
```

**Fall 2: Extra-Mahlzeit für einen Tag**
```dart
// User fügt am 20.01. Geburtstagskuchen hinzu
dayOverrides["2026-01-20"] = DayOverride(
  hiddenTemplateIds: [],
  additionalMeals: [
    MealEntry(id: "cake-123", name: "Geburtstagskuchen", ...)
  ],
  templateOrderOverrides: {},
);
```

**Fall 3: Reihenfolge für einen Tag ändern**
```dart
// User verschiebt "Hähnchen" am 25.01. an erste Stelle
dayOverrides["2026-01-25"] = DayOverride(
  hiddenTemplateIds: [],
  additionalMeals: [],
  templateOrderOverrides: {
    "chicken-template-id": 1,  // Neue Position
  },
);
// → An anderen Tagen bleibt defaultDisplayOrder=10
```

#### 4. `meal_entry.dart` - Konkrete Mahlzeit

```dart
/// Konkrete Mahlzeit (kann in Template oder als day-specific sein)
class MealEntry implements AbstractMealEntry {
  final String id;
  final String name;
  
  // Entweder FoodData oder Recipe (eins von beiden)
  final String? foodDataId;
  final double? foodQuantity;
  
  final String? recipeId;
  final double? recipeServings;
  
  /// Sortier-Reihenfolge (nur für day-specific meals)
  /// Bei Templates ist die Reihenfolge in RecurringMealTemplate.defaultDisplayOrder
  final int displayOrder;
  
  // Methods
  Map<String, dynamic> toJson();
  static MealEntry fromJson(Map<String, dynamic> json);
  MealEntry copyWith({...});
  
  /// Berechnet Makros via MacroService
  MacroNutrients getMacros(MacroService service);
  
  // Factories
  static MealEntry fromFood(FoodData food, double quantity);
  static MealEntry fromRecipe(Recipe recipe, double servings);
}
```

**Warum nicht `FoodEntry` und `RecipeEntry` getrennt?**
- Vereinfachung: Beide verwenden `AbstractMealEntry` Interface
- Einfacheres Override-Handling (nur ein Typ)
- JSON Serialisierung einfacher

#### 5. `day_tracking.dart` - Tracking & Completion

```dart
/// Tracking-Daten für einen spezifischen Tag
class DayTracking {
  final String dateKey;  // "2026-01-15"
  
  /// Welche Mahlzeiten wurden abgehakt?
  /// Map: mealId (template.id oder additionalMeal.id) -> completed
  final Map<String, bool> mealCompletions;
  
  /// Zeitstempel der letzten Änderung
  final DateTime lastUpdated;
  
  // Computed properties
  int get completedCount => mealCompletions.values.where((v) => v).length;
  int get totalMeals => mealCompletions.length;
  bool get allCompleted => totalMeals > 0 && completedCount == totalMeals;
  
  // Methods
  Map<String, dynamic> toJson();
  static DayTracking fromJson(Map<String, dynamic> json);
  DayTracking copyWith({...});
  
  /// Toggle completion status
  DayTracking toggleMeal(String mealId);
}
```

**Tracking-Logik:**
```dart
// User hakt "Haferflocken" am 15.01. ab
dayTracking["2026-01-15"] = dayTracking["2026-01-15"]!.toggleMeal("haferflocken-template-id");

// Später: Auswertung "An welchen Tagen Ziel erreicht?"
final successfulDays = dayTracking.entries
    .where((e) => e.value.allCompleted)
    .map((e) => e.key)
    .toList();
```

## Rendering-Engine: Template-Override Merge

### Kernlogik: getMealsForDay()

**Service: `lib/logic/services/meal_plan_service.dart`**

```dart
class MealPlanService {
  final Map<String, FoodData> foodDataMap;
  final Map<String, Recipe> recipeMap;
  final MacroService macroService;
  
  /// KERNFUNKTION: Berechnet alle Mahlzeiten für einen spezifischen Tag
  /// Merged Templates + Overrides zur Laufzeit
  List<MealWithMeta> getMealsForDay(MealPlan plan, DateTime date) {
    final dateKey = MealPlan.getDateKey(date);
    final override = plan.dayOverrides[dateKey];
    final tracking = plan.dayTracking[dateKey];
    
    // 1. Sammle alle gültigen Templates
    final applicableTemplates = plan.recurringTemplates
        .where((template) => template.appliesToDate(date))
        .where((template) => !(override?.hiddenTemplateIds.contains(template.id) ?? false))
        .toList();
    
    // 2. Erstelle MealWithMeta aus Templates
    final mealsFromTemplates = applicableTemplates.map((template) {
      final order = override?.templateOrderOverrides[template.id] 
          ?? template.defaultDisplayOrder;
      
      return MealWithMeta(
        mealId: template.id,
        entry: template.mealEntry,
        displayOrder: order,
        isRecurring: true,
        isCompleted: tracking?.mealCompletions[template.id] ?? false,
      );
    }).toList();
    
    // 3. Füge day-specific meals hinzu
    final additionalMeals = (override?.additionalMeals ?? []).map((meal) {
      return MealWithMeta(
        mealId: meal.id,
        entry: meal,
        displayOrder: meal.displayOrder,
        isRecurring: false,
        isCompleted: tracking?.mealCompletions[meal.id] ?? false,
      );
    }).toList();
    
    // 4. Merge und sortiere
    final allMeals = [...mealsFromTemplates, ...additionalMeals];
    allMeals.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    
    return allMeals;
  }
  
  /// Kalorienziel-Berechnung für einen Tag
  DayCalorieStats getCalorieStatsForDay(MealPlan plan, DateTime date) {
    final meals = getMealsForDay(plan, date);
    
    double plannedCalories = 0;
    double completedCalories = 0;
    
    for (final meal in meals) {
      final macros = meal.entry.getMacros(macroService);
      plannedCalories += macros.calories;
      
      if (meal.isCompleted) {
        completedCalories += macros.calories;
      }
    }
    
    return DayCalorieStats(
      goal: plan.dailyCalorieGoal,
      planned: plannedCalories,
      completed: completedCalories,
      plannedProgress: plannedCalories / plan.dailyCalorieGoal,
      completedProgress: completedCalories / plan.dailyCalorieGoal,
    );
  }
  
  /// Übersicht über alle Tage
  Map<String, DayCalorieStats> getCalorieStatsForAllDays(MealPlan plan) {
    final stats = <String, DayCalorieStats>{};
    
    for (var i = 0; i < plan.totalDays; i++) {
      final date = plan.startDate.add(Duration(days: i));
      final dateKey = MealPlan.getDateKey(date);
      stats[dateKey] = getCalorieStatsForDay(plan, date);
    }
    
    return stats;
  }
}

/// Mahlzeit mit Metadaten (für UI)
class MealWithMeta {
  final String mealId;
  final AbstractMealEntry entry;
  final int displayOrder;
  final bool isRecurring;
  final bool isCompleted;
  
  MealWithMeta({
    required this.mealId,
    required this.entry,
    required this.displayOrder,
    required this.isRecurring,
    required this.isCompleted,
  });
}

/// Kalorien-Statistik für einen Tag
class DayCalorieStats {
  final double goal;              // z.B. 3000
  final double planned;           // z.B. 2800 (alle Mahlzeiten)
  final double completed;         // z.B. 1500 (abgehakte Mahlzeiten)
  final double plannedProgress;   // 2800/3000 = 0.93
  final double completedProgress; // 1500/3000 = 0.50
  
  bool get goalReached => completed >= goal;
  bool get plannedReachesGoal => planned >= goal;
  
  DayCalorieStats({
    required this.goal,
    required this.planned,
    required this.completed,
    required this.plannedProgress,
    required this.completedProgress,
  });
}
```

### Beispiel-Szenarien

#### Szenario 1: Tag ohne Änderungen

**Setup:**
- Template: "Haferflocken" täglich, order=1
- Template: "Hähnchen" täglich, order=10
- Datum: 15.01.2026

**Rendering:**
```dart
getMealsForDay(plan, DateTime(2026, 1, 15))
// Returns:
[
  MealWithMeta(mealId: "haferflocken-id", displayOrder: 1, isRecurring: true),
  MealWithMeta(mealId: "chicken-id", displayOrder: 10, isRecurring: true),
]
```

#### Szenario 2: Template an einem Tag gelöscht

**Setup:**
- Template: "Haferflocken" täglich, order=1
- Template: "Hähnchen" täglich, order=10
- Override 15.01.: hiddenTemplateIds = ["haferflocken-id"]

**Rendering:**
```dart
getMealsForDay(plan, DateTime(2026, 1, 15))
// Returns:
[
  MealWithMeta(mealId: "chicken-id", displayOrder: 10, isRecurring: true),
]
// Haferflocken fehlt!

getMealsForDay(plan, DateTime(2026, 1, 16))
// Returns:
[
  MealWithMeta(mealId: "haferflocken-id", displayOrder: 1, isRecurring: true),
  MealWithMeta(mealId: "chicken-id", displayOrder: 10, isRecurring: true),
]
// Am 16.01. wieder normal!
```

#### Szenario 3: Reihenfolge für einen Tag geändert

**Setup:**
- Template: "Haferflocken" täglich, order=1
- Template: "Hähnchen" täglich, order=10
- Override 20.01.: templateOrderOverrides = {"chicken-id": 0}

**Rendering:**
```dart
getMealsForDay(plan, DateTime(2026, 1, 20))
// Returns (sortiert!):
[
  MealWithMeta(mealId: "chicken-id", displayOrder: 0, isRecurring: true),  // ZUERST!
  MealWithMeta(mealId: "haferflocken-id", displayOrder: 1, isRecurring: true),
]
```

#### Szenario 4: Extra-Mahlzeit + Tracking

**Setup:**
- Template: "Haferflocken" täglich, order=1
- Override 25.01.: additionalMeals = [MealEntry("kuchen", order=15)]
- Tracking 25.01.: completions = {"haferflocken-id": true, "kuchen": false}

**Rendering:**
```dart
getMealsForDay(plan, DateTime(2026, 1, 25))
// Returns:
[
  MealWithMeta(mealId: "haferflocken-id", displayOrder: 1, isCompleted: true),
  MealWithMeta(mealId: "kuchen", displayOrder: 15, isCompleted: false),
]
```

**Kalorien-Stats:**
```dart
getCalorieStatsForDay(plan, DateTime(2026, 1, 25))
// Angenommen: Haferflocken=400kcal, Kuchen=500kcal, Ziel=3000kcal
// Returns:
DayCalorieStats(
  goal: 3000,
  planned: 900,           // 400 + 500
  completed: 400,         // nur Haferflocken abgehakt
  plannedProgress: 0.30,  // 900/3000
  completedProgress: 0.13, // 400/3000
)
```

## State Management & Persistence

### Provider-Architektur (Riverpod)

**Datei: `lib/logic/provider/meal_plan_notifier.dart`**

```dart
class MealPlanNotifier extends StateNotifier<Map<String, MealPlan>> {
  final IStorageService _storageService;
  static const String _storageKey = 'meal_plans_v2.json';
  
  MealPlanNotifier(this._storageService) : super({}) {
    _load();
  }
  
  // ========== CRUD Operations ==========
  
  void createPlan(MealPlan plan) {
    state = {...state, plan.id: plan};
    _save();
  }
  
  void updatePlan(MealPlan plan) {
    state = {...state, plan.id: plan};
    _save();
  }
  
  void deletePlan(String planId) {
    final newState = Map<String, MealPlan>.from(state);
    newState.remove(planId);
    state = newState;
    _save();
  }
  
  // ========== Template Management ==========
  
  void addRecurringTemplate(String planId, RecurringMealTemplate template) {
    final plan = state[planId];
    if (plan == null) return;
    
    final updatedTemplates = [...plan.recurringTemplates, template];
    updatePlan(plan.copyWith(recurringTemplates: updatedTemplates));
  }
  
  void removeRecurringTemplate(String planId, String templateId) {
    final plan = state[planId];
    if (plan == null) return;
    
    final updatedTemplates = plan.recurringTemplates
        .where((t) => t.id != templateId)
        .toList();
    updatePlan(plan.copyWith(recurringTemplates: updatedTemplates));
  }
  
  void updateRecurringTemplate(String planId, RecurringMealTemplate template) {
    final plan = state[planId];
    if (plan == null) return;
    
    final updatedTemplates = plan.recurringTemplates
        .map((t) => t.id == template.id ? template : t)
        .toList();
    updatePlan(plan.copyWith(recurringTemplates: updatedTemplates));
  }
  
  // ========== Day-Specific Override Management ==========
  
  /// Versteckt ein Template an einem spezifischen Tag
  void hideTemplateOnDay(String planId, DateTime date, String templateId) {
    final plan = state[planId];
    if (plan == null) return;
    
    final dateKey = MealPlan.getDateKey(date);
    final currentOverride = plan.dayOverrides[dateKey] ?? DayOverride(dateKey: dateKey);
    
    final updatedOverride = currentOverride.copyWith(
      hiddenTemplateIds: [...currentOverride.hiddenTemplateIds, templateId],
    );
    
    final updatedOverrides = {...plan.dayOverrides, dateKey: updatedOverride};
    updatePlan(plan.copyWith(dayOverrides: updatedOverrides));
  }
  
  /// Fügt eine day-specific Mahlzeit hinzu
  void addDaySpecificMeal(String planId, DateTime date, MealEntry meal) {
    final plan = state[planId];
    if (plan == null) return;
    
    final dateKey = MealPlan.getDateKey(date);
    final currentOverride = plan.dayOverrides[dateKey] ?? DayOverride(dateKey: dateKey);
    
    final updatedOverride = currentOverride.copyWith(
      additionalMeals: [...currentOverride.additionalMeals, meal],
    );
    
    final updatedOverrides = {...plan.dayOverrides, dateKey: updatedOverride};
    updatePlan(plan.copyWith(dayOverrides: updatedOverrides));
  }
  
  /// Ändert Reihenfolge eines Templates für einen spezifischen Tag
  void setTemplateOrderForDay(String planId, DateTime date, String templateId, int order) {
    final plan = state[planId];
    if (plan == null) return;
    
    final dateKey = MealPlan.getDateKey(date);
    final currentOverride = plan.dayOverrides[dateKey] ?? DayOverride(dateKey: dateKey);
    
    final updatedOrderMap = {...currentOverride.templateOrderOverrides, templateId: order};
    final updatedOverride = currentOverride.copyWith(
      templateOrderOverrides: updatedOrderMap,
    );
    
    final updatedOverrides = {...plan.dayOverrides, dateKey: updatedOverride};
    updatePlan(plan.copyWith(dayOverrides: updatedOverrides));
  }
  
  /// Entfernt day-specific Mahlzeit
  void removeDaySpecificMeal(String planId, DateTime date, String mealId) {
    final plan = state[planId];
    if (plan == null) return;
    
    final dateKey = MealPlan.getDateKey(date);
    final currentOverride = plan.dayOverrides[dateKey];
    if (currentOverride == null) return;
    
    final updatedMeals = currentOverride.additionalMeals
        .where((m) => m.id != mealId)
        .toList();
    
    final updatedOverride = currentOverride.copyWith(additionalMeals: updatedMeals);
    
    if (updatedOverride.isEmpty) {
      // Override ist leer → komplett entfernen (Speicher sparen!)
      final updatedOverrides = Map<String, DayOverride>.from(plan.dayOverrides);
      updatedOverrides.remove(dateKey);
      updatePlan(plan.copyWith(dayOverrides: updatedOverrides));
    } else {
      final updatedOverrides = {...plan.dayOverrides, dateKey: updatedOverride};
      updatePlan(plan.copyWith(dayOverrides: updatedOverrides));
    }
  }
  
  // ========== Tracking/Completion Management ==========
  
  /// Togglet Completion-Status einer Mahlzeit
  void toggleMealCompletion(String planId, DateTime date, String mealId) {
    final plan = state[planId];
    if (plan == null) return;
    
    final dateKey = MealPlan.getDateKey(date);
    final currentTracking = plan.dayTracking[dateKey] ?? DayTracking(
      dateKey: dateKey,
      mealCompletions: {},
      lastUpdated: DateTime.now(),
    );
    
    final updatedTracking = currentTracking.toggleMeal(mealId);
    final updatedTrackingMap = {...plan.dayTracking, dateKey: updatedTracking};
    
    updatePlan(plan.copyWith(dayTracking: updatedTrackingMap));
  }
  
  /// Setzt Completion-Status explizit
  void setMealCompletion(String planId, DateTime date, String mealId, bool completed) {
    final plan = state[planId];
    if (plan == null) return;
    
    final dateKey = MealPlan.getDateKey(date);
    final currentTracking = plan.dayTracking[dateKey] ?? DayTracking(
      dateKey: dateKey,
      mealCompletions: {},
      lastUpdated: DateTime.now(),
    );
    
    final updatedCompletions = {...currentTracking.mealCompletions, mealId: completed};
    final updatedTracking = currentTracking.copyWith(
      mealCompletions: updatedCompletions,
      lastUpdated: DateTime.now(),
    );
    
    final updatedTrackingMap = {...plan.dayTracking, dateKey: updatedTracking};
    updatePlan(plan.copyWith(dayTracking: updatedTrackingMap));
  }
  
  // ========== Persistence ==========
  
  Future<void> _load() async {
    try {
      final json = await _storageService.loadJsonFromFile(_storageKey);
      final Map<String, MealPlan> plans = {};
      
      json.forEach((key, value) {
        plans[key] = MealPlan.fromJson(value as Map<String, dynamic>);
      });
      
      state = plans;
    } catch (e) {
      // File nicht vorhanden oder Fehler → leerer State
      state = {};
    }
  }
  
  Future<void> _save() async {
    final json = <String, dynamic>{};
    state.forEach((key, plan) {
      json[key] = plan.toJson();
    });
    await _storageService.saveJsonToFile(_storageKey, json);
  }
}
```

**Provider Registration (`lib/logic/provider/providers.dart`):**

```dart
final mealPlanProvider = 
    StateNotifierProvider<MealPlanNotifier, Map<String, MealPlan>>(
  (ref) => MealPlanNotifier(ref.watch(storageServiceProvider)),
);

final mealPlanServiceProvider = Provider<MealPlanService>((ref) {
  final foodDataMap = ref.watch(foodDataMapProvider);
  final recipeMap = ref.watch(recipeProvider);
  final macroService = ref.watch(macroServiceProvider);
  
  return MealPlanService(
    foodDataMap: foodDataMap,
    recipeMap: recipeMap,
    macroService: macroService,
  );
});

/// Helper: Aktueller Plan (wenn in Detail-Page)
final currentMealPlanProvider = Provider.family<MealPlan?, String>((ref, planId) {
  return ref.watch(mealPlanProvider)[planId];
});

/// Helper: Mahlzeiten für spezifisches Datum
final mealsForDayProvider = Provider.family<List<MealWithMeta>, (String, DateTime)>(
  (ref, params) {
    final (planId, date) = params;
    final plan = ref.watch(currentMealPlanProvider(planId));
    final service = ref.watch(mealPlanServiceProvider);
    
    if (plan == null) return [];
    return service.getMealsForDay(plan, date);
  },
);

/// Helper: Kalorien-Stats für Tag
final calorieStatsForDayProvider = Provider.family<DayCalorieStats?, (String, DateTime)>(
  (ref, params) {
    final (planId, date) = params;
    final plan = ref.watch(currentMealPlanProvider(planId));
    final service = ref.watch(mealPlanServiceProvider);
    
    if (plan == null) return null;
    return service.getCalorieStatsForDay(plan, date);
  },
);
```

### Storage-Format (JSON)

**Datei:** `meal_plans_v2.json`

```json
{
  "plan-uuid-abc": {
    "id": "plan-uuid-abc",
    "name": "Muskelaufbau Januar 2026",
    "startDate": "2026-01-06T00:00:00.000Z",
    "endDate": "2026-02-02T00:00:00.000Z",
    "dailyCalorieGoal": 3000.0,
    "recurringTemplates": [
      {
        "id": "template-1",
        "mealEntry": {
          "id": "meal-1",
          "name": "Haferflocken mit Milch",
          "foodDataId": "food-123",
          "foodQuantity": 100.0,
          "recipeId": null,
          "recipeServings": null,
          "displayOrder": 1
        },
        "pattern": {
          "pattern": "daily",
          "daysOfWeek": null
        },
        "defaultDisplayOrder": 1
      },
      {
        "id": "template-2",
        "mealEntry": {
          "id": "meal-2",
          "name": "Hähnchen mit Reis",
          "foodDataId": null,
          "foodQuantity": null,
          "recipeId": "recipe-456",
          "recipeServings": 1.5,
          "displayOrder": 10
        },
        "pattern": {
          "pattern": "specificDaysOfWeek",
          "daysOfWeek": [1, 3, 5]
        },
        "defaultDisplayOrder": 10
      }
    ],
    "dayOverrides": {
      "2026-01-15": {
        "dateKey": "2026-01-15",
        "hiddenTemplateIds": ["template-1"],
        "additionalMeals": [
          {
            "id": "special-meal-1",
            "name": "Geburtstagskuchen",
            "foodDataId": "food-789",
            "foodQuantity": 200.0,
            "recipeId": null,
            "recipeServings": null,
            "displayOrder": 20
          }
        ],
        "templateOrderOverrides": {}
      },
      "2026-01-20": {
        "dateKey": "2026-01-20",
        "hiddenTemplateIds": [],
        "additionalMeals": [],
        "templateOrderOverrides": {
          "template-2": 0
        }
      }
    },
    "dayTracking": {
      "2026-01-15": {
        "dateKey": "2026-01-15",
        "mealCompletions": {
          "template-2": true,
          "special-meal-1": false
        },
        "lastUpdated": "2026-01-15T18:30:00.000Z"
      }
    }
  }
}
```

**Speicher-Effizienz Beispiel:**
- Plan mit 90 Tagen
- 3 wiederkehrende Templates
- 10 day-specific overrides
- 15 Tage mit Tracking-Daten

**Storage-Größe:**
- `recurringTemplates`: ~3 KB (3 Templates)
- `dayOverrides`: ~2 KB (10 kleine Overrides)
- `dayTracking`: ~1 KB (15 Tage)
- **Total: ~6 KB** statt ~270 KB bei vollständiger Materialisierung! ✅

## UI-Konzept & Komponenten

### Hauptansicht: Meal Plan Detail Page

**Features:**
- **Header:** Plan-Name, Zeitraum, Gesamt-Fortschritt
- **Tages-Ansicht** mit zwei Tabs:
  - **Kalender-View:** Übersicht über alle Tage mit Status-Indikatoren
  - **Listen-View:** Aktuelle Woche/Tag mit Mahlzeiten
- **Fortschrittsbalken:**
  - **Oberer Balken (Blau):** Geplante Kalorien vs. Ziel
  - **Unterer Balken (Grün):** Abgehakte Kalorien vs. Ziel
- **Mahlzeiten-Liste:** Sortierbar, abhakbar, löschbar

### UI-Flow: Reihenfolge ändern

```
Nutzer hält Mahlzeit gedrückt → Drag & Drop
  ↓
UI fragt: "Nur für heute oder dauerhaft ändern?"
  ↓
├─ "Nur heute" → updatePlan mit templateOrderOverride für dieses Datum
└─ "Dauerhaft"  → updateRecurringTemplate mit neuem defaultDisplayOrder
```

### UI-Flow: Mahlzeit löschen

```
Nutzer löscht Mahlzeit
  ↓
Ist es ein recurring template?
  ├─ JA  → Dialog: "Nur heute löschen oder komplett?"
  │         ├─ "Nur heute" → hideTemplateOnDay()
  │         └─ "Komplett"  → removeRecurringTemplate()
  └─ NEIN → removeDaySpecificMeal()
```

### Komponenten-Struktur

#### 1. `meal_plan_detail_page.dart` - Hauptseite

```dart
class MealPlanDetailPage extends ConsumerStatefulWidget {
  final String planId;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(currentMealPlanProvider(planId));
    final selectedDate = useState(DateTime.now());
    
    return Scaffold(
      appBar: AppBar(
        title: Text(plan?.name ?? ''),
        actions: [
          IconButton(icon: Icon(Icons.edit), onPressed: () => _editPlan()),
          IconButton(icon: Icon(Icons.delete), onPressed: () => _deletePlan()),
        ],
      ),
      body: Column(
        children: [
          // Header mit Zeitraum + Gesamt-Stats
          PlanHeaderWidget(plan: plan),
          
          // Tab-View: Kalender vs. Liste
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(tabs: [
                    Tab(icon: Icon(Icons.calendar_month), text: 'Kalender'),
                    Tab(icon: Icon(Icons.list), text: 'Liste'),
                  ]),
                  Expanded(
                    child: TabBarView(children: [
                      CalendarViewTab(planId: planId, onDateSelected: (date) {
                        selectedDate.value = date;
                      }),
                      DayListViewTab(planId: planId, date: selectedDate.value),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        children: [
          SpeedDialChild(
            label: 'Wiederkehrende Mahlzeit',
            onTap: () => _addRecurringMeal(),
          ),
          SpeedDialChild(
            label: 'Mahlzeit für ${formatDate(selectedDate.value)}',
            onTap: () => _addDaySpecificMeal(selectedDate.value),
          ),
        ],
      ),
    );
  }
}
```

#### 2. `plan_header_widget.dart` - Header mit Stats

```dart
class PlanHeaderWidget extends ConsumerWidget {
  final MealPlan? plan;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (plan == null) return SizedBox.shrink();
    
    final service = ref.watch(mealPlanServiceProvider);
    final allStats = service.getCalorieStatsForAllDays(plan);
    
    // Aggregierte Stats
    final totalDays = plan.totalDays;
    final completedDays = allStats.values.where((s) => s.goalReached).length;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '${formatDate(plan.startDate)} - ${formatDate(plan.endDate)}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              'Ziel erreicht: $completedDays / $totalDays Tage',
              style: TextStyle(color: Colors.grey[700]),
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: completedDays / totalDays,
              backgroundColor: Colors.grey[300],
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}
```

#### 3. `day_list_view_tab.dart` - Tages-Ansicht mit Mahlzeiten

```dart
class DayListViewTab extends ConsumerWidget {
  final String planId;
  final DateTime date;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(mealsForDayProvider((planId, date)));
    final stats = ref.watch(calorieStatsForDayProvider((planId, date)));
    
    return Column(
      children: [
        // Datum-Selector
        DateNavigator(
          currentDate: date,
          onDateChanged: (newDate) {
            // Update selected date in parent
          },
        ),
        
        // Kalorien-Fortschrittsbalken
        if (stats != null) DayProgressBars(stats: stats),
        
        // Mahlzeiten-Liste
        Expanded(
          child: ReorderableListView.builder(
            itemCount: meals.length,
            onReorder: (oldIndex, newIndex) {
              _handleReorder(ref, planId, date, meals, oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final meal = meals[index];
              return MealListTile(
                key: ValueKey(meal.mealId),
                planId: planId,
                date: date,
                meal: meal,
              );
            },
          ),
        ),
      ],
    );
  }
  
  void _handleReorder(WidgetRef ref, String planId, DateTime date, 
                     List<MealWithMeta> meals, int oldIndex, int newIndex) {
    final meal = meals[oldIndex];
    
    // Dialog: Nur heute oder dauerhaft?
    if (meal.isRecurring) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Reihenfolge ändern'),
          content: Text('Wie soll die Reihenfolge geändert werden?'),
          actions: [
            TextButton(
              onPressed: () {
                // Nur für diesen Tag
                ref.read(mealPlanProvider.notifier)
                    .setTemplateOrderForDay(planId, date, meal.mealId, newIndex);
                Navigator.pop(context);
              },
              child: Text('Nur heute'),
            ),
            TextButton(
              onPressed: () {
                // Dauerhaft (alle Tage)
                // TODO: Update template defaultDisplayOrder
                Navigator.pop(context);
              },
              child: Text('Dauerhaft'),
            ),
          ],
        ),
      );
    } else {
      // Day-specific meal → direkt ändern
      // TODO: Update additionalMeal displayOrder
    }
  }
}
```

#### 4. `day_progress_bars.dart` - Fortschrittsbalken

```dart
class DayProgressBars extends StatelessWidget {
  final DayCalorieStats stats;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Geplante Kalorien
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Geplant:', style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  '${stats.planned.toStringAsFixed(0)} / ${stats.goal.toStringAsFixed(0)} kcal',
                  style: TextStyle(color: Colors.blue[700]),
                ),
              ],
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: stats.plannedProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              color: Colors.blue,
              minHeight: 10,
            ),
            
            SizedBox(height: 16),
            
            // Abgehakte Kalorien
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Erreicht:', style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  '${stats.completed.toStringAsFixed(0)} / ${stats.goal.toStringAsFixed(0)} kcal',
                  style: TextStyle(color: Colors.green[700]),
                ),
              ],
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: stats.completedProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              color: stats.goalReached ? Colors.green : Colors.orange,
              minHeight: 10,
            ),
            
            if (stats.goalReached)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text('Ziel erreicht!', style: TextStyle(color: Colors.green)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

#### 5. `meal_list_tile.dart` - Einzelne Mahlzeit

```dart
class MealListTile extends ConsumerWidget {
  final String planId;
  final DateTime date;
  final MealWithMeta meal;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final macroService = ref.watch(macroServiceProvider);
    final macros = meal.entry.getMacros(macroService);
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: meal.isCompleted,
          onChanged: (value) {
            ref.read(mealPlanProvider.notifier)
                .toggleMealCompletion(planId, date, meal.mealId);
          },
        ),
        title: Text(
          meal.entry.name,
          style: TextStyle(
            decoration: meal.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${macros.calories.toStringAsFixed(0)} kcal | '
          'P: ${macros.protein.toStringAsFixed(0)}g | '
          'C: ${macros.carbs.toStringAsFixed(0)}g | '
          'F: ${macros.fat.toStringAsFixed(0)}g',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (meal.isRecurring)
              Icon(Icons.repeat, color: Colors.grey, size: 16),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _handleDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }
  
  void _handleDelete(BuildContext context, WidgetRef ref) {
    if (meal.isRecurring) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Mahlzeit löschen'),
          content: Text('Wie soll diese Mahlzeit gelöscht werden?'),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(mealPlanProvider.notifier)
                    .hideTemplateOnDay(planId, date, meal.mealId);
                Navigator.pop(context);
              },
              child: Text('Nur heute'),
            ),
            TextButton(
              onPressed: () {
                ref.read(mealPlanProvider.notifier)
                    .removeRecurringTemplate(planId, meal.mealId);
                Navigator.pop(context);
              },
              child: Text('Komplett'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      );
    } else {
      ref.read(mealPlanProvider.notifier)
          .removeDaySpecificMeal(planId, date, meal.mealId);
    }
  }
}
```

#### 6. `calendar_view_tab.dart` - Kalender-Übersicht

```dart
class CalendarViewTab extends ConsumerWidget {
  final String planId;
  final Function(DateTime) onDateSelected;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(currentMealPlanProvider(planId));
    final service = ref.watch(mealPlanServiceProvider);
    
    if (plan == null) return Center(child: CircularProgressIndicator());
    
    final allStats = service.getCalorieStatsForAllDays(plan);
    
    return TableCalendar(
      firstDay: plan.startDate,
      lastDay: plan.endDate,
      focusedDay: plan.startDate,
      calendarFormat: CalendarFormat.month,
      
      // Marker für jeden Tag
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          final dateKey = MealPlan.getDateKey(date);
          final stats = allStats[dateKey];
          
          if (stats == null) return SizedBox.shrink();
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Geplante Kalorien: Kreis
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: stats.plannedReachesGoal ? Colors.blue : Colors.grey,
                ),
              ),
              SizedBox(width: 2),
              // Erreichte Kalorien: Kreis
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: stats.goalReached ? Colors.green : Colors.orange,
                ),
              ),
            ],
          );
        },
      ),
      
      onDaySelected: (selectedDay, focusedDay) {
        onDateSelected(selectedDay);
      },
    );
  }
}
```

## Implementierungs-Roadmap

### Phase 1: Datenmodelle & Service (Fundament)

**Dateien:**
1. `lib/logic/models/meal_plan.dart`
2. `lib/logic/models/recurring_meal_template.dart`
3. `lib/logic/models/day_override.dart`
4. `lib/logic/models/meal_entry.dart`
5. `lib/logic/models/day_tracking.dart`
6. `lib/logic/services/meal_plan_service.dart`

**Aufwand:** ~6-8 Stunden

**Tests:**
- Unit Tests für `getMealsForDay()` mit verschiedenen Szenarien
- Test für RecurrenceRule.appliesToDate()
- Test für DayOverride merge logic

### Phase 2: State Management & Persistence

**Dateien:**
1. `lib/logic/provider/meal_plan_notifier.dart`
2. Update `lib/logic/provider/providers.dart`

**Aufwand:** ~3-4 Stunden

**Tests:**
- Provider Tests für alle CRUD-Operationen
- Test für Override-Management
- Test für Tracking-Funktionen
- Persistence Tests (JSON Serialization)

### Phase 3: Basis-UI (MVP)

**Dateien:**
1. `lib/frontend/pages/meal_plans/meal_plan_detail_page.dart`
2. `lib/frontend/widgets/day_list_view_tab.dart`
3. `lib/frontend/widgets/day_progress_bars.dart`
4. `lib/frontend/widgets/meal_list_tile.dart`

**Aufwand:** ~8-10 Stunden

**Features:**
- Tages-Ansicht mit Mahlzeiten-Liste
- Fortschrittsbalken für Kalorien
- Abhaken von Mahlzeiten
- Einfaches Löschen (nur "komplett", kein "nur heute")

### Phase 4: Erweiterte UI-Features

**Dateien:**
1. `lib/frontend/widgets/calendar_view_tab.dart`
2. `lib/frontend/widgets/plan_header_widget.dart`
3. Erweitere `meal_list_tile.dart` mit Dialogen

**Aufwand:** ~6-8 Stunden

**Features:**
- Kalender-Ansicht
- "Nur heute vs. dauerhaft" Dialoge
- Drag & Drop für Reihenfolge
- Gesamt-Statistiken im Header

### Phase 5: Erstellung & Verwaltung

**Dateien:**
1. `lib/frontend/pages/meal_plans/meal_plan_creation_page.dart`
2. `lib/frontend/dialogs/recurring_meal_dialog.dart`
3. `lib/frontend/dialogs/add_meal_dialog.dart`

**Aufwand:** ~4-6 Stunden

**Features:**
- Plan erstellen (Name, Start, Ende, Ziel)
- Wiederkehrende Mahlzeit definieren
- Day-specific Mahlzeit hinzufügen

### Phase 6: Integration & Polish

**Dateien:**
1. Update bestehende `meal_plans_page.dart`
2. Router-Integration
3. Navigation

**Aufwand:** ~3-4 Stunden

**Features:**
- Liste aller Pläne
- Navigation zu Detail
- Plan löschen/bearbeiten

### Phase 7: Testing & Bugfixes

**Aufwand:** ~4-6 Stunden

**Aktivitäten:**
- Integration Tests
- UI Tests für kritische Flows
- Performance Testing (90-Tage-Plan)
- Bug-Fixing

---

**Gesamt-Aufwand:** ~34-46 Stunden (~1-1.5 Wochen Vollzeit)

## Technische Entscheidungen & Best Practices

### 1. Warum Hybrid statt Fully Materialized?

**Szenario-Vergleich:**

| Anforderung | Materialized | Hybrid |
|-------------|--------------|--------|
| 90-Tage-Plan, 5 tägliche Mahlzeiten | 450 Einträge (450 KB) | 5 Templates (5 KB) ✅ |
| Mahlzeit an Tag 45 löschen | Einfach: lösche entry | Override: hide template |
| Reihenfolge an Tag 60 ändern | Einfach: ändere order | Override: order override |
| Speicher bei 10 Plänen | ~4.5 MB | ~50 KB ✅ |
| Auswertung "Ziel erreicht?" | ✅ Einfach | ✅ Einfach (via Tracking) |

**Fazit:** Hybrid ist optimal für deine Anforderungen!

### 2. DateKey als String statt DateTime

**Warum `"2026-01-15"` statt `DateTime`?**
- ✅ JSON-kompatibel (kein Parsing nötig)
- ✅ Konsistent bei Zeitzone-Problemen
- ✅ Map-Key funktioniert zuverlässig
- ✅ Human-readable in Storage-File

### 3. Tracking pro Tag statt pro Mahlzeit

**Warum `dayTracking[date]` statt separates `CompletionStatus`?**
- ✅ Natürliche Gruppierung (alle Completions eines Tages zusammen)
- ✅ Effiziente Auswertung ("An welchen Tagen Ziel erreicht?")
- ✅ Einfaches Cleanup (alte Tracking-Daten löschen)
- ✅ Weniger Speicher (1 Objekt pro Tag statt N pro Mahlzeit)

### 4. isEmpty-Check für DayOverride

**Speicher-Optimierung:**
```dart
if (updatedOverride.isEmpty) {
  dayOverrides.remove(dateKey);  // Leere Overrides löschen!
}
```
- Verhindert Speicher-Verschwendung
- Hält JSON-File sauber
- Wichtig bei 90-Tage-Plänen

### 5. Provider.family für Performance

```dart
final mealsForDayProvider = Provider.family<List<MealWithMeta>, (String, DateTime)>
```
- ✅ Cached pro (planId, date) Kombination
- ✅ Nur neu berechnet bei Änderungen
- ✅ Effizient beim Blättern durch Tage

## Erweiterungsmöglichkeiten (Future Features)

### 1. Import/Export von Plänen

```dart
class MealPlan {
  String exportToJson();
  static MealPlan importFromJson(String json);
}
```

### 2. Plan-Templates

```dart
class MealPlanTemplate {
  String name;
  List<RecurringMealTemplate> templates;
  
  MealPlan instantiate(DateTime startDate, DateTime endDate);
}
// User kann "Muskelaufbau-Template" speichern und wiederverwenden
```

### 3. Erweiterte Wiederholungs-Regeln

```dart
enum RecurrencePattern {
  everyNDays,  // z.B. alle 3 Tage
  specificDatesOfMonth,  // z.B. 1., 15., 30.
  // ...
}
```

### 4. Kopieren von Tagen

```dart
void copyDayTo(String planId, DateTime sourceDate, DateTime targetDate) {
  // Kopiert alle Mahlzeiten (inkl. Overrides) von einem Tag zu einem anderen
}
```

### 5. Makro-Ziele pro Mahlzeit

```dart
class MealPlan {
  Map<String, MacroGoals>? mealGoals; // "breakfast" -> MacroGoals
}
```

### 6. Shopping-Liste Generation

```dart
class MealPlanService {
  List<ShoppingItem> generateShoppingList(
    MealPlan plan,
    DateTime startDate,
    DateTime endDate,
  ) {
    // Aggregiert alle Zutaten für Zeitraum
  }
}
```

### 7. Notifications/Reminders

```dart
class DailyReminder {
  String planId;
  TimeOfDay reminderTime;
  String message; // "Vergiss nicht deine Mahlzeiten zu tracken!"
}
```

## Offene Fragen zur Klärung

### 1. Kalorienziel flexibel oder fix?

**Frage:** Soll das Kalorienziel pro Tag variierbar sein?

**Option A - Fix (aktueller Plan):**
- `dailyCalorieGoal: 3000` für alle Tage

**Option B - Flexibel:**
```dart
class MealPlan {
  double defaultDailyCalorieGoal;
  Map<String, double>? dailyGoalOverrides; // dateKey -> abweichendes Ziel
}
```

**Use Case:** Trainingstage 3500 kcal, Ruhetage 2500 kcal

### 2. Makro-Ziele zusätzlich zu Kalorien?

**Frage:** Nur Kalorien oder auch Protein/Carbs/Fat-Ziele?

**Option A - Nur Kalorien** (einfacher)
**Option B - Vollständige Makros** (detaillierter)

```dart
class MacroGoals {
  double calories;
  double? protein;
  double? carbs;
  double? fat;
}
```

### 3. Bestehenden MealPlan beibehalten oder ersetzen?

**Frage:** Wie mit altem Single-Day `MealPlan` umgehen?

**Option A - Komplett ersetzen** (sauber, aber Breaking Change)
**Option B - Parallel existieren** (Abwärtskompatibilität)
**Option C - Migration-Tool** (alt → neu konvertieren)

**Empfehlung:** Option A, da neues System alle Use-Cases abdeckt (Single-Day Plan = Start=End)

### 4. Offline-First oder Online-Sync?

**Aktuell:** Lokaler File-Storage
**Future:** Soll Cloud-Sync möglich sein?

Wenn ja: UUID-basierte IDs (✅ bereits so), Conflict-Resolution nötig

## Nächste Schritte

1. **Entscheidungen treffen** zu offenen Fragen
2. **Phase 1 starten:** Modelle implementieren
3. **Unit Tests schreiben** parallel zu Models
4. **Service-Layer implementieren** mit Rendering-Engine
5. **Provider aufsetzen** mit Persistence
6. **MVP-UI bauen:** Detail-Page mit Tages-Liste
7. **Iterativ erweitern** mit Kalender, Dialogen, etc.

## Zusammenfassung

### Kernkonzept

Das **Hybrid Template-Override Pattern** löst deine Anforderungen elegant:

✅ **Wiederkehrende Mahlzeiten** via Templates (täglich, Mo/Mi/Fr, etc.)
✅ **Flexibilität** via Day-Overrides (Löschen, Reihenfolge, Extra-Mahlzeiten)
✅ **Speicher-Effizient** (Templates + Deltas statt volle Materialisierung)
✅ **Tracking** via DayTracking (abhaken, Ziel-Kontrolle)
✅ **Kalorienziel-System** mit Fortschrittsbalken (geplant vs. erreicht)
✅ **Skalierbar** (1 Woche bis 3 Monate kein Problem)

### Architektur-Highlights

- **Rendering-Engine:** `getMealsForDay()` merged Templates + Overrides zur Laufzeit
- **Speicher:** ~6 KB statt ~270 KB für 90-Tage-Plan
- **UX:** Dialoge für "Nur heute vs. dauerhaft"
- **Tracking:** Pro Tag, nicht pro Mahlzeit
- **Provider:** Riverpod mit family-Providern für Performance

### Aufwand

**Gesamt:** ~34-46 Stunden
**MVP (Phasen 1-3):** ~17-22 Stunden
