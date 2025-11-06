import 'package:flutter/material.dart';
import 'package:fly_feedback/fly_feedback.dart';

/// Configuration for bottom sheet feedback handler
class BottomSheetFeedbackHandlerConfig extends DefaultFeedbackHandlerConfig {
  /// Icon size
  final double? iconSize;

  /// Border radius for top corners
  final double? borderRadius;

  /// Padding for content
  final EdgeInsets? contentPadding;

  /// Handle bar width
  final double? handleBarWidth;

  /// Handle bar height
  final double? handleBarHeight;

  /// Handle bar margin bottom
  final double? handleBarMarginBottom;

  /// Handle bar color
  final Color? handleBarColor;

  /// Use safe area
  final bool? useSafeArea;

  /// Queue retry delay
  final Duration? queueRetryDelay;

  /// Max queue wait time
  final Duration? maxQueueWait;

  /// Button vertical padding
  final double? buttonVerticalPadding;

  /// Default constructor
  const BottomSheetFeedbackHandlerConfig({
    super.backgroundColors,
    super.icons,
    super.iconColors,
    super.textColors,
    super.defaultDurations,
    super.semanticsConfig,
    this.iconSize,
    this.borderRadius,
    this.contentPadding,
    this.handleBarWidth,
    this.handleBarHeight,
    this.handleBarMarginBottom,
    this.handleBarColor,
    this.useSafeArea,
    this.queueRetryDelay,
    this.maxQueueWait,
    this.buttonVerticalPadding,
  });

  /// Create with default values matching current bottom sheet handler behavior
  factory BottomSheetFeedbackHandlerConfig.defaults() {
    return const BottomSheetFeedbackHandlerConfig(
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
      borderRadius: 20.0,
      contentPadding: EdgeInsets.fromLTRB(24, 16, 24, 16),
      handleBarWidth: 40.0,
      handleBarHeight: 4.0,
      handleBarMarginBottom: 16.0,
      // No hardcoded handle bar color - use theme outline
      handleBarColor: null,
      useSafeArea: true,
      queueRetryDelay: Duration(milliseconds: 300),
      maxQueueWait: Duration(seconds: 5),
      buttonVerticalPadding: 16.0,
    );
  }

  @override
  BottomSheetFeedbackHandlerConfig copyWith({
    Map<FeedbackType, Color?>? backgroundColors,
    Map<FeedbackType, IconData?>? icons,
    Map<FeedbackType, Color?>? iconColors,
    Map<FeedbackType, Color?>? textColors,
    Map<FeedbackType, Duration?>? defaultDurations,
    FeedbackSemanticsConfig? semanticsConfig,
    double? iconSize,
    double? borderRadius,
    EdgeInsets? contentPadding,
    double? handleBarWidth,
    double? handleBarHeight,
    double? handleBarMarginBottom,
    Color? handleBarColor,
    bool? useSafeArea,
    Duration? queueRetryDelay,
    Duration? maxQueueWait,
    double? buttonVerticalPadding,
  }) {
    return BottomSheetFeedbackHandlerConfig(
      backgroundColors: backgroundColors ?? this.backgroundColors,
      icons: icons ?? this.icons,
      iconColors: iconColors ?? this.iconColors,
      textColors: textColors ?? this.textColors,
      defaultDurations: defaultDurations ?? this.defaultDurations,
      semanticsConfig: semanticsConfig ?? this.semanticsConfig,
      iconSize: iconSize ?? this.iconSize,
      borderRadius: borderRadius ?? this.borderRadius,
      contentPadding: contentPadding ?? this.contentPadding,
      handleBarWidth: handleBarWidth ?? this.handleBarWidth,
      handleBarHeight: handleBarHeight ?? this.handleBarHeight,
      handleBarMarginBottom: handleBarMarginBottom ?? this.handleBarMarginBottom,
      handleBarColor: handleBarColor ?? this.handleBarColor,
      useSafeArea: useSafeArea ?? this.useSafeArea,
      queueRetryDelay: queueRetryDelay ?? this.queueRetryDelay,
      maxQueueWait: maxQueueWait ?? this.maxQueueWait,
      buttonVerticalPadding: buttonVerticalPadding ?? this.buttonVerticalPadding,
    );
  }

  @override
  BottomSheetFeedbackHandlerConfig merge(FeedbackHandlerConfig? other) {
    if (other == null) return this;
    if (other is! DefaultFeedbackHandlerConfig) return this;
    
    if (other is BottomSheetFeedbackHandlerConfig) {
      return BottomSheetFeedbackHandlerConfig(
        backgroundColors: {...backgroundColors, ...other.backgroundColors},
        icons: {...icons, ...other.icons},
        iconColors: {...iconColors, ...other.iconColors},
        textColors: {...textColors, ...other.textColors},
        defaultDurations: {...defaultDurations, ...other.defaultDurations},
        semanticsConfig: other.semanticsConfig ?? semanticsConfig,
        iconSize: other.iconSize ?? iconSize,
        borderRadius: other.borderRadius ?? borderRadius,
        contentPadding: other.contentPadding ?? contentPadding,
        handleBarWidth: other.handleBarWidth ?? handleBarWidth,
        handleBarHeight: other.handleBarHeight ?? handleBarHeight,
        handleBarMarginBottom: other.handleBarMarginBottom ?? handleBarMarginBottom,
        handleBarColor: other.handleBarColor ?? handleBarColor,
        useSafeArea: other.useSafeArea ?? useSafeArea,
        queueRetryDelay: other.queueRetryDelay ?? queueRetryDelay,
        maxQueueWait: other.maxQueueWait ?? maxQueueWait,
        buttonVerticalPadding: other.buttonVerticalPadding ?? buttonVerticalPadding,
      );
    }

    // Merge with base config only
    return BottomSheetFeedbackHandlerConfig(
      backgroundColors: {...backgroundColors, ...other.backgroundColors},
      icons: {...icons, ...other.icons},
      iconColors: {...iconColors, ...other.iconColors},
      textColors: {...textColors, ...other.textColors},
      defaultDurations: {...defaultDurations, ...other.defaultDurations},
      semanticsConfig: other.semanticsConfig ?? semanticsConfig,
      iconSize: iconSize,
      borderRadius: borderRadius,
      contentPadding: contentPadding,
      handleBarWidth: handleBarWidth,
      handleBarHeight: handleBarHeight,
      handleBarMarginBottom: handleBarMarginBottom,
      handleBarColor: handleBarColor,
      useSafeArea: useSafeArea,
      queueRetryDelay: queueRetryDelay,
      maxQueueWait: maxQueueWait,
      buttonVerticalPadding: buttonVerticalPadding,
    );
  }
}

