import 'package:eat_beat_repeat/frontend/pages/home/home_page.dart';
import 'package:eat_beat_repeat/frontend/pages/meal_plans/meal_plans_page.dart';
import 'package:eat_beat_repeat/frontend/pages/foods_and_recipes/foods_and_recipes_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eat_beat_repeat/frontend/pages/workouts/workouts_page.dart';
import 'package:eat_beat_repeat/frontend/pages/profile/profile_page.dart';

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
      const MealPlansPage(),
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
      // HIER ist der Schlüssel: IndexedStack
      // Zeigt nur das Widget an der Position '_selectedIndex'.
      // Die anderen Widgets bleiben im Speicher erhalten.
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // Die Bottom Navigation Bar
      bottomNavigationBar: NavigationBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        indicatorColor: Theme.of(
          context,
        ).colorScheme.onPrimary.withOpacity(0.2), // Visueller Indikator
        selectedIndex: _selectedIndex, // Zeigt an, welcher Tab aktiv ist
        onDestinationSelected:
            _onItemTapped, // Ruft die Methode zum Wechseln auf

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book, color: Colors.white),
            label: 'Recipes',
          ),
          NavigationDestination(
            icon: Icon(Icons.fastfood, color: Colors.white),
            label: 'Meal Plans',
          ),
          NavigationDestination(
            icon: Icon(Icons.home, color: Colors.white),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center, color: Colors.white),
            label: 'Workouts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person, color: Colors.white),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
