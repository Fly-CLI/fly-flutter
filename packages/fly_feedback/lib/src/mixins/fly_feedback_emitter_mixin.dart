import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fly_feedback/src/types/feedback_types.dart';
import 'package:fly_feedback/src/events/feedback_event.dart';

/// Mixin to add feedback emission capability to any class
///
/// **Thread Safety:** This mixin is designed for single-threaded Flutter
/// main isolate usage. Event emission should only be called from the main isolate.
///
/// **Lifecycle:** This mixin provides a standalone stream controller for feedback events.
/// Call `disposeFeedbackEmitter()` when the object is disposed to clean up resources.
///
/// **Note:** This mixin emits feedback to a stream for listeners to consume.
/// For direct feedback display with BuildContext, use FeedbackService directly.
///
/// Example:
/// ```dart
/// class MyService with FlyFeedbackEmitterMixin {
///   Future<void> doWork() async {
///     emitSuccess('Work completed!');
///   }
///
///   void dispose() {
///     disposeFeedbackEmitter();
///   }
/// }
/// ```
mixin FlyFeedbackEmitterMixin {
  StreamController<FeedbackEvent>? _feedbackController;
  bool _isDisposed = false;

  /// Stream of feedback events
  ///
  /// Returns a broadcast stream of feedback events.
  /// Returns an empty stream if the emitter is disposed.
  Stream<FeedbackEvent> get feedbackStream {
    if (_isDisposed) {
      debugPrint('⚠️ Warning: Accessing feedbackStream after disposal');
      return const Stream<FeedbackEvent>.empty();
    }

    _feedbackController ??= StreamController<FeedbackEvent>.broadcast();
    return _feedbackController!.stream;
  }

  /// Check if mixin is disposed
  bool get isDisposed => _isDisposed;

  /// Emit a feedback event
  ///
  /// Returns true if event was emitted, false if ignored (disposed/no listeners)
  bool emitFeedback(FeedbackEvent event) {
    if (_isDisposed) {
      debugPrint(
          '⚠️ Warning: Attempted to emit feedback after disposal: ${event.message}',);
      return false;
    }

    try {
      _feedbackController ??= StreamController<FeedbackEvent>.broadcast();
      
      if (!_feedbackController!.hasListener) {
        // No listeners, but we'll still queue the event
        debugPrint('ℹ️ No listeners for feedback event: ${event.message}');
      }

      _feedbackController!.add(event);
      return true;
    } catch (e) {
      debugPrint('❌ Error emitting feedback: $e');
      return false;
    }
  }

  /// Emit success feedback
  void emitSuccess(
    String message, {
    FeedbackDisplay display = FeedbackDisplay.snackBar,
    Duration? duration,
    VoidCallback? action,
    String? actionLabel,
    Map<String, dynamic> metadata = const {},
  }) {
    emitFeedback(
      SuccessFeedback(
        message,
        display: display,
        duration: duration,
        action: action,
        actionLabel: actionLabel,
        metadata: metadata,
      ),
    );
  }

  /// Emit error feedback
  void emitError(
    String message, {
    String? technicalDetails,
    VoidCallback? retryAction,
    String? retryLabel,
    bool showTechnicalDetails = false,
    FeedbackDisplay display = FeedbackDisplay.snackBar,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    emitFeedback(
      ErrorFeedback(
        message,
        technicalDetails: technicalDetails,
        retryAction: retryAction,
        retryLabel: retryLabel,
        showTechnicalDetails: showTechnicalDetails,
        display: display,
        duration: duration,
        metadata: metadata,
      ),
    );
  }

  /// Emit warning feedback
  void emitWarning(
    String message, {
    FeedbackDisplay display = FeedbackDisplay.snackBar,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    emitFeedback(
      WarningFeedback(
        message,
        display: display,
        duration: duration,
        metadata: metadata,
      ),
    );
  }

  /// Emit info feedback
  void emitInfo(
    String message, {
    FeedbackDisplay display = FeedbackDisplay.snackBar,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    emitFeedback(
      InfoFeedback(
        message,
        display: display,
        duration: duration,
        metadata: metadata,
      ),
    );
  }

  /// Emit confirmation dialog
  void emitConfirmation({
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
    emitFeedback(
      ConfirmationFeedback(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isDangerous: isDangerous,
        barrierDismissible: barrierDismissible,
        metadata: metadata,
      ),
    );
  }

  /// Dispose feedback emitter mixin
  ///
  /// Clears the stream controller and marks the mixin as disposed.
  /// Should be called when the object is disposed to prevent memory leaks.
  void disposeFeedbackEmitter() {
    if (_isDisposed) return;

    _isDisposed = true;
    _feedbackController?.close();
    _feedbackController = null;
  }
}

