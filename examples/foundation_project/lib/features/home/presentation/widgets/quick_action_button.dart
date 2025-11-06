import 'package:flutter/material.dart';

/// Quick action button widget
class QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const QuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final buttonColor = color ?? colorScheme.primary;
    
    // Determine appropriate foreground color for proper contrast
    final foregroundColor = _getForegroundColor(buttonColor, colorScheme);
    
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  /// Get appropriate foreground color for a given background color
  /// 
  /// Uses theme's on* colors when possible, otherwise calculates
  /// based on color brightness for proper contrast.
  Color _getForegroundColor(Color backgroundColor, ColorScheme colorScheme) {
    // If using primary color, use onPrimary
    if (backgroundColor == colorScheme.primary) {
      return colorScheme.onPrimary;
    }
    
    // If using error color, use onError
    if (backgroundColor == colorScheme.error) {
      return colorScheme.onError;
    }
    
    // If using secondary color, use onSecondary
    if (backgroundColor == colorScheme.secondary) {
      return colorScheme.onSecondary;
    }
    
    // If using tertiary color, use onTertiary
    if (backgroundColor == colorScheme.tertiary) {
      return colorScheme.onTertiary;
    }
    
    // For custom colors, calculate based on brightness
    // Use white for dark colors, black for light colors
    final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }
}

