import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'async_value_providers.g.dart';

/// Provider for handling async operations with loading, error, and success states
@riverpod
class AsyncValueProvider extends _$AsyncValueProvider {
  @override
  AsyncValue<String> build() {
    return const AsyncValue.loading();
  }
  
  /// Load data asynchronously
  Future<void> loadData(Future<String> Function() dataLoader) async {
    state = const AsyncValue.loading();
    
    try {
      final data = await dataLoader();
      state = AsyncValue.data(data);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace ?? StackTrace.current);
    }
  }
  
  /// Refresh the data
  Future<void> refresh(Future<String> Function() dataLoader) async {
    await loadData(dataLoader);
  }
  
  /// Clear the data
  void clear() {
    state = const AsyncValue.loading();
  }
}

/// Provider for handling async operations with generic data type
@riverpod
class GenericAsyncValueProvider extends _$GenericAsyncValueProvider {
  @override
  AsyncValue<dynamic> build() {
    return const AsyncValue.loading();
  }
  
  /// Load data asynchronously
  Future<void> loadData<T>(Future<T> Function() dataLoader) async {
    state = const AsyncValue.loading();
    
    try {
      final data = await dataLoader();
      state = AsyncValue.data(data);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace ?? StackTrace.current);
    }
  }
  
  /// Refresh the data
  Future<void> refresh<T>(Future<T> Function() dataLoader) async {
    await loadData(dataLoader);
  }
  
  /// Clear the data
  void clear() {
    state = const AsyncValue.loading();
  }
  
  /// Update the data directly
  void updateData<T>(T data) {
    state = AsyncValue.data(data);
  }
  
  /// Set error state
  void setError(Object error, [StackTrace? stackTrace]) {
    state = AsyncValue.error(error, stackTrace ?? StackTrace.current);
  }
}

/// Provider for handling paginated data
@riverpod
class PaginatedDataProvider extends _$PaginatedDataProvider {
  @override
  AsyncValue<List<dynamic>> build() {
    return const AsyncValue.data([]);
  }
  
  /// Load initial data
  Future<void> loadInitialData<T>(Future<List<T>> Function() dataLoader) async {
    state = const AsyncValue.loading();
    
    try {
      final data = await dataLoader();
      state = AsyncValue.data(data.cast<dynamic>());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace ?? StackTrace.current);
    }
  }
  
  /// Load more data (append to existing)
  Future<void> loadMoreData<T>(Future<List<T>> Function() dataLoader) async {
    final currentData = state.valueOrNull ?? <dynamic>[];
    
    try {
      final newData = await dataLoader();
      state = AsyncValue.data([...currentData, ...newData.cast<dynamic>()]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace ?? StackTrace.current);
    }
  }
  
  /// Refresh all data
  Future<void> refresh<T>(Future<List<T>> Function() dataLoader) async {
    await loadInitialData(dataLoader);
  }
  
  /// Clear all data
  void clear() {
    state = const AsyncValue.data([]);
  }
  
  /// Add item to the list
  void addItem<T>(T item) {
    final currentData = state.valueOrNull ?? <dynamic>[];
    state = AsyncValue.data([...currentData, item]);
  }
  
  /// Remove item from the list
  void removeItem<T>(T item) {
    final currentData = state.valueOrNull ?? <dynamic>[];
    state = AsyncValue.data(currentData.where((e) => e != item).toList());
  }
  
  /// Update item in the list
  void updateItem<T>(T oldItem, T newItem) {
    final currentData = state.valueOrNull ?? <dynamic>[];
    final updatedData = currentData.map((item) => item == oldItem ? newItem : item).toList();
    state = AsyncValue.data(updatedData);
  }
}

/// Provider for handling search functionality
@riverpod
class SearchProvider extends _$SearchProvider {
  @override
  AsyncValue<List<dynamic>> build() {
    return const AsyncValue.data([]);
  }
  
  /// Perform search
  Future<void> search<T>(
    String query,
    Future<List<T>> Function(String query) searchFunction,
  ) async {
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    
    state = const AsyncValue.loading();
    
    try {
      final results = await searchFunction(query);
      state = AsyncValue.data(results.cast<dynamic>());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace ?? StackTrace.current);
    }
  }
  
  /// Clear search results
  void clear() {
    state = const AsyncValue.data([]);
  }
}

/// Provider for handling form validation
@riverpod
class FormValidationProvider extends _$FormValidationProvider {
  @override
  Map<String, String> build() {
    return {};
  }
  
  /// Set field error
  void setFieldError(String field, String error) {
    state = {...state, field: error};
  }
  
  /// Clear field error
  void clearFieldError(String field) {
    final newState = Map<String, String>.from(state);
    newState.remove(field);
    state = newState;
  }
  
  /// Clear all errors
  void clearAllErrors() {
    state = {};
  }
  
  /// Check if form is valid
  bool get isValid => state.isEmpty;
  
  /// Get error for specific field
  String? getFieldError(String field) => state[field];
  
  /// Check if field has error
  bool hasFieldError(String field) => state.containsKey(field);
}
