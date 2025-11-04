import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{project_name_snake}}/core/foundation/foundation.dart';

/// Base class for Riverpod-based ViewModels
/// Provides common state management functionality using Riverpod
abstract class ViewModel<T extends ViewModelState> extends Notifier<T>
    with FeedbackEmitterMixin {
  final AsyncHandler _asyncHandler = AsyncHandler();

  ViewModel();

  /// Abstract method for copying state with updated values
  /// Subclasses must implement this to provide state-specific copying logic
  T copyState({bool? isLoading, String? error});

  /// Set loading state
  void setLoading(bool loading) {
    state = copyState(isLoading: loading);
  }

  /// Set error state
  void setError(String? errorMessage) {
    state = copyState(error: errorMessage);
  }

  /// Clear error state
  void clearError() {
    state = copyState(error: null);
  }

  T get viewModelState => state;

  /// Convenient performAsync method that integrates with state management
  ///
  /// Supports optional automatic feedback emission via [successMessage] and
  /// [errorMessage] parameters. When provided, success/error feedback will be
  /// automatically displayed using the feedback system.
  ///
  /// Example:
  /// ```dart
  /// // Without feedback (existing behavior)
  /// await performAsync(() => repository.save(data));
  ///
  /// // With automatic feedback
  /// await performAsync(
  ///   () => repository.save(data),
  ///   successMessage: 'Data saved successfully!',
  ///   errorMessage: 'Failed to save data',
  /// );
  /// ```
  Future<AppResult<R>> performAsync<R>(
    Future<R> Function() operation, {
    String? errorMessage,
    Duration timeout = const Duration(seconds: 100 * 60),
    bool resetError = true,
    void Function()? onFinally,
    void Function(String errorMessage)? onError,
    void Function(bool)? loadingHandler,
    // Feedback parameters
    String? successMessage,
    bool showSuccess = true,
    bool showError = true,
  }) async {
    final result = await _asyncHandler.performAsync(
      operation,
      errorMessage: errorMessage,
      timeout: timeout,
      onLoadingChanged: (loading) {
        if (loadingHandler != null) {
          loadingHandler(loading);
        } else {
          setLoading(loading);
        }
      },
      onErrorChanged: (errorMessage) {
        if (errorMessage != null) {
          setError(errorMessage);
          onError?.call(errorMessage);
        } else if (resetError) {
          clearError();
        }
      },
      onNotify: () {},
      // No need to notify manually with Riverpod
      resetError: resetError,
      notifyChange: false,
      // Riverpod handles notifications automatically
      onFinally: onFinally,
    );

    // Handle automatic feedback emission
    if (result.isSuccess && showSuccess && successMessage != null) {
      emitSuccess(successMessage);
    } else if (!result.isSuccess && showError) {
      // Only emit error feedback if errorMessage is provided or we have a result error
      final errorMsg = errorMessage ?? result.error;
      if (errorMsg != null) {
        emitError(
          errorMsg,
          retryAction: () => performAsync(
            operation,
            errorMessage: errorMessage,
            timeout: timeout,
            resetError: resetError,
            onFinally: onFinally,
            onError: onError,
            loadingHandler: loadingHandler,
            successMessage: successMessage,
            showSuccess: showSuccess,
            showError: showError,
          ),
        );
      }
    }

    return result;
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
    disposeFeedbackEmitter(); // Clean up feedback stream
    // Default implementation - can be overridden by subclasses
  }

}

/// Abstract interface for ViewModel state
/// All ViewModel states must implement this interface to ensure
/// they have the common properties needed for state management
abstract class ViewModelState {
  /// Whether the ViewModel is in a loading state
  bool get isLoading;

  /// Error message if an error occurred
  String? get error;

  /// Check if there's an error
  bool get hasError => error != null;
}

/// Base implementation of ViewModelState
/// Provides a default implementation with common state management properties
/// ViewModels can extend this or create their own implementations
class BaseViewModelState implements ViewModelState {
  @override
  final bool isLoading;

  @override
  final String? error;

  /// Custom state map for backward compatibility
  /// New ViewModels should prefer strongly-typed state properties
  final Map<String, dynamic> customState;

  const BaseViewModelState({
    this.isLoading = false,
    this.error,
    this.customState = const {},
  });

  BaseViewModelState copyWith({
    bool? isLoading,
    String? error,
    bool? isInitialized,
    Map<String, dynamic>? customState,
  }) {
    return BaseViewModelState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      customState: customState ?? this.customState,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BaseViewModelState &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.customState == customState;
  }

  @override
  int get hashCode {
    return Object.hash(isLoading, error, customState);
  }

  @override
  String toString() {
    return 'BaseViewModelState(isLoading: $isLoading, error: $error, customState: $customState)';
  }

  @override
  bool get hasError => error != null;
}

/// Mixin for creating Riverpod providers from ViewModels
mixin ViewModelProviderMixin<
  VM extends ViewModel<S>,
  S extends ViewModelState
> {
  /// Create a NotifierProvider for a ViewModel
  NotifierProvider<VM, S> get provider;
}

/// Extension methods for easier state access
extension ViewModelStateExtensions on ViewModelState {
  /// Check if there's an error
  bool get hasError => error != null;

  /// Get error message or empty string
  String get errorMessage => error ?? '';

  /// Check if the ViewModel is in a loading state
  bool get isBusy => isLoading;

  /// Check if the ViewModel is ready (initialized and not loading)
  bool get isReady => !isLoading && !hasError;
}
