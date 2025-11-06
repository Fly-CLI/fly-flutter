import 'package:flutter/material.dart';
import 'package:fly_feedback/src/handlers/fly_feedback_handler.dart';
import 'package:fly_feedback/src/service/feedback_service.dart';
import 'package:fly_feedback/src/events/feedback_event.dart';
import 'package:fly_feedback/src/types/feedback_types.dart';

/// Default implementation of FeedbackService using standard feedback handlers
///
/// This implementation uses a composite feedback handler to perform feedback
/// operations with standard Flutter widgets (SnackBar, Dialog).
///
/// Example usage:
/// ```dart
/// final service = DefaultFeedbackService(
///   handler: CompositeFeedbackHandler([
///     SnackbarFeedbackHandler(),
///     DialogFeedbackHandler(),
///   ]),
/// );
/// service.showSuccess(context, 'Saved!');
/// ```
class DefaultFeedbackService implements FeedbackService<FeedbackEvent> {
  /// The feedback handler to use for displaying feedback
  final FlyFeedbackHandler handler;

  /// Creates a DefaultFeedbackService
  ///
  /// [handler] - The feedback handler to use for displaying feedback
  DefaultFeedbackService({required this.handler});

  @override
  void show(BuildContext context, FeedbackEvent feedback) {
    handler.handle(context, feedback);
  }

  @override
  void showSuccess(
    BuildContext context,
    String message, {
    FeedbackDisplay display = FeedbackDisplay.snackBar,
    Duration? duration,
    VoidCallback? action,
    String? actionLabel,
    Map<String, dynamic> metadata = const {},
  }) {
    final feedback = SuccessFeedback(
      message,
      display: display,
      duration: duration,
      action: action,
      actionLabel: actionLabel,
      metadata: metadata,
    );

    show(context, feedback);
  }

  @override
  void showError(
    BuildContext context,
    String message, {
    String? technicalDetails,
    VoidCallback? retryAction,
    String? retryLabel,
    bool showTechnicalDetails = false,
    FeedbackDisplay display = FeedbackDisplay.snackBar,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    final feedback = ErrorFeedback(
      message,
      technicalDetails: technicalDetails,
      retryAction: retryAction,
      retryLabel: retryLabel,
      showTechnicalDetails: showTechnicalDetails,
      display: display,
      duration: duration,
      metadata: metadata,
    );

    show(context, feedback);
  }

  @override
  void showWarning(
    BuildContext context,
    String message, {
    FeedbackDisplay display = FeedbackDisplay.snackBar,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    final feedback = WarningFeedback(
      message,
      display: display,
      duration: duration,
      metadata: metadata,
    );

    show(context, feedback);
  }

  @override
  void showInfo(
    BuildContext context,
    String message, {
    FeedbackDisplay display = FeedbackDisplay.snackBar,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    final feedback = InfoFeedback(
      message,
      display: display,
      duration: duration,
      metadata: metadata,
    );

    show(context, feedback);
  }

  @override
  void showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDangerous = false,
    bool barrierDismissible = true,
    Map<String, dynamic> metadata = const {},
  }) {
    final feedback = ConfirmationFeedback(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: onConfirm,
      onCancel: onCancel,
      isDangerous: isDangerous,
      barrierDismissible: barrierDismissible,
      metadata: metadata,
    );

    show(context, feedback);
  }
}

