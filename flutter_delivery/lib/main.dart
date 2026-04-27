import 'package:flutter/material.dart';
import 'presentation/router/app_router.dart';

void main() {
  runApp(const RonsPizzaDeliveryApp());
}

class RonsPizzaDeliveryApp extends StatelessWidget {
  const RonsPizzaDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rons Pizza Delivery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: '/',
    );
  }
}