// ignore_for_file: unused_local_variable

import 'package:eat_beat_repeat/frontend/router/app_router.dart';
import 'package:eat_beat_repeat/logic/provider/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      child: MyApp(
        appRouter: AppRouter(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  final AppRouter appRouter;
  const MyApp({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // loading providers to initialize data
    final recipesMap = ref.watch(recipeProvider);
    final predefinedFoodsMap = ref.watch(predefinedFoodProvider);
    final mealPlansMap = ref.watch(mealPlanProvider);
    final foodDataMap = ref.watch(foodDataMapProvider);
    final macroService = ref.watch(macroServiceProvider);
    return MaterialApp(
      title: 'Eat-Beat-Repeat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      initialRoute: Routes.root.name,
      onGenerateRoute: appRouter.getRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
