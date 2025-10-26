import 'package:freezed_annotation/freezed_annotation.dart';

part 'view_state.freezed.dart';

/// Sealed class representing the state of a view/viewmodel
/// 
/// This class provides a type-safe way to represent different states
/// that a view can be in, with support for data, loading, error, and idle states.
@freezed
sealed class ViewState<T> with _$ViewState<T> {
  /// Initial state when the view is first created
  const factory ViewState.idle() = IdleState<T>;
  
  /// Loading state when an operation is in progress
  const factory ViewState.loading() = LoadingState<T>;
  
  /// Error state when an operation fails
  const factory ViewState.error(Object error, [StackTrace? stackTrace]) = ErrorState<T>;
  
  /// Success state when an operation completes successfully
  const factory ViewState.success(T data) = SuccessState<T>;
}

/// Extension methods for ViewState
extension ViewStateExtension<T> on ViewState<T> {
  /// Whether the state is idle
  bool get isIdle => this is IdleState<T>;
  
  /// Whether the state is loading
  bool get isLoading => this is LoadingState<T>;
  
  /// Whether the state is an error
  bool get isError => this is ErrorState<T>;
  
  /// Whether the state is success
  bool get isSuccess => this is SuccessState<T>;
  
  /// Get the error if the state is an error, null otherwise
  Object? get error => switch (this) {
    ErrorState<T>(error: final error) => error,
    _ => null,
  };
  
  /// Get the stack trace if the state is an error, null otherwise
  StackTrace? get stackTrace => switch (this) {
    ErrorState<T>(stackTrace: final stackTrace) => stackTrace,
    _ => null,
  };
  
  /// Get the data if the state is success, null otherwise
  T? get data => switch (this) {
    SuccessState<T>(data: final data) => data,
    _ => null,
  };
  
  /// Map the state to a value based on its type
  R when<R>({
    required R Function() idle,
    required R Function() loading,
    required R Function(Object error, StackTrace? stackTrace) error,
    required R Function(T data) success,
  }) {
    return switch (this) {
      IdleState<T>() => idle(),
      LoadingState<T>() => loading(),
      ErrorState<T>(error: final err, stackTrace: final stackTrace) => error(err, stackTrace),
      SuccessState<T>(data: final data) => success(data),
    };
  }
  
  /// Map the state to a value, with optional handlers
  R maybeWhen<R>({
    R Function()? idle,
    R Function()? loading,
    R Function(Object error, StackTrace? stackTrace)? error,
    R Function(T data)? success,
    required R Function() orElse,
  }) {
    return switch (this) {
      IdleState<T>() => idle?.call() ?? orElse(),
      LoadingState<T>() => loading?.call() ?? orElse(),
      ErrorState<T>(error: final err, stackTrace: final stackTrace) => 
        error != null ? error(err, stackTrace) : orElse(),
      SuccessState<T>(data: final data) => success != null ? success(data) : orElse(),
    };
  }
  
  /// Check if the state matches a specific type
  bool isA<U>() => this is SuccessState<U>;
}
