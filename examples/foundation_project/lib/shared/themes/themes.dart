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
  Color get background => colors.surface;
}

/// Provider for theme data
/// Note: This requires BuildContext, so it should be used within a ConsumerWidget
final appThemeProvider = Provider<AppThemeData>((ref) {
  // Fallback to default theme since we can't access context here
  final theme = ThemeData.light();
  return AppThemeData(
    colors: theme.colorScheme,
    textTheme: theme.textTheme,
  );
});

/// Helper function to get theme from BuildContext
AppThemeData getAppTheme(BuildContext context) {
  final theme = Theme.of(context);
  return AppThemeData(
    colors: theme.colorScheme,
    textTheme: theme.textTheme,
  );
}

/// Extension on WidgetRef to access theme
extension ThemeRefExtension on WidgetRef {
  AppThemeData get appTheme {
    // Fallback if context is not available
    final theme = ThemeData.light();
    return AppThemeData(
      colors: theme.colorScheme,
      textTheme: theme.textTheme,
    );
  }
}
