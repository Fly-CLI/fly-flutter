import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fly_core/src/models/result.dart';
import 'package:fly_core/src/models/view_state.dart';

part 'base_viewmodel.g.dart';

/// Base class for all ViewModels in Fly CLI applications
/// 
/// Provides common functionality for state management, error handling,
/// and lifecycle management using Riverpod StateNotifier.
abstract class BaseViewModel<T> extends StateNotifier<ViewState<T>> {
  BaseViewModel() : super(ViewState<T>.idle());
  
  /// Initialize the ViewModel
  /// 
  /// This method is called when the ViewModel is first created.
  /// Override this method to perform initialization logic.
  Future<void> initialize() async {
    // Default implementation does nothing
    // Override in subclasses for initialization logic
  }
  
  /// Execute a safe operation that can fail
  /// 
  /// This method wraps an operation in try-catch and updates the state
  /// accordingly. It's the recommended way to handle operations that
  /// might fail.
  Future<Result<T>> runSafe(Future<T> Function() operation) async {
    state = ViewState<T>.loading();
    
    try {
      final result = await operation();
      state = ViewState<T>.success(result);
      return Result.success(result);
    } catch (error, stackTrace) {
      state = ViewState<T>.error(error, stackTrace);
      return Result.failure(error, stackTrace);
    }
  }
  
  /// Execute a safe operation synchronously
  /// 
  /// This method wraps a synchronous operation in try-catch and updates
  /// the state accordingly.
  Result<T> runSafeSync(T Function() operation) {
    state = ViewState<T>.loading();
    
    try {
      final result = operation();
      state = ViewState<T>.success(result);
      return Result.success(result);
    } catch (error, stackTrace) {
      state = ViewState<T>.error(error, stackTrace);
      return Result.failure(error, stackTrace);
    }
  }
  
  /// Set the state to idle
  void setIdle() {
    state = ViewState<T>.idle();
  }
  
  /// Set the state to loading
  void setLoading() {
    state = ViewState<T>.loading();
  }
  
  /// Set the state to error
  void setError(Object error, [StackTrace? stackTrace]) {
    state = ViewState<T>.error(error, stackTrace);
  }
  
  /// Set the state to success with data
  void setSuccess(T data) {
    state = ViewState<T>.success(data);
  }
  
  /// Get the current data if the state is success
  T? getData() {
    return state.data;
  }
  
  /// Get the current error if the state is error
  Object? getError() {
    return state.error;
  }
  
  /// Whether the ViewModel is currently loading
  bool get isLoading => state.isLoading;
  
  /// Whether the ViewModel has an error
  bool get hasError => state.isError;
  
  /// Whether the ViewModel is idle
  bool get isIdle => state.isIdle;
  
  /// Whether the ViewModel has success data
  bool get hasData => state.isSuccess;
  
  /// Dispose of the ViewModel
  /// 
  /// Override this method to perform cleanup when the ViewModel is disposed.
  @override
  void dispose() {
    // Default implementation does nothing
    // Override in subclasses for cleanup logic
    super.dispose();
  }
}

/// Mixin for ViewModels that need to handle refresh operations
mixin RefreshableMixin<T> on BaseViewModel<T> {
  /// Refresh the data
  /// 
  /// This method should be implemented by subclasses to define
  /// how data should be refreshed.
  Future<void> refresh();
  
  /// Whether the ViewModel is currently refreshing
  bool get isRefreshing => isLoading;
}

/// Mixin for ViewModels that need to handle pagination
mixin PaginationMixin<T> on BaseViewModel<T> {
  /// Load more data for pagination
  /// 
  /// This method should be implemented by subclasses to define
  /// how pagination should work.
  Future<void> loadMore();
  
  /// Whether there is more data to load
  bool get hasMoreData => true; // Override in subclasses
  
  /// Whether the ViewModel is currently loading more data
  bool get isLoadingMore => false; // Override in subclasses
}

/// Mixin for ViewModels that need to handle search
mixin SearchMixin<T> on BaseViewModel<T> {
  /// Search for data
  /// 
  /// This method should be implemented by subclasses to define
  /// how search should work.
  Future<void> search(String query);
  
  /// Clear the search
  void clearSearch();
  
  /// The current search query
  String get searchQuery => ''; // Override in subclasses
}

/// Provider for BaseViewModel
/// 
/// This provider creates a BaseViewModel instance. It's mainly
/// used for testing or as a base for more specific providers.
@riverpod
class BaseViewModelProvider extends _$BaseViewModelProvider {
  @override
  BaseViewModel<Object?> build() {
    return _BaseViewModelImpl();
  }
}

/// Simple implementation of BaseViewModel for testing
class _BaseViewModelImpl extends BaseViewModel<Object?> {
  @override
  Future<void> initialize() async {
    // Simple implementation for testing
  }
}
