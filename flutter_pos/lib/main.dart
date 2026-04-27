import 'package:flutter/material.dart';

import 'presentation/figma/figma_pos_shell.dart';

void main() {
  runApp(const RonsPizzaPosApp());
}

class RonsPizzaPosApp extends StatelessWidget {
  const RonsPizzaPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rons Pizza POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        fontFamily: 'Segoe UI',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      ),
      home: const FigmaPosShell(),
    );
  }
}
