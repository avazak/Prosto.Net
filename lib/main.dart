import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ProstoNetApp());
}

class ProstoNetApp extends StatelessWidget {
  const ProstoNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prosto.Net',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0F0F23),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A2E),
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

