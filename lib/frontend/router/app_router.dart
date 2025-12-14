import 'package:eat_beat_repeat/frontend/pages/home/home_page.dart';
import 'package:eat_beat_repeat/frontend/pages/meal_plans/meal_plan_detail_page.dart';
import 'package:eat_beat_repeat/frontend/pages/meal_plans/meal_plans_page.dart';
import 'package:eat_beat_repeat/frontend/pages/profile/profile_page.dart';
import 'package:eat_beat_repeat/frontend/pages/foods_and_recipes/foods_and_recipes_page.dart';
import 'package:eat_beat_repeat/frontend/pages/main_page.dart';
import 'package:eat_beat_repeat/frontend/pages/workouts/workouts_page.dart';
import 'package:flutter/material.dart';

enum Routes {
  root,
  recipes,
  mealPlans,
  mealPlanDetail,
  home,
  workouts,
  profile,
}

class AppRouter {
  Route? getRoute(RouteSettings settings) {
    switch (settings.name) {
      case 'root':
        return MaterialPageRoute(builder: (_) => const MainPage());
      case 'recipes':
        return createNoTransitionRoute(const FooodsAndRecipesPage());
      case 'mealPlans':
        return createNoTransitionRoute(const MealPlansPage());
      case 'mealPlanDetail':
        final mealPlanId = settings.arguments as String?;
        return createNoTransitionRoute(MealPlanDetailPage(planId: mealPlanId!));
      case 'home':
        return createNoTransitionRoute(const HomePage());
      case 'workouts':
        return createNoTransitionRoute(const WorkoutsPage());
      case 'profile':
        return createNoTransitionRoute(const ProfilePage());
      default:
        return MaterialPageRoute(builder: (_) => const HomePage());
    }
  }

  Route createNoTransitionRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Keine Animation
        return child;
      },
      transitionDuration: Duration(milliseconds: 0),
    );
  }
}
