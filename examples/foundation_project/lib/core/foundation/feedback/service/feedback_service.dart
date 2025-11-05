import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';
import 'package:foundation_project/core/foundation/feedback/types/feedback_types.dart';

/// Abstract interface for feedback operations with generic feedback types
///
/// [F] - The feedback event type (e.g., FeedbackEvent, CustomFeedback)
///
/// This interface provides feedback-agnostic functionality,
/// allowing projects to use custom feedback types or the default FeedbackEvent
/// by implementing this interface.
///
/// The service accepts BuildContext for displaying feedback via
/// ScaffoldMessenger and dialogs.
///
/// Feedback types must extend FeedbackEvent for handler compatibility.
/// For example:
/// - FeedbackEvent works directly (default)
/// - CustomFeedback extends FeedbackEvent
///
/// Example usage:
/// ```dart
/// // FeedbackEvent-based service (default)
/// FeedbackService<FeedbackEvent> service;
/// service.showSuccess(context, 'Saved!');
///
/// // Custom feedback type
/// FeedbackService<CustomFeedback> service;
/// service.show(context, CustomFeedback.success('Saved!'), ref);
/// ```
abstract class FeedbackService<F extends FeedbackEvent> {
  /// Show feedback event
  ///
  /// [context] - BuildContext for displaying feedback
  /// [feedback] - Feedback event of type F
  /// [ref] - Optional WidgetRef for theme access
  void show(BuildContext context, F feedback, WidgetRef? ref);

  /// Show success feedback (convenience method)
  ///
  /// [context] - BuildContext for displaying feedback
  /// [message] - Success message (already localized)
  /// [display] - Display type (default: snackbar)
  /// [duration] - Optional duration for the feedback
  /// [action] - Optional action callback
  /// [actionLabel] - Optional action button label
  /// [metadata] - Optional metadata
  void showSuccess(
    BuildContext context,
    String message, {
    FeedbackDisplay display = FeedbackDisplay.snackBar,
    Duration? duration,
    VoidCallback? action,
    String? actionLabel,
    Map<String, dynamic> metadata = const {},
  });

  /// Show error feedback (convenience method)
  ///
  /// [context] - BuildContext for displaying feedback
  /// [message] - Error message (already localized)
  /// [technicalDetails] - Optional technical error details
  /// [retryAction] - Optional retry callback
  /// [retryLabel] - Optional retry button label
  /// [showTechnicalDetails] - Whether to show technical details
  /// [display] - Display type (default: snackbar)
  /// [duration] - Optional duration for the feedback
  /// [metadata] - Optional metadata
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
  });

  /// Show warning feedback (convenience method)
  ///
  /// [context] - BuildContext for displaying feedback
  /// [message] - Warning message (already localized)
  /// [display] - Display type (default: snackbar)
  /// [duration] - Optional duration for the feedback
  /// [metadata] - Optional metadata
  void showWarning(
    BuildContext context,
    String message, {
    FeedbackDisplay display = FeedbackDisplay.snackBar,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  });

  /// Show info feedback (convenience method)
  ///
  /// [context] - BuildContext for displaying feedback
  /// [message] - Info message (already localized)
  /// [display] - Display type (default: snackbar)
  /// [duration] - Optional duration for the feedback
  /// [metadata] - Optional metadata
  void showInfo(
    BuildContext context,
    String message, {
    FeedbackDisplay display = FeedbackDisplay.snackBar,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  });

  /// Show confirmation dialog (convenience method)
  ///
  /// [context] - BuildContext for displaying feedback
  /// [title] - Dialog title (already localized)
  /// [message] - Dialog message (already localized)
  /// [confirmLabel] - Optional confirm button label
  /// [cancelLabel] - Optional cancel button label
  /// [onConfirm] - Optional confirm callback
  /// [onCancel] - Optional cancel callback
  /// [isDangerous] - Whether this is a dangerous action (red button)
  /// [barrierDismissible] - Whether dialog can be dismissed by tapping outside
  /// [metadata] - Optional metadata
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
  });
}

