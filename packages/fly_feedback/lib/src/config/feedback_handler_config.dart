import 'package:flutter/material.dart';
import 'package:fly_feedback/fly_feedback.dart';

/// Base configuration for feedback handlers
///
/// Provides common customization properties shared across all feedback handlers.
/// Handler-specific configurations extend or compose this base class.
abstract class FeedbackHandlerConfig {
  /// Default constructor
  const FeedbackHandlerConfig();

  /// Get background color for a specific feedback type
  Color? getBackgroundColor(FeedbackType type, ColorScheme colorScheme);

  /// Get icon for a specific feedback type
  IconData? getIcon(FeedbackType type);

  /// Get icon color for a specific feedback type
  Color? getIconColor(FeedbackType type, ColorScheme colorScheme);

  /// Get text color for a specific feedback type
  Color? getTextColor(FeedbackType type, ColorScheme colorScheme);

  /// Get default duration for a specific feedback type
  Duration? getDefaultDuration(FeedbackType type);

  /// Get semantics configuration
  FeedbackSemanticsConfig? get semanticsConfig;

  /// Create a copy of this configuration with updated values
  FeedbackHandlerConfig copyWith({
    Map<FeedbackType, Color?>? backgroundColors,
    Map<FeedbackType, IconData?>? icons,
    Map<FeedbackType, Color?>? iconColors,
    Map<FeedbackType, Color?>? textColors,
    Map<FeedbackType, Duration?>? defaultDurations,
    FeedbackSemanticsConfig? semanticsConfig,
  });

  /// Merge this configuration with another
  ///
  /// Values from [other] take precedence over this configuration's values.
  FeedbackHandlerConfig merge(FeedbackHandlerConfig? other);
}

/// Default implementation of base feedback handler configuration
class DefaultFeedbackHandlerConfig extends FeedbackHandlerConfig {
  /// Background colors per feedback type
  final Map<FeedbackType, Color?> backgroundColors;

  /// Icons per feedback type
  final Map<FeedbackType, IconData?> icons;

  /// Icon colors per feedback type
  final Map<FeedbackType, Color?> iconColors;

  /// Text colors per feedback type
  final Map<FeedbackType, Color?> textColors;

  /// Default durations per feedback type
  final Map<FeedbackType, Duration?> defaultDurations;

  /// Semantics configuration
  final FeedbackSemanticsConfig? semanticsConfig;

  /// Default constructor with standard values
  const DefaultFeedbackHandlerConfig({
    this.backgroundColors = const {},
    this.icons = const {},
    this.iconColors = const {},
    this.textColors = const {},
    this.defaultDurations = const {},
    this.semanticsConfig,
  });

  /// Create with default values matching current handler behavior
  factory DefaultFeedbackHandlerConfig.defaults() {
    return const DefaultFeedbackHandlerConfig(
      // No hardcoded colors - all colors derived from theme
      backgroundColors: {},
      icons: {
        FeedbackType.success: Icons.check_circle,
        FeedbackType.error: Icons.error_outline,
        FeedbackType.warning: Icons.warning_amber,
        FeedbackType.info: Icons.info_outline,
      },
      // No hardcoded colors - all colors derived from theme
      iconColors: {},
      // No hardcoded colors - all colors derived from theme
      textColors: {},
      defaultDurations: {
        FeedbackType.success: Duration(seconds: 3),
        FeedbackType.error: Duration(seconds: 4),
        FeedbackType.warning: Duration(seconds: 3),
        FeedbackType.info: Duration(seconds: 3),
      },
    );
  }

  @override
  Color? getBackgroundColor(FeedbackType type, ColorScheme colorScheme) {
    final color = backgroundColors[type];
    if (color != null) return color;
    // All colors derived from theme
    switch (type) {
      case FeedbackType.success:
        return colorScheme.primary;
      case FeedbackType.error:
        return colorScheme.error;
      case FeedbackType.warning:
        return colorScheme.tertiary;
      case FeedbackType.info:
        return colorScheme.secondary;
    }
  }

  @override
  IconData? getIcon(FeedbackType type) {
    return icons[type];
  }

  @override
  Color? getIconColor(FeedbackType type, ColorScheme colorScheme) {
    final color = iconColors[type];
    if (color != null) return color;
    // Use on* colors based on background color
    switch (type) {
      case FeedbackType.success:
        return colorScheme.onPrimary;
      case FeedbackType.error:
        return colorScheme.onError;
      case FeedbackType.warning:
        return colorScheme.onTertiary;
      case FeedbackType.info:
        return colorScheme.onSecondary;
    }
  }

  @override
  Color? getTextColor(FeedbackType type, ColorScheme colorScheme) {
    final color = textColors[type];
    if (color != null) return color;
    // Use on* colors based on background color
    switch (type) {
      case FeedbackType.success:
        return colorScheme.onPrimary;
      case FeedbackType.error:
        return colorScheme.onError;
      case FeedbackType.warning:
        return colorScheme.onTertiary;
      case FeedbackType.info:
        return colorScheme.onSecondary;
    }
  }

  @override
  Duration? getDefaultDuration(FeedbackType type) {
    return defaultDurations[type];
  }

  @override
  DefaultFeedbackHandlerConfig copyWith({
    Map<FeedbackType, Color?>? backgroundColors,
    Map<FeedbackType, IconData?>? icons,
    Map<FeedbackType, Color?>? iconColors,
    Map<FeedbackType, Color?>? textColors,
    Map<FeedbackType, Duration?>? defaultDurations,
    FeedbackSemanticsConfig? semanticsConfig,
  }) {
    return DefaultFeedbackHandlerConfig(
      backgroundColors: backgroundColors ?? this.backgroundColors,
      icons: icons ?? this.icons,
      iconColors: iconColors ?? this.iconColors,
      textColors: textColors ?? this.textColors,
      defaultDurations: defaultDurations ?? this.defaultDurations,
      semanticsConfig: semanticsConfig ?? this.semanticsConfig,
    );
  }

  @override
  DefaultFeedbackHandlerConfig merge(FeedbackHandlerConfig? other) {
    if (other == null) return this;
    if (other is! DefaultFeedbackHandlerConfig) return this;

    return DefaultFeedbackHandlerConfig(
      backgroundColors: {...backgroundColors, ...other.backgroundColors},
      icons: {...icons, ...other.icons},
      iconColors: {...iconColors, ...other.iconColors},
      textColors: {...textColors, ...other.textColors},
      defaultDurations: {...defaultDurations, ...other.defaultDurations},
      semanticsConfig: other.semanticsConfig ?? semanticsConfig,
    );
  }
}

