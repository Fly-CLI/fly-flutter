import 'package:flutter/material.dart';
import 'package:fly_feedback/fly_feedback.dart';

/// Configuration for dialog feedback handler
class DialogFeedbackHandlerConfig extends DefaultFeedbackHandlerConfig {
  /// Default constructor
  const DialogFeedbackHandlerConfig({
    super.backgroundColors,
    super.icons,
    super.iconColors,
    super.textColors,
    super.defaultDurations,
    super.semanticsConfig,
  });

  /// Create with default values matching current dialog handler behavior
  factory DialogFeedbackHandlerConfig.defaults() {
    return const DialogFeedbackHandlerConfig();
  }

  @override
  DialogFeedbackHandlerConfig copyWith({
    Map<FeedbackType, Color?>? backgroundColors,
    Map<FeedbackType, IconData?>? icons,
    Map<FeedbackType, Color?>? iconColors,
    Map<FeedbackType, Color?>? textColors,
    Map<FeedbackType, Duration?>? defaultDurations,
    FeedbackSemanticsConfig? semanticsConfig,
  }) {
    return DialogFeedbackHandlerConfig(
      backgroundColors: backgroundColors ?? this.backgroundColors,
      icons: icons ?? this.icons,
      iconColors: iconColors ?? this.iconColors,
      textColors: textColors ?? this.textColors,
      defaultDurations: defaultDurations ?? this.defaultDurations,
      semanticsConfig: semanticsConfig ?? this.semanticsConfig,
    );
  }

  @override
  DialogFeedbackHandlerConfig merge(FeedbackHandlerConfig? other) {
    if (other == null) return this;
    if (other is! DefaultFeedbackHandlerConfig) return this;
    
    return DialogFeedbackHandlerConfig(
      backgroundColors: {...backgroundColors, ...other.backgroundColors},
      icons: {...icons, ...other.icons},
      iconColors: {...iconColors, ...other.iconColors},
      textColors: {...textColors, ...other.textColors},
      defaultDurations: {...defaultDurations, ...other.defaultDurations},
      semanticsConfig: other.semanticsConfig ?? semanticsConfig,
    );
  }
}

