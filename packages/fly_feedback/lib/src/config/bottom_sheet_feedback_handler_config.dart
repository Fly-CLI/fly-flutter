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
  ///
  /// Deprecated: Use [queueConfig] instead. This property is kept for
  /// backward compatibility and will be removed in a future version.
  @Deprecated('Use queueConfig.queueRetryDelay instead')
  final Duration? queueRetryDelay;

  /// Max queue wait time
  ///
  /// Deprecated: Use [queueConfig] instead. This property is kept for
  /// backward compatibility and will be removed in a future version.
  @Deprecated('Use queueConfig.maxQueueWait instead')
  final Duration? maxQueueWait;

  /// Queue configuration for bottom sheet queue management
  final FeedbackQueueConfig? queueConfig;

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
    super.hapticConfig,
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
    this.queueConfig,
    this.buttonVerticalPadding,
  });

  /// Create with default values matching current bottom sheet handler behavior
  factory BottomSheetFeedbackHandlerConfig.defaults() {
    return BottomSheetFeedbackHandlerConfig(
      // No hardcoded colors - all colors derived from theme
      backgroundColors: const {},
      icons: const {
        FeedbackType.success: Icons.check_circle,
        FeedbackType.error: Icons.error_outline,
        FeedbackType.warning: Icons.warning_amber,
        FeedbackType.info: Icons.info_outline,
      },
      // No hardcoded colors - all colors derived from theme
      iconColors: const {},
      // No hardcoded colors - all colors derived from theme
      textColors: const {},
      iconSize: 24.0,
      borderRadius: 20.0,
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      handleBarWidth: 40.0,
      handleBarHeight: 4.0,
      handleBarMarginBottom: 16.0,
      // No hardcoded handle bar color - use theme outline
      handleBarColor: null,
      useSafeArea: true,
      queueRetryDelay: const Duration(milliseconds: 300),
      maxQueueWait: const Duration(seconds: 5),
      queueConfig: FeedbackQueueConfig.defaults(),
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
    HapticConfig? hapticConfig,
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
    FeedbackQueueConfig? queueConfig,
    double? buttonVerticalPadding,
  }) {
    return BottomSheetFeedbackHandlerConfig(
      backgroundColors: backgroundColors ?? this.backgroundColors,
      icons: icons ?? this.icons,
      iconColors: iconColors ?? this.iconColors,
      textColors: textColors ?? this.textColors,
      defaultDurations: defaultDurations ?? this.defaultDurations,
      semanticsConfig: semanticsConfig ?? this.semanticsConfig,
      hapticConfig: hapticConfig ?? this.hapticConfig,
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
      queueConfig: queueConfig ?? this.queueConfig,
      buttonVerticalPadding: buttonVerticalPadding ?? this.buttonVerticalPadding,
    );
  }

  @override
  BottomSheetFeedbackHandlerConfig merge(FeedbackHandlerConfig? other) {
    if (other == null) return this;
    if (other is! DefaultFeedbackHandlerConfig) return this;
    
    if (other is BottomSheetFeedbackHandlerConfig) {
      // Handle queue config merging
      FeedbackQueueConfig? mergedQueueConfig = queueConfig;
      if (other.queueConfig != null) {
        mergedQueueConfig = queueConfig?.merge(other.queueConfig) ?? other.queueConfig;
      }
      
      return BottomSheetFeedbackHandlerConfig(
        backgroundColors: {...backgroundColors, ...other.backgroundColors},
        icons: {...icons, ...other.icons},
        iconColors: {...iconColors, ...other.iconColors},
        textColors: {...textColors, ...other.textColors},
        defaultDurations: {...defaultDurations, ...other.defaultDurations},
        semanticsConfig: other.semanticsConfig ?? semanticsConfig,
        hapticConfig: other.hapticConfig ?? hapticConfig,
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
        queueConfig: mergedQueueConfig,
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
      hapticConfig: other.hapticConfig ?? hapticConfig,
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

