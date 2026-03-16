import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const slate = Color(0xFF0F172A);
  const surface = Color(0xFFF8FAFC);
  const accent = Color(0xFF2563EB);
  const mint = Color(0xFF14B8A6);

  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
      primary: accent,
      secondary: mint,
      surface: surface,
    ),
    scaffoldBackgroundColor: surface,
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: slate,
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        color: slate,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: TextStyle(
        color: Color(0xFF475569),
        fontSize: 15,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: slate,
      elevation: 0,
      centerTitle: false,
    ),
  );
}
