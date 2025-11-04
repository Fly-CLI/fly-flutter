import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Theme data for the app
class AppThemeData {
  final ColorScheme colors;
  final TextTheme textTheme;

  const AppThemeData({
    required this.colors,
    required this.textTheme,
  });

  Color get primary => colors.primary;
  Color get error => colors.error;
  Color get success => Colors.green;
  Color get warning => Colors.orange;
}

/// Provider for theme data
final appThemeProvider = Provider<AppThemeData>((ref) {
  final theme = Theme.of(ref.context);
  return AppThemeData(
    colors: theme.colorScheme,
    textTheme: theme.textTheme,
  );
});

/// Extension on WidgetRef to access theme
extension ThemeRefExtension on WidgetRef {
  AppThemeData get appTheme {
    try {
      return ref.read(appThemeProvider);
    } catch (e) {
      // Fallback if context is not available
      final theme = ThemeData.light();
      return AppThemeData(
        colors: theme.colorScheme,
        textTheme: theme.textTheme,
      );
    }
  }
}

