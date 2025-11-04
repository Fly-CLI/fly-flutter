import 'package:flutter/foundation.dart';

/// Types of feedback
enum FeedbackType {
  success,
  error,
  warning,
  info,
}

/// Display strategies for feedback
enum FeedbackDisplay {
  snackbar,
  dialog,
  toast,
  banner,
  custom,
}

/// Base feedback event - pure data, no logic
sealed class FeedbackEvent {
  final String id; // Unique ID for tracking
  final String message; // Already localized string from ViewModel
  final FeedbackType type;
  final FeedbackDisplay display;
  final Duration? duration;
  final DateTime timestamp; // For analytics
  final Map<String, dynamic> metadata;

  FeedbackEvent({
    String? id, // Optional for testing
    required this.message,
    required this.type,
    this.display = FeedbackDisplay.snackbar,
    this.duration,
    DateTime? timestamp, // Optional for testing
    this.metadata = const {},
  })  : id = id ?? generateId(),
        timestamp = timestamp ?? DateTime.now();

  // Note: id generation moved to factory to support const constructors
  static String generateId() {
    return 'feedback_${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}';
  }

  static int _idCounter = 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedbackEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Success feedback
class SuccessFeedback extends FeedbackEvent {
  final VoidCallback? action;
  final String? actionLabel;

  SuccessFeedback(
    String message, {
    super.id,
    super.display = FeedbackDisplay.snackbar,
    super.duration,
    this.action,
    this.actionLabel,
    super.timestamp,
    super.metadata = const {},
  }) : super(
          message: message,
          type: FeedbackType.success,
        );
}

/// Error feedback
class ErrorFeedback extends FeedbackEvent {
  final String? technicalDetails;
  final VoidCallback? retryAction;
  final bool showTechnicalDetails; // Control detail visibility

  ErrorFeedback(
    String message, {
    super.id,
    this.technicalDetails,
    this.retryAction,
    this.showTechnicalDetails = false, // Hidden by default
    super.display = FeedbackDisplay.snackbar,
    super.duration,
    super.timestamp,
    super.metadata = const {},
  }) : super(
          message: message,
          type: FeedbackType.error,
        );
}

/// Warning feedback
class WarningFeedback extends FeedbackEvent {
  WarningFeedback(
    String message, {
    super.id,
    super.display = FeedbackDisplay.snackbar,
    super.duration,
    super.timestamp,
    super.metadata = const {},
  }) : super(
          message: message,
          type: FeedbackType.warning,
        );
}

/// Info feedback
class InfoFeedback extends FeedbackEvent {
  InfoFeedback(
    String message, {
    super.id,
    super.display = FeedbackDisplay.snackbar,
    super.duration,
    super.timestamp,
    super.metadata = const {},
  }) : super(
          message: message,
          type: FeedbackType.info,
        );
}

/// Confirmation dialog feedback
class ConfirmationFeedback extends FeedbackEvent {
  final String title;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDangerous;
  final bool barrierDismissible; // Control dialog dismissal

  ConfirmationFeedback({
    super.id,
    required this.title,
    required super.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.isDangerous = false,
    this.barrierDismissible = true, // Default dismissible
    super.timestamp,
    super.metadata = const {},
  }) : super(
          type: FeedbackType.info,
          display: FeedbackDisplay.dialog,
        );
}

