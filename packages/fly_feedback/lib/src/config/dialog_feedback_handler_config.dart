import 'package:flutter/material.dart';
import 'package:fly_feedback/fly_feedback.dart';

/// Configuration for dialog feedback handler
class DialogFeedbackHandlerConfig extends DefaultFeedbackHandlerConfig {
  /// Queue configuration for dialog queue management
  final FeedbackQueueConfig? queueConfig;

  /// Default constructor
  const DialogFeedbackHandlerConfig({
    super.backgroundColors,
    super.icons,
    super.iconColors,
    super.textColors,
    super.defaultDurations,
    super.semanticsConfig,
    super.hapticConfig,
    this.queueConfig,
  });

  /// Create with default values matching current dialog handler behavior
  factory DialogFeedbackHandlerConfig.defaults() {
    return DialogFeedbackHandlerConfig(
      queueConfig: FeedbackQueueConfig.defaults(),
    );
  }

  @override
  DialogFeedbackHandlerConfig copyWith({
    Map<FeedbackType, Color?>? backgroundColors,
    Map<FeedbackType, IconData?>? icons,
    Map<FeedbackType, Color?>? iconColors,
    Map<FeedbackType, Color?>? textColors,
    Map<FeedbackType, Duration?>? defaultDurations,
    FeedbackSemanticsConfig? semanticsConfig,
    HapticConfig? hapticConfig,
    FeedbackQueueConfig? queueConfig,
  }) {
    return DialogFeedbackHandlerConfig(
      backgroundColors: backgroundColors ?? this.backgroundColors,
      icons: icons ?? this.icons,
      iconColors: iconColors ?? this.iconColors,
      textColors: textColors ?? this.textColors,
      defaultDurations: defaultDurations ?? this.defaultDurations,
      semanticsConfig: semanticsConfig ?? this.semanticsConfig,
      hapticConfig: hapticConfig ?? this.hapticConfig,
      queueConfig: queueConfig ?? this.queueConfig,
    );
  }

  @override
  DialogFeedbackHandlerConfig merge(FeedbackHandlerConfig? other) {
    if (other == null) return this;
    if (other is! DefaultFeedbackHandlerConfig) return this;
    
    // Handle queue config merging if other is DialogFeedbackHandlerConfig
    FeedbackQueueConfig? mergedQueueConfig = queueConfig;
    if (other is DialogFeedbackHandlerConfig && other.queueConfig != null) {
      mergedQueueConfig = queueConfig?.merge(other.queueConfig) ?? other.queueConfig;
    }
    
    return DialogFeedbackHandlerConfig(
      backgroundColors: {...backgroundColors, ...other.backgroundColors},
      icons: {...icons, ...other.icons},
      iconColors: {...iconColors, ...other.iconColors},
      textColors: {...textColors, ...other.textColors},
      defaultDurations: {...defaultDurations, ...other.defaultDurations},
      semanticsConfig: other.semanticsConfig ?? semanticsConfig,
      hapticConfig: other.hapticConfig ?? hapticConfig,
      queueConfig: mergedQueueConfig,
    );
  }
}


