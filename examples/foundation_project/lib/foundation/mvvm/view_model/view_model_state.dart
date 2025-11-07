import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/foundation/mvvm/view_model/fly_view_model.dart';

/// Abstract interface for ViewModel state
/// All ViewModel states must implement this interface to ensure
/// they have the common properties needed for state management
abstract class FlyViewModelState<TSelf extends FlyViewModelState<TSelf>> {
  /// Whether the ViewModel is in a loading state
  bool get isLoading;

  /// Error message if an error occurred
  String? get error;

  /// Check if there's an error
  bool get hasError => error != null;

  TSelf withLoading(bool isLoading) {
    return copyWith(isLoading: isLoading);
  }

  TSelf withError(String? error) {
    return copyWith(error: error, updateError: true);
  }

  TSelf clearError() {
    return copyWith(error: null, updateError: true);
  }

  TSelf copyWith({
    bool? isLoading,
    String? error,
    bool updateError = false,
  });
}

/// Base implementation of ViewModelState
/// Provides a default implementation with common state management properties
/// ViewModels can extend this or create their own implementations
class BaseViewModelState extends FlyViewModelState<BaseViewModelState> {
  @override
  final bool isLoading;

  @override
  final String? error;

  BaseViewModelState({
    this.isLoading = false,
    this.error,
  });

  @override
  BaseViewModelState copyWith({
    bool? isLoading,
    String? error,
    bool updateError = false,
  }) {
    return BaseViewModelState(
      isLoading: isLoading ?? this.isLoading,
      error: updateError ? error : this.error,
    );
  }

  @override
  BaseViewModelState withLoading(bool isLoading) {
    return copyWith(isLoading: isLoading);
  }

  @override
  BaseViewModelState withError(String? error) {
    return copyWith(error: error, updateError: true);
  }

  @override
  BaseViewModelState clearError() {
    return copyWith(error: null, updateError: true);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BaseViewModelState &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(isLoading, error);
  }

  @override
  String toString() {
    return 'BaseViewModelState(isLoading: $isLoading, error: $error)';
  }
}

/// Mixin for creating Riverpod providers from ViewModels
mixin ViewModelProviderMixin<
VM extends FlyViewModel<S>,
S extends FlyViewModelState<S>
> {
  /// Create a NotifierProvider for a ViewModel
  NotifierProvider<VM, S> get provider;
}

/// Extension methods for easier state access
extension ViewModelStateExtensions<T extends FlyViewModelState<T>> on T {
  /// Check if there's an error
  bool get hasError => error != null;

  /// Get error message or empty string
  String get errorMessage => error ?? '';

  /// Check if the ViewModel is in a loading state
  bool get isBusy => isLoading;

  /// Check if the ViewModel is ready (initialized and not loading)
  bool get isReady => !isLoading && !hasError;
}