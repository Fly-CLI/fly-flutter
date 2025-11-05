import 'package:flutter/foundation.dart';
import 'package:foundation_project/core/di/global_container.dart';
import 'package:foundation_project/core/foundation/feedback/types/feedback_types.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_emitter.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_emitter_extensions.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_providers.dart';

/// Mixin to add feedback emission capability to any class
///
/// **Thread Safety:** This mixin is designed for single-threaded Flutter
/// main isolate usage. Event emission should only be called from the main isolate.
///
/// **Lifecycle:** This mixin provides access to the lifecycle emitter
/// via GlobalContainer. No disposal is needed as the emitter is managed
/// by the provider system.
///
/// **Note:** This mixin emits feedback to a stream for listeners to consume.
/// For direct feedback display with BuildContext, use FeedbackService directly.
///
/// Example:
/// ```dart
/// class MyService with FeedbackEmitterMixin {
///   Future<void> doWork() async {
///     emitSuccess('Work completed!');
///   }
/// }
/// ```
mixin FlyFeedbackEmitterMixin {
  AppLifecycleEmitter? _cachedEmitter;
  bool _isDisposed = false;

  /// Get the lifecycle emitter instance
  ///
  /// Uses lazy initialization and caching for performance.
  /// Accesses the emitter via GlobalContainer.
  AppLifecycleEmitter get _emitter {
    if (_isDisposed) {
      debugPrint('⚠️ Warning: Accessing lifecycle emitter after disposal');
      throw StateError('FeedbackEmitterMixin is disposed');
    }

    if (_cachedEmitter == null) {
      try {
        _cachedEmitter = GlobalContainer.instance.read(lifecycleEmitterProvider);
      } catch (e) {
        debugPrint('❌ Error accessing lifecycle emitter: $e');
        rethrow;
      }
    }

    return _cachedEmitter!;
  }

  /// Check if mixin is disposed
  bool get isDisposed => _isDisposed;

  /// Stream of feedback events
  ///
  /// Returns the feedback stream from the lifecycle emitter.
  /// This provides backward compatibility with code that accesses `feedbackStream`.
  Stream<FeedbackEvent> get feedbackStream {
    if (_isDisposed) {
      debugPrint('⚠️ Warning: Accessing feedbackStream after disposal');
      return const Stream<FeedbackEvent>.empty();
    }

    try {
      return _emitter.getFeedbackStream();
    } catch (e) {
      debugPrint('❌ Error accessing feedback stream: $e');
      return const Stream<FeedbackEvent>.empty();
    }
  }

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
      return _emitter.emit(event);
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
    String? retryLabel, // Optional - user provides localization
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
    String? confirmLabel, // Optional - user provides localization
    String? cancelLabel, // Optional - user provides localization
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
  /// Clears the cached emitter reference.
  /// Should be called when the object is disposed.
  /// Note: The lifecycle emitter itself is managed by the provider system
  /// and does not need manual disposal.
  void disposeFeedbackEmitter() {
    if (_isDisposed) return;

    _isDisposed = true;
    _cachedEmitter = null;
  }
}

