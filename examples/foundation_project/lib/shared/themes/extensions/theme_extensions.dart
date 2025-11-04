import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Extension on WidgetRef to access theme colors
extension ThemeExtensions on WidgetRef {
  /// Get colors from theme
  /// Note: This requires a valid BuildContext. Use with caution.
  ColorScheme get colors {
    try {
      // WidgetRef doesn't have direct context access
      // This is a placeholder - in practice, pass BuildContext explicitly
      return const ColorScheme.light();
    } catch (e) {
      // Fallback to default colors if context is not available
      return const ColorScheme.light();
    }
  }

  /// Get primary color
  Color get primaryColor => colors.primary;

  /// Get error color
  Color get errorColor => colors.error;

  /// Get success color (using green)
  Color get successColor => Colors.green;

  /// Get warning color (using orange)
  Color get warningColor => Colors.orange;
}

/// Extension on BuildContext to access theme colors
extension ThemeContextExtensions on BuildContext {
  /// Get colors from theme
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Get primary color
  Color get primaryColor => colors.primary;

  /// Get error color
  Color get errorColor => colors.error;

  /// Get success color (using green)
  Color get successColor => Colors.green;

  /// Get warning color (using orange)
  Color get warningColor => Colors.orange;
}
