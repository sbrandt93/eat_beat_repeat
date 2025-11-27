import 'package:eat_beat_repeat/frontend/pages/home_page.dart';
import 'package:flutter/material.dart';

enum Routes { home, settings, profile }

class AppRouter {
  Route? getRoute(RouteSettings settings) {
    switch (settings.name) {
      case 'home':
        return MaterialPageRoute(builder: (_) => const HomePage());
      default:
        return null;
    }
  }
}
