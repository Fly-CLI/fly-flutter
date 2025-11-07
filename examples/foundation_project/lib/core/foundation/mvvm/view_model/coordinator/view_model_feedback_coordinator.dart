import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:foundation_project/core/foundation/foundation.dart';

typedef FeedbackAction = void Function();
typedef EventEmitter = bool Function(AppEvent event);

class ViewModelFeedbackCoordinator with EventEmitterMixin {
  final String scope;

  ViewModelFeedbackCoordinator({
    required this.scope,
  });

  /// Emit a feedback event through the event emitter.
  ///
  /// Packages the feedback event inside a [FeedbackAppEvent] so that
  /// listeners can leverage the shared event infrastructure.
  bool _emitFeedback(
    FeedbackEvent event, {
    Map<String, dynamic> metadata = const {},
  }) {
    final combinedMetadata = <String, dynamic>{
      ...event.metadata,
      ...metadata,
    };

    return emit(
      FeedbackAppEvent(
        scope: scope,
        payload: event,
        metadata: combinedMetadata,
      ),
    );
  }

  void showSuccess(
    String message, {
    FeedbackDisplay display = FeedbackDisplay.snackBar,
    Duration? duration,
    FeedbackAction? action,
    String? actionLabel,
    Map<String, dynamic> metadata = const {},
  }) {
    _emitFeedback(
      SuccessFeedback(
        message,
        display: display,
        duration: duration,
        action: action,
        actionLabel: actionLabel,
        metadata: metadata,
      ),
      metadata: metadata,
    );
  }

  void showError(
    String message, {
    String? technicalDetails,
    FeedbackAction? retryAction,
    String? retryLabel,
    bool showTechnicalDetails = false,
    FeedbackDisplay display = FeedbackDisplay.snackBar,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    _emitFeedback(
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
      metadata: metadata,
    );
  }

  void showErrorWithRetry(
    String message,
    AsyncCallback retryOperation, {
    String? technicalDetails,
    String? retryLabel,
    bool showTechnicalDetails = false,
    FeedbackDisplay display = FeedbackDisplay.snackBar,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    showError(
      message,
      technicalDetails: technicalDetails,
      retryAction: () => unawaited(retryOperation()),
      retryLabel: retryLabel,
      showTechnicalDetails: showTechnicalDetails,
      display: display,
      duration: duration,
      metadata: metadata,
    );
  }

  void showWarning(
    String message, {
    FeedbackDisplay display = FeedbackDisplay.snackBar,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    _emitFeedback(
      WarningFeedback(
        message,
        display: display,
        duration: duration,
        metadata: metadata,
      ),
      metadata: metadata,
    );
  }

  void showInfo(
    String message, {
    FeedbackDisplay display = FeedbackDisplay.snackBar,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    _emitFeedback(
      InfoFeedback(
        message,
        display: display,
        duration: duration,
        metadata: metadata,
      ),
      metadata: metadata,
    );
  }

  void showConfirmation({
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    FeedbackAction? onConfirm,
    FeedbackAction? onCancel,
    bool isDangerous = false,
    bool barrierDismissible = true,
    Map<String, dynamic> metadata = const {},
  }) {
    _emitFeedback(
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
      metadata: metadata,
    );
  }
}


