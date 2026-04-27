import 'package:flutter/material.dart';
import '../screens/deliveries_screen.dart';
import '../screens/login_screen.dart';
import '../screens/route_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/deliveries':
        return MaterialPageRoute(builder: (_) => const DeliveriesScreen());
      case '/route':
        return MaterialPageRoute(
          builder: (_) => RouteScreen(args: (settings.arguments as Map<String, dynamic>? ?? const <String, dynamic>{})),
        );
      default:
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Route not found'))));
    }
  }
}
