import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:{{project_name_snake}}/core/foundation/feedback/feedback_event.dart';

/// Mixin to add feedback emission capability to any class
///
/// **Thread Safety:** This mixin is designed for single-threaded Flutter
/// main isolate usage. StreamController operations should only be called
/// from the main isolate.
///
/// **Lifecycle:** Always call `disposeFeedbackEmitter()` when disposing
/// the object to prevent memory leaks.
///
/// Example:
/// ```dart
/// class MyService with FeedbackEmitterMixin {
///   Future<void> doWork() async {
///     emitSuccess('Work completed!');
///   }
///
///   @override
///   void dispose() {
///     disposeFeedbackEmitter();  // IMPORTANT!
///     super.dispose();
///   }
/// }
/// ```
mixin FeedbackEmitterMixin {
  StreamController<FeedbackEvent>? _feedbackController;
  bool _isDisposed = false;

  /// Stream of feedback events
  /// Lazy initialization - only creates controller when first accessed
  Stream<FeedbackEvent> get feedbackStream {
    if (_isDisposed) {
      debugPrint('⚠️ Warning: Accessing feedbackStream after disposal');
      return const Stream<FeedbackEvent>.empty();
    }

    _feedbackController ??= StreamController<FeedbackEvent>.broadcast();
    return _feedbackController!.stream;
  }

  /// Check if feedback stream is active (has listeners)
  bool get hasFeedbackListeners {
    if (_isDisposed || _feedbackController == null) return false;
    return _feedbackController!.hasListener;
  }

  /// Check if emitter is disposed
  bool get isDisposed => _isDisposed;

  /// Emit a feedback event
  ///
  /// Returns true if event was emitted, false if ignored (disposed/no listeners)
  bool emitFeedback(FeedbackEvent event) {
    if (_isDisposed) {
      debugPrint(
          '⚠️ Warning: Attempted to emit feedback after disposal: ${event.message}');
      return false;
    }

    if (_feedbackController == null) {
      // No listeners yet, skip silently (normal case)
      return false;
    }

    if (_feedbackController!.isClosed) {
      debugPrint('⚠️ Warning: Feedback stream is closed');
      return false;
    }

    try {
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
    FeedbackDisplay display = FeedbackDisplay.snackbar,
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
    bool showTechnicalDetails = false,
    FeedbackDisplay display = FeedbackDisplay.snackbar,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    emitFeedback(
      ErrorFeedback(
        message,
        technicalDetails: technicalDetails,
        retryAction: retryAction,
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
    FeedbackDisplay display = FeedbackDisplay.snackbar,
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
    FeedbackDisplay display = FeedbackDisplay.snackbar,
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
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
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

  /// Dispose feedback resources
  /// MUST be called when the object is disposed to prevent memory leaks
  void disposeFeedbackEmitter() {
    if (_isDisposed) return;

    _isDisposed = true;
    _feedbackController?.close();
    _feedbackController = null;
  }
}

