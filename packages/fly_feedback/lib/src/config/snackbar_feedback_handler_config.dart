import 'package:flutter/material.dart';
import 'package:fly_feedback/fly_feedback.dart';

/// Configuration for snackbar feedback handler
class SnackbarFeedbackHandlerConfig extends DefaultFeedbackHandlerConfig {
  /// Icon size
  final double? iconSize;

  /// Snackbar behavior
  final SnackBarBehavior? behavior;

  /// Default constructor
  const SnackbarFeedbackHandlerConfig({
    super.backgroundColors,
    super.icons,
    super.iconColors,
    super.textColors,
    super.defaultDurations,
    super.semanticsConfig,
    super.hapticConfig,
    this.iconSize,
    this.behavior,
  });

  /// Create with default values matching current snackbar handler behavior
  factory SnackbarFeedbackHandlerConfig.defaults() {
    return const SnackbarFeedbackHandlerConfig(
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
      iconSize: 20.0,
      behavior: SnackBarBehavior.floating,
    );
  }

  @override
  SnackbarFeedbackHandlerConfig copyWith({
    Map<FeedbackType, Color?>? backgroundColors,
    Map<FeedbackType, IconData?>? icons,
    Map<FeedbackType, Color?>? iconColors,
    Map<FeedbackType, Color?>? textColors,
    Map<FeedbackType, Duration?>? defaultDurations,
    FeedbackSemanticsConfig? semanticsConfig,
    HapticConfig? hapticConfig,
    double? iconSize,
    SnackBarBehavior? behavior,
  }) {
    return SnackbarFeedbackHandlerConfig(
      backgroundColors: backgroundColors ?? this.backgroundColors,
      icons: icons ?? this.icons,
      iconColors: iconColors ?? this.iconColors,
      textColors: textColors ?? this.textColors,
      defaultDurations: defaultDurations ?? this.defaultDurations,
      semanticsConfig: semanticsConfig ?? this.semanticsConfig,
      hapticConfig: hapticConfig ?? this.hapticConfig,
      iconSize: iconSize ?? this.iconSize,
      behavior: behavior ?? this.behavior,
    );
  }

  @override
  SnackbarFeedbackHandlerConfig merge(FeedbackHandlerConfig? other) {
    if (other == null) return this;
    if (other is! DefaultFeedbackHandlerConfig) return this;
    
    if (other is SnackbarFeedbackHandlerConfig) {
      return SnackbarFeedbackHandlerConfig(
        backgroundColors: {...backgroundColors, ...other.backgroundColors},
        icons: {...icons, ...other.icons},
        iconColors: {...iconColors, ...other.iconColors},
        textColors: {...textColors, ...other.textColors},
        defaultDurations: {...defaultDurations, ...other.defaultDurations},
        semanticsConfig: other.semanticsConfig ?? semanticsConfig,
        hapticConfig: other.hapticConfig ?? hapticConfig,
        iconSize: other.iconSize ?? iconSize,
        behavior: other.behavior ?? behavior,
      );
    }

    // Merge with base config only
    return SnackbarFeedbackHandlerConfig(
      backgroundColors: {...backgroundColors, ...other.backgroundColors},
      icons: {...icons, ...other.icons},
      iconColors: {...iconColors, ...other.iconColors},
      textColors: {...textColors, ...other.textColors},
      defaultDurations: {...defaultDurations, ...other.defaultDurations},
      semanticsConfig: other.semanticsConfig ?? semanticsConfig,
      hapticConfig: other.hapticConfig ?? hapticConfig,
      iconSize: iconSize,
      behavior: behavior,
    );
  }
}

