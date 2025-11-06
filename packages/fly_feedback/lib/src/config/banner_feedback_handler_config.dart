import 'package:flutter/material.dart';
import 'package:fly_feedback/fly_feedback.dart';

/// Configuration for banner feedback handler
class BannerFeedbackHandlerConfig extends DefaultFeedbackHandlerConfig {
  /// Icon size
  final double? iconSize;

  /// Leading padding
  final EdgeInsets? leadingPadding;

  /// Content padding
  final EdgeInsets? padding;

  /// Default constructor
  const BannerFeedbackHandlerConfig({
    super.backgroundColors,
    super.icons,
    super.iconColors,
    super.textColors,
    super.defaultDurations,
    super.semanticsConfig,
    super.hapticConfig,
    this.iconSize,
    this.leadingPadding,
    this.padding,
  });

  /// Create with default values matching current banner handler behavior
  factory BannerFeedbackHandlerConfig.defaults() {
    return const BannerFeedbackHandlerConfig(
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
      iconSize: 24.0,
      leadingPadding: EdgeInsets.only(left: 16),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  BannerFeedbackHandlerConfig copyWith({
    Map<FeedbackType, Color?>? backgroundColors,
    Map<FeedbackType, IconData?>? icons,
    Map<FeedbackType, Color?>? iconColors,
    Map<FeedbackType, Color?>? textColors,
    Map<FeedbackType, Duration?>? defaultDurations,
    FeedbackSemanticsConfig? semanticsConfig,
    HapticConfig? hapticConfig,
    double? iconSize,
    EdgeInsets? leadingPadding,
    EdgeInsets? padding,
  }) {
    return BannerFeedbackHandlerConfig(
      backgroundColors: backgroundColors ?? this.backgroundColors,
      icons: icons ?? this.icons,
      iconColors: iconColors ?? this.iconColors,
      textColors: textColors ?? this.textColors,
      defaultDurations: defaultDurations ?? this.defaultDurations,
      semanticsConfig: semanticsConfig ?? this.semanticsConfig,
      hapticConfig: hapticConfig ?? this.hapticConfig,
      iconSize: iconSize ?? this.iconSize,
      leadingPadding: leadingPadding ?? this.leadingPadding,
      padding: padding ?? this.padding,
    );
  }

  @override
  BannerFeedbackHandlerConfig merge(FeedbackHandlerConfig? other) {
    if (other == null) return this;
    if (other is! DefaultFeedbackHandlerConfig) return this;
    
    if (other is BannerFeedbackHandlerConfig) {
      return BannerFeedbackHandlerConfig(
        backgroundColors: {...backgroundColors, ...other.backgroundColors},
        icons: {...icons, ...other.icons},
        iconColors: {...iconColors, ...other.iconColors},
        textColors: {...textColors, ...other.textColors},
        defaultDurations: {...defaultDurations, ...other.defaultDurations},
        semanticsConfig: other.semanticsConfig ?? semanticsConfig,
        hapticConfig: other.hapticConfig ?? hapticConfig,
        iconSize: other.iconSize ?? iconSize,
        leadingPadding: other.leadingPadding ?? leadingPadding,
        padding: other.padding ?? padding,
      );
    }

    // Merge with base config only
    return BannerFeedbackHandlerConfig(
      backgroundColors: {...backgroundColors, ...other.backgroundColors},
      icons: {...icons, ...other.icons},
      iconColors: {...iconColors, ...other.iconColors},
      textColors: {...textColors, ...other.textColors},
      defaultDurations: {...defaultDurations, ...other.defaultDurations},
      semanticsConfig: other.semanticsConfig ?? semanticsConfig,
      hapticConfig: other.hapticConfig ?? hapticConfig,
      iconSize: iconSize,
      leadingPadding: leadingPadding,
      padding: padding,
    );
  }
}

