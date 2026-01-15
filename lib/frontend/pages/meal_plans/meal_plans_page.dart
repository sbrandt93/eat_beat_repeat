// page where users can view and manage their meal plans
// home page has bottom navigation bar to other pages like this, home, profile, workouts, and recipes
// if daily plan provider is empty, show message to create a new meal plan
// else show list of meal plans as carts with info like date, meals, calories, etc. and on tap navigate to detailed meal plan page

import 'package:eat_beat_repeat/frontend/router/app_router.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:eat_beat_repeat/logic/utils/helpers.dart';
import 'package:eat_beat_repeat/logic/models/meal_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MealPlansPage extends ConsumerWidget {
  const MealPlansPage({super.key});

  // 1. Die Methode zum Anzeigen des Dialogs
  Future<void> _showNewPlanDialog(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    DateTime? selectedDate = DateTime.now();

    // Zeigt den Dialog an und wartet auf das Ergebnis
    final result = await showDialog<MealPlan?>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _NewPlanInputDialog(
          titleController: titleController,
          initialDate: selectedDate,
        );
      },
    );

    // 2. Wenn der Benutzer bestätigt hat (result ist nicht null)
    if (result != null) {
      // Füge den neuen Plan über den Riverpod Notifier hinzu
      ref.read(mealPlanProvider.notifier).add(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealPlansMap = ref.watch(mealPlanProvider);
    final mealPlans = mealPlansMap.values.toList();
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/vion/vion_basic.png',
              height: 50,
            ),
            const SizedBox(width: 10),
            const Text(
              'Ernährungspläne',
              style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Deine Pläne',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: mealPlans.isEmpty
                ? const Center(
                    child: Text(
                      'Keine Ernährungspläne vorhanden.\nErstelle einen neuen Plan!',
                    ),
                  )
                : ListView.builder(
                    itemCount: mealPlans.length,
                    itemBuilder: (context, index) {
                      final plan = mealPlans[index];
                      return MealPlanCard(plan: plan);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewPlanDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class MealPlanCard extends ConsumerWidget {
  const MealPlanCard({
    super.key,
    required this.plan,
  });

  final MealPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                // Führe die Navigation aus und übergebe die plan.id
                Navigator.of(context).pushNamed(
                  Routes.mealPlanDetail.name,
                  arguments: plan.id, // <-- Die ID wird übergeben
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Date: ${formatDateTime(plan.date)}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    // Text('Calories: ${plan.totalMacros({}, {}).calories} kcal'),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(mealPlanProvider.notifier).remove(plan.id);
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
    );
  }
}

// meal_plans_page.dart (im selben File darunter oder in einem separaten File)

class _NewPlanInputDialog extends ConsumerStatefulWidget {
  final TextEditingController titleController;
  final DateTime? initialDate;

  const _NewPlanInputDialog({
    required this.titleController,
    required this.initialDate,
  });

  @override
  ConsumerState<_NewPlanInputDialog> createState() =>
      _NewPlanInputDialogState();
}

class _NewPlanInputDialogState extends ConsumerState<_NewPlanInputDialog> {
  late DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
  }

  // Widget zum Auswählen des Datums
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate!,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Neuen Ernährungsplan erstellen'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            // Eingabefeld für den Titel
            TextField(
              controller: widget.titleController,
              decoration: const InputDecoration(
                hintText: "Plan-Name (z.B. 'Woche 1')",
              ),
            ),
            const SizedBox(height: 20),

            // Datumsauswahl-Feld
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Datum: ${formatDateTime(selectedDate!)}',
                  ),
                ),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('Datum wählen'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        // Abbruch-Button
        TextButton(
          child: const Text('Abbrechen'),
          onPressed: () {
            Navigator.of(context).pop(null); // Gibt null zurück
          },
        ),
        // Bestätigungs-Button
        TextButton(
          child: const Text('Erstellen'),
          onPressed: () {
            // Einfache Validierung
            if (widget.titleController.text.isEmpty) {
              // Kurze Benachrichtigung anzeigen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bitte geben Sie einen Plan-Namen ein.'),
                ),
              );
              return;
            }

            // Erstellt das neue DailyPlan-Objekt
            final newPlan = MealPlan(
              name: widget.titleController.text,
              date: selectedDate!,
            );

            // Schließt den Dialog und gibt das neue Objekt zurück
            Navigator.of(context).pop(newPlan);
          },
        ),
      ],
    );
  }
}
