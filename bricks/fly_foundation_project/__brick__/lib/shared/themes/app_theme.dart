import 'package:flutter/material.dart';

class AppTheme {
  static final ColorScheme _baseLight = ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: Brightness.light,
  ).harmonized().copyWith(
        primary: const Color(0xFF1B4B91),
        onPrimary: Colors.white,
        secondary: const Color(0xFF006E90),
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: const Color(0xFF1D1B20),
      );

  static final ColorScheme _baseDark = ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: Brightness.dark,
  ).harmonized().copyWith(
        primary: const Color(0xFF9CC2FF),
        onPrimary: const Color(0xFF00315D),
        secondary: const Color(0xFF66DDE8),
        onSecondary: const Color(0xFF00363D),
        surface: const Color(0xFF1C1B1F),
        onSurface: const Color(0xFFE6E1E5),
      );

  static ThemeData get lightTheme => ThemeData(
        colorScheme: _baseLight,
        useMaterial3: true,
        textTheme: _accessibleTextTheme(Typography.blackMountainView),
        visualDensity: VisualDensity.standard,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        colorScheme: _baseDark,
        useMaterial3: true,
        textTheme: _accessibleTextTheme(Typography.whiteMountainView),
        visualDensity: VisualDensity.standard,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      );

  static TextTheme _accessibleTextTheme(TextTheme base) {
    return base.apply(
      fontSizeFactor: 1.02,
      bodyColor: base.bodyLarge?.color,
      displayColor: base.displayLarge?.color,
    );
  }
}

