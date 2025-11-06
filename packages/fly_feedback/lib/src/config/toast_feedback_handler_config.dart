import 'package:flutter/material.dart';
import 'package:fly_feedback/fly_feedback.dart';

/// Configuration for toast feedback handler
class ToastFeedbackHandlerConfig extends DefaultFeedbackHandlerConfig {
  /// Icon size
  final double? iconSize;

  /// Top offset from safe area
  final double? topOffset;

  /// Horizontal padding
  final double? horizontalPadding;

  /// Vertical padding
  final double? verticalPadding;

  /// Border radius
  final double? borderRadius;

  /// Animation duration
  final Duration? animationDuration;

  /// Animation curve
  final Curve? animationCurve;

  /// Slide animation begin offset
  final Offset? slideBeginOffset;

  /// Shadow color
  final Color? shadowColor;

  /// Shadow blur radius
  final double? shadowBlurRadius;

  /// Shadow offset
  final Offset? shadowOffset;

  /// Font size
  final double? fontSize;

  /// Default constructor
  const ToastFeedbackHandlerConfig({
    super.backgroundColors,
    super.icons,
    super.iconColors,
    super.textColors,
    super.defaultDurations,
    super.semanticsConfig,
    this.iconSize,
    this.topOffset,
    this.horizontalPadding,
    this.verticalPadding,
    this.borderRadius,
    this.animationDuration,
    this.animationCurve,
    this.slideBeginOffset,
    this.shadowColor,
    this.shadowBlurRadius,
    this.shadowOffset,
    this.fontSize,
  });

  /// Create with default values matching current toast handler behavior
  factory ToastFeedbackHandlerConfig.defaults() {
    return const ToastFeedbackHandlerConfig(
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
        FeedbackType.success: Duration(seconds: 2),
        FeedbackType.error: Duration(seconds: 3),
        FeedbackType.warning: Duration(seconds: 2),
        FeedbackType.info: Duration(seconds: 2),
      },
      iconSize: 20.0,
      topOffset: 16.0,
      horizontalPadding: 16.0,
      verticalPadding: 12.0,
      borderRadius: 8.0,
      animationDuration: Duration(milliseconds: 300),
      animationCurve: Curves.easeOut,
      slideBeginOffset: Offset(0, -1),
      // No hardcoded shadow color - use theme shadow
      shadowColor: null,
      shadowBlurRadius: 8.0,
      shadowOffset: Offset(0, 2),
      fontSize: 14.0,
    );
  }

  @override
  ToastFeedbackHandlerConfig copyWith({
    Map<FeedbackType, Color?>? backgroundColors,
    Map<FeedbackType, IconData?>? icons,
    Map<FeedbackType, Color?>? iconColors,
    Map<FeedbackType, Color?>? textColors,
    Map<FeedbackType, Duration?>? defaultDurations,
    FeedbackSemanticsConfig? semanticsConfig,
    double? iconSize,
    double? topOffset,
    double? horizontalPadding,
    double? verticalPadding,
    double? borderRadius,
    Duration? animationDuration,
    Curve? animationCurve,
    Offset? slideBeginOffset,
    Color? shadowColor,
    double? shadowBlurRadius,
    Offset? shadowOffset,
    double? fontSize,
  }) {
    return ToastFeedbackHandlerConfig(
      backgroundColors: backgroundColors ?? this.backgroundColors,
      icons: icons ?? this.icons,
      iconColors: iconColors ?? this.iconColors,
      textColors: textColors ?? this.textColors,
      defaultDurations: defaultDurations ?? this.defaultDurations,
      semanticsConfig: semanticsConfig ?? this.semanticsConfig,
      iconSize: iconSize ?? this.iconSize,
      topOffset: topOffset ?? this.topOffset,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
      verticalPadding: verticalPadding ?? this.verticalPadding,
      borderRadius: borderRadius ?? this.borderRadius,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      slideBeginOffset: slideBeginOffset ?? this.slideBeginOffset,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      shadowOffset: shadowOffset ?? this.shadowOffset,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  @override
  ToastFeedbackHandlerConfig merge(FeedbackHandlerConfig? other) {
    if (other == null) return this;
    if (other is! DefaultFeedbackHandlerConfig) return this;
    
    if (other is ToastFeedbackHandlerConfig) {
      return ToastFeedbackHandlerConfig(
        backgroundColors: {...backgroundColors, ...other.backgroundColors},
        icons: {...icons, ...other.icons},
        iconColors: {...iconColors, ...other.iconColors},
        textColors: {...textColors, ...other.textColors},
        defaultDurations: {...defaultDurations, ...other.defaultDurations},
        semanticsConfig: other.semanticsConfig ?? semanticsConfig,
        iconSize: other.iconSize ?? iconSize,
        topOffset: other.topOffset ?? topOffset,
        horizontalPadding: other.horizontalPadding ?? horizontalPadding,
        verticalPadding: other.verticalPadding ?? verticalPadding,
        borderRadius: other.borderRadius ?? borderRadius,
        animationDuration: other.animationDuration ?? animationDuration,
        animationCurve: other.animationCurve ?? animationCurve,
        slideBeginOffset: other.slideBeginOffset ?? slideBeginOffset,
        shadowColor: other.shadowColor ?? shadowColor,
        shadowBlurRadius: other.shadowBlurRadius ?? shadowBlurRadius,
        shadowOffset: other.shadowOffset ?? shadowOffset,
        fontSize: other.fontSize ?? fontSize,
      );
    }

    // Merge with base config only
    return ToastFeedbackHandlerConfig(
      backgroundColors: {...backgroundColors, ...other.backgroundColors},
      icons: {...icons, ...other.icons},
      iconColors: {...iconColors, ...other.iconColors},
      textColors: {...textColors, ...other.textColors},
      defaultDurations: {...defaultDurations, ...other.defaultDurations},
      semanticsConfig: other.semanticsConfig ?? semanticsConfig,
      iconSize: iconSize,
      topOffset: topOffset,
      horizontalPadding: horizontalPadding,
      verticalPadding: verticalPadding,
      borderRadius: borderRadius,
      animationDuration: animationDuration,
      animationCurve: animationCurve,
      slideBeginOffset: slideBeginOffset,
      shadowColor: shadowColor,
      shadowBlurRadius: shadowBlurRadius,
      shadowOffset: shadowOffset,
      fontSize: fontSize,
    );
  }
}

