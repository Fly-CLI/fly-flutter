import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:fly_flow_guard/fly_flow_guard.dart';
import 'package:fly_flow_guard/fly_flow_guard.dart';
import '../view_model/coordinator/view_model_async_coordinator.dart';
import '../view_model/coordinator/view_model_feedback_coordinator.dart';
import '../view_model/view_model_state.dart';

/// Base class for Riverpod-based ViewModels
/// Provides common state management functionality using Riverpod
abstract class FlyViewModel<T extends FlyViewModelState<T>>
    extends Notifier<T> {
  final ViewModelFlowGuardCoordinator _asyncCoordinator;
  late final ViewModelFeedbackCoordinator _feedbackCoordinator;

  FlyViewModel({
    ViewModelFlowGuardCoordinator? asyncCoordinator,
    ViewModelFeedbackCoordinator? feedbackCoordinator,
  }) : _asyncCoordinator = asyncCoordinator ??
            ViewModelFlowGuardCoordinator() {
    _feedbackCoordinator = feedbackCoordinator ??
        ViewModelFeedbackCoordinator(
          scope: feedbackScope,
        );
  }

  /// Identifier used to scope feedback events for this ViewModel.
  ///
  /// Defaults to the runtime type name but can be overridden by subclasses
  /// to provide a custom scope (e.g., when multiple instances of the same
  /// ViewModel type are active simultaneously).
  String get feedbackScope => runtimeType.toString();

  T get viewModelState => state;

  /// Convenient runAsyncOperation method that integrates with state management
  ///
  /// This method automatically handles loading states, error states, and optional
  /// feedback emission. It uses [FlowGuard] internally for network-aware async
  /// operation handling with retry logic, connectivity checking, and timeout management.
  ///
  /// **Important**: Always use this method for async operations in ViewModels to ensure
  /// consistent error handling, loading state management, and proper network awareness.
  ///
  /// Supports optional automatic feedback emission via [successMessage] and
  /// [errorMessage] parameters. When provided, success/error feedback will be
  /// automatically displayed using the feedback system.
  ///
  /// The [timeout] parameter defaults to [AsyncOperationConfig.standardTimeout] (30 seconds)
  /// if not specified. For long-running operations, consider using:
  /// - [AsyncOperationConfig.longTimeout] (60 seconds)
  /// - [AsyncOperationConfig.veryLongTimeout] (120 seconds)
  /// - [AsyncOperationConfig.backgroundTimeout] (100 minutes)
  ///
  /// Example:
  /// ```dart
  /// // Basic usage without feedback
  /// final result = await runAsyncOperation(() => repository.fetchData());
  /// if (result.isSuccess) {
  ///   state = state.copyWith(data: result.data);
  /// }
  ///
  /// // With automatic feedback
  /// await runAsyncOperation(
  ///   () => repository.save(data),
  ///   successMessage: 'Data saved successfully!',
  ///   errorMessage: 'Failed to save data',
  /// );
  ///
  /// // With custom timeout
  /// await runAsyncOperation(
  ///   () => repository.uploadLargeFile(file),
  ///   timeout: AsyncOperationConfig.veryLongTimeout,
  ///   errorMessage: 'Upload failed',
  /// );
  /// ```
  Future<AppResult<R>> runAsyncOperation<R>(
    Future<R> Function() operation, {
    String? errorMessage,
    Duration? timeout,
    bool resetError = true,
    void Function()? onFinally,
    void Function(String errorMessage)? onError,
    void Function({required bool isLoading})? loadingHandler,
    // Feedback parameters
    String? successMessage,
    bool canShowSuccess = true,
    bool canShowError = true,
  }) async {
    final void Function({required bool isLoading}) effectiveLoadingHandler =
        loadingHandler ?? setLoading;
    void errorStateHandler(String? value) {
      if (value != null) {
        setError(value);
        onError?.call(value);
      } else if (resetError) {
        clearError();
      }
    }

    final result = await _asyncCoordinator.execute<R>(
      operation,
      errorMessage: errorMessage,
      timeout: timeout,
      resetError: resetError,
      onFinally: onFinally,
      onLoadingChanged: effectiveLoadingHandler,
      onErrorChanged: errorStateHandler,
      successMessage: successMessage,
      canShowSuccess: canShowSuccess,
      canShowError: canShowError,
      feedbackHandlers: ViewModelFeedbackHandlers(
        showSuccess: successMessage != null
            ? (message) => _feedbackCoordinator.showSuccess(message)
            : null,
        showError: (message, retryAction) {
          _feedbackCoordinator.showError(
            message,
            retryAction: retryAction,
          );
        },
      ),
    );

    return result;
  }

  // =============================================================================
  // FEEDBACK METHODS - feedback system integration
  // =============================================================================

  /// Emit success feedback.
  void showSuccess(
      String message, {
        FeedbackDisplay display = FeedbackDisplay.snackBar,
        Duration? duration,
        VoidCallback? action,
        String? actionLabel,
        Map<String, dynamic> metadata = const {},
      }) {
    _feedbackCoordinator.showSuccess(
      message,
      display: display,
      duration: duration,
      action: action,
      actionLabel: actionLabel,
      metadata: metadata,
    );
  }

  /// Emit error feedback.
  void showError(
      String message, {
        String? technicalDetails,
        VoidCallback? retryAction,
        String? retryLabel,
        bool showTechnicalDetails = false,
        FeedbackDisplay display = FeedbackDisplay.snackBar,
        Duration? duration,
        Map<String, dynamic> metadata = const {},
      }) {
    _feedbackCoordinator.showError(
      message,
      technicalDetails: technicalDetails,
      retryAction: retryAction,
      retryLabel: retryLabel,
      showTechnicalDetails: showTechnicalDetails,
      display: display,
      duration: duration,
      metadata: metadata,
    );
  }

  /// Emit warning feedback.
  void showWarning(
      String message, {
        FeedbackDisplay display = FeedbackDisplay.snackBar,
        Duration? duration,
        Map<String, dynamic> metadata = const {},
      }) {
    _feedbackCoordinator.showWarning(
      message,
      display: display,
      duration: duration,
      metadata: metadata,
    );
  }

  /// Emit informational feedback.
  void showInfo(
      String message, {
        FeedbackDisplay display = FeedbackDisplay.snackBar,
        Duration? duration,
        Map<String, dynamic> metadata = const {},
      }) {
    _feedbackCoordinator.showInfo(
      message,
      display: display,
      duration: duration,
      metadata: metadata,
    );
  }

  /// Emit confirmation dialog feedback.
  void showConfirmation({
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
    _feedbackCoordinator.showConfirmation(
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
  }

  /// Set loading state
  void setLoading({required bool isLoading}) {
    state = state.withLoading(isLoading);
  }

  /// Set error state
  void setError(String? errorMessage) {
    state = state.withError(errorMessage);
  }

  /// Clear error state
  void clearError() {
    state = state.clearError();
  }

  // =============================================================================
  // LIFECYCLE METHODS - Optional overrides for screen lifecycle events
  // =============================================================================

  /// Called once when the ViewModel is first initialized
  /// Override this to perform one-time setup operations
  void onInitialize() {
    // Default implementation - can be overridden
  }

  /// Called every time the screen appears (including first time)
  /// Override this to refresh data or update state when screen becomes visible
  void onAppear() {
    // Default implementation - can be overridden
  }

  /// Called when the screen is popped or hidden
  /// Override this to cleanup resources or cancel ongoing operations
  void onDisappear() {
    // Default implementation - can be overridden
  }

  /// Called when the screen is being permanently disposed
  /// Override this to cleanup resources that need to be released
  void onDispose() {
    // Default implementation - can be overridden by subclasses
  }

}

