import 'package:flutter/foundation.dart';
import 'package:fly_feedback/src/types/feedback_types.dart';

/// Base feedback event - pure data, no logic
///
/// This class is abstract (not sealed) to allow custom feedback types
/// to be created in other libraries, enabling the generic FeedbackService<F>
/// pattern to work with custom feedback implementations.
abstract class FeedbackEvent {

  FeedbackEvent({
    String? id,
    DateTime? timestamp,
    this.metadata = const {},
    required this.message,
    required this.type,
    this.display = FeedbackDisplay.snackBar,
    this.duration,
    this.title,
    this.okLabel,
  })  : id = id ?? _generateId(),
        timestamp = timestamp ?? DateTime.now();
  /// Unique identifier for this event
  final String id;

  /// Timestamp when the event occurred
  final DateTime timestamp;

  /// Additional metadata for the event
  final Map<String, dynamic> metadata;

  /// Feedback message (already localized)
  final String message;

  /// Type of feedback
  final FeedbackType type;

  /// Display strategy for this feedback
  final FeedbackDisplay display;

  /// Optional duration for the feedback
  final Duration? duration;

  /// Optional title for dialog display
  final String? title;

  /// Optional OK button label for alert dialogs
  final String? okLabel;

  /// Generate a unique ID for the event
  static String _generateId() {
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

  SuccessFeedback(
    String message, {
    super.id,
    super.display = FeedbackDisplay.snackBar,
    super.duration,
    this.action,
    this.actionLabel,
    super.timestamp,
    super.metadata = const {},
  }) : super(
          message: message,
          type: FeedbackType.success,
        );
  final VoidCallback? action;
  final String? actionLabel;
}

/// Error feedback
class ErrorFeedback extends FeedbackEvent {

  ErrorFeedback(
    String message, {
    super.id,
    this.technicalDetails,
    this.retryAction,
    this.retryLabel,
    this.showTechnicalDetails = false,
    super.display = FeedbackDisplay.snackBar,
    super.duration,
    super.timestamp,
    super.metadata = const {},
  }) : super(
          message: message,
          type: FeedbackType.error,
        );
  final String? technicalDetails;
  final VoidCallback? retryAction;
  final String? retryLabel;
  final bool showTechnicalDetails;
}

/// Warning feedback
class WarningFeedback extends FeedbackEvent {
  WarningFeedback(
    String message, {
    super.id,
    super.display = FeedbackDisplay.snackBar,
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
    super.display = FeedbackDisplay.snackBar,
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

  ConfirmationFeedback({
    super.id,
    required String title,
    required super.message,
    this.confirmLabel,
    this.cancelLabel,
    this.onConfirm,
    this.onCancel,
    this.isDangerous = false,
    this.barrierDismissible = true,
    super.timestamp,
    super.metadata = const {},
  }) : super(
          type: FeedbackType.info,
          display: FeedbackDisplay.dialog,
          title: title,
        );
  final String? confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDangerous;
  final bool barrierDismissible;
}

