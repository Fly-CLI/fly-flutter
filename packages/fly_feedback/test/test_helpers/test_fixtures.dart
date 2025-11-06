import 'package:flutter/material.dart';
import 'package:fly_feedback/fly_feedback.dart';

/// Test fixtures and factory functions for creating test data

/// Common test messages
class TestMessages {
  static const String success = 'Operation completed successfully';
  static const String error = 'An error occurred';
  static const String warning = 'Warning: This action may have consequences';
  static const String info = 'Information: Please note this';
  static const String confirmationTitle = 'Confirm Action';
  static const String confirmationMessage = 'Are you sure you want to proceed?';
}

/// Factory functions for creating test feedback events
class TestFeedbackEvents {
  /// Create a test SuccessFeedback
  static SuccessFeedback createSuccess({
    String? message,
    FeedbackDisplay display = FeedbackDisplay.snackBar,
    Duration? duration,
    VoidCallback? action,
    String? actionLabel,
    Map<String, dynamic> metadata = const {},
  }) {
    return SuccessFeedback(
      message ?? TestMessages.success,
      display: display,
      duration: duration,
      action: action,
      actionLabel: actionLabel,
      metadata: metadata,
    );
  }

  /// Create a test ErrorFeedback
  static ErrorFeedback createError({
    String? message,
    String? technicalDetails,
    VoidCallback? retryAction,
    String? retryLabel,
    bool showTechnicalDetails = false,
    FeedbackDisplay display = FeedbackDisplay.snackBar,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    return ErrorFeedback(
      message ?? TestMessages.error,
      technicalDetails: technicalDetails,
      retryAction: retryAction,
      retryLabel: retryLabel,
      showTechnicalDetails: showTechnicalDetails,
      display: display,
      duration: duration,
      metadata: metadata,
    );
  }

  /// Create a test WarningFeedback
  static WarningFeedback createWarning({
    String? message,
    FeedbackDisplay display = FeedbackDisplay.snackBar,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    return WarningFeedback(
      message ?? TestMessages.warning,
      display: display,
      duration: duration,
      metadata: metadata,
    );
  }

  /// Create a test InfoFeedback
  static InfoFeedback createInfo({
    String? message,
    FeedbackDisplay display = FeedbackDisplay.snackBar,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    return InfoFeedback(
      message ?? TestMessages.info,
      display: display,
      duration: duration,
      metadata: metadata,
    );
  }

  /// Create a test ConfirmationFeedback
  static ConfirmationFeedback createConfirmation({
    String? title,
    String? message,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDangerous = false,
    bool barrierDismissible = true,
    Map<String, dynamic> metadata = const {},
  }) {
    return ConfirmationFeedback(
      title: title ?? TestMessages.confirmationTitle,
      message: message ?? TestMessages.confirmationMessage,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: onConfirm,
      onCancel: onCancel,
      isDangerous: isDangerous,
      barrierDismissible: barrierDismissible,
      metadata: metadata,
    );
  }
}

/// Factory functions for creating test configs
class TestConfigs {
  /// Create a test FeedbackQueueConfig
  static FeedbackQueueConfig createQueueConfig({
    Duration? queueRetryDelay,
    Duration? maxQueueWait,
    int? maxQueueSize,
    bool? enablePrioritySorting,
    bool? enableDuplicatePrevention,
    bool? enableStaleItemRemoval,
    bool? enableContextValidation,
    Map<FeedbackType, FeedbackPriority>? priorityMapping,
    void Function(FeedbackEvent)? onItemDropped,
    void Function(FeedbackEvent)? onStaleItemRemoved,
  }) {
    return FeedbackQueueConfig(
      queueRetryDelay: queueRetryDelay,
      maxQueueWait: maxQueueWait,
      maxQueueSize: maxQueueSize,
      enablePrioritySorting: enablePrioritySorting,
      enableDuplicatePrevention: enableDuplicatePrevention,
      enableStaleItemRemoval: enableStaleItemRemoval,
      enableContextValidation: enableContextValidation,
      priorityMapping: priorityMapping,
      onItemDropped: onItemDropped,
      onStaleItemRemoved: onStaleItemRemoved,
    );
  }

  /// Create a test SnackbarFeedbackHandlerConfig
  static SnackbarFeedbackHandlerConfig createSnackbarConfig({
    Map<FeedbackType, Color?>? backgroundColors,
    Map<FeedbackType, IconData?>? icons,
    Map<FeedbackType, Color?>? iconColors,
    Map<FeedbackType, Color?>? textColors,
    Map<FeedbackType, Duration?>? defaultDurations,
    FeedbackSemanticsConfig? semanticsConfig,
    double? iconSize,
    SnackBarBehavior? behavior,
  }) {
    return SnackbarFeedbackHandlerConfig(
      backgroundColors: backgroundColors ?? const {},
      icons: icons ?? const {},
      iconColors: iconColors ?? const {},
      textColors: textColors ?? const {},
      defaultDurations: defaultDurations ?? const {},
      semanticsConfig: semanticsConfig,
      iconSize: iconSize,
      behavior: behavior,
    );
  }
}

/// Common test durations
class TestDurations {
  static const Duration short = Duration(seconds: 1);
  static const Duration medium = Duration(seconds: 3);
  static const Duration long = Duration(seconds: 5);
  static const Duration veryLong = Duration(seconds: 10);
}
