import 'package:eat_beat_repeat/frontend/pages/home/home_page.dart';
import 'package:eat_beat_repeat/frontend/pages/nutrition_plans/nutrition_plans_page.dart';
import 'package:eat_beat_repeat/frontend/pages/foods_and_recipes/foods_and_recipes_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eat_beat_repeat/frontend/pages/workouts/workouts_page.dart';
import 'package:eat_beat_repeat/frontend/pages/profile/profile_page.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  // Index 2 ist die Mitte: Home
  int _selectedIndex = 2;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const FooodsAndRecipesPage(),
      const NutritionPlansPage(), // Ersetzt alte MealPlansPage
      const HomePage(),
      const WorkoutsPage(),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    // Wenn der Index unverändert ist, machen wir nichts.
    if (_selectedIndex == index) {
      // Optional: Hier könnten Sie den inneren Navigator zum Root popen
      // (aber das ist komplexer und meist nicht nötig).
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // Die Bottom Navigation Bar
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                color: Colors.teal,
              );
            }
            return const IconThemeData(
              color: Colors.black54,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              );
            }
            return const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            );
          }),
        ),
        child: NavigationBar(
          backgroundColor: Colors.white54,
          indicatorColor: Theme.of(
            context,
          ).colorScheme.onPrimary,
          selectedIndex: _selectedIndex, // Zeigt an, welcher Tab aktiv ist
          onDestinationSelected: _onItemTapped,

          destinations: const [
            NavigationDestination(
              icon: Icon(
                LucideIcons.book,
              ),
              label: 'Rezepte',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.fastfood_outlined,
              ),
              label: 'Mahlzeiten',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.home_outlined,
              ),
              label: 'Startseite',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.fitness_center,
              ),
              label: 'Sport',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.person_outline,
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
