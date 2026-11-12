import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() => runApp(const MarbefApp());

class MarbefApp extends StatelessWidget {
  const MarbefApp({super.key});

  static const navy = Color(0xFF20247F);
  static const red = Color(0xFFED1B24);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor Marbef Services',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: navy, primary: navy, secondary: red),
        scaffoldBackgroundColor: const Color(0xFFF5F7FC),
        appBarTheme: const AppBarTheme(backgroundColor: navy, foregroundColor: Colors.white),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
