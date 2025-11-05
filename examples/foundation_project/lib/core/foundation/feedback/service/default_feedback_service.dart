import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/fly_feedback_handler.dart';
import 'package:foundation_project/core/foundation/feedback/service/feedback_service.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';
import 'package:foundation_project/core/foundation/feedback/types/feedback_types.dart';

/// Default implementation of FeedbackService using standard feedback handlers
///
/// This implementation uses a composite feedback handler to perform feedback
/// operations with standard Flutter widgets (SnackBar, Dialog).
///
/// Example usage:
/// ```dart
/// final service = DefaultFeedbackService<FeedbackEvent>(
///   handler: CompositeFeedbackHandler([
///     SnackbarFeedbackHandler(),
///     DialogFeedbackHandler(),
///   ]),
/// );
/// service.showSuccess(context, 'Saved!');
/// ```
class DefaultFeedbackService<F extends FeedbackEvent>
    implements FeedbackService<F> {
  /// The feedback handler to use for displaying feedback
  final FlyFeedbackHandler handler;

  /// Creates a DefaultFeedbackService
  ///
  /// [handler] - The feedback handler to use for displaying feedback
  DefaultFeedbackService({required this.handler});

  @override
  void show(BuildContext context, F feedback, WidgetRef? ref) {
    // Convert F to FeedbackEvent for handler compatibility
    // Since F extends FeedbackEvent, we can pass it directly
    handler.handle(context, feedback, ref);
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
    // Construct SuccessFeedback and cast to F
    // Note: This assumes F can be SuccessFeedback, which is true for default case
    // For custom F types, users should use show() directly with their custom types
    final feedback = SuccessFeedback(
      message,
      display: display,
      duration: duration,
      action: action,
      actionLabel: actionLabel,
      metadata: metadata,
    ) as F;

    show(context, feedback, null);
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
    ) as F;

    show(context, feedback, null);
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
    ) as F;

    show(context, feedback, null);
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
    ) as F;

    show(context, feedback, null);
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
    ) as F;

    show(context, feedback, null);
  }
}

