import 'package:flutter/material.dart';

/// App-wide light theme. Large, readable typography chosen so Deaf users
/// and hearing users can both read quickly during a conversation.
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF00796B); // calm teal
  static const Color emergencyRed = Color(0xFFC62828);
  static const Color surface = Color(0xFFF6FBFA);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        surface: surface,
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        titleLarge:
            base.textTheme.titleLarge?.copyWith(fontSize: 22),
        bodyLarge:
            base.textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.5),
        bodyMedium:
            base.textTheme.bodyMedium?.copyWith(fontSize: 16, height: 1.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
