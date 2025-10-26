import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Extension methods for AsyncValue
extension FlyAsyncValueExtension<T> on AsyncValue<T> {
  /// Whether the value is loading
  bool get isFlyLoading => when(
    data: (_) => false,
    loading: () => true,
    error: (_, __) => false,
  );
  
  /// Whether the value has data
  bool get hasFlyData => when(
    data: (_) => true,
    loading: () => false,
    error: (_, __) => false,
  );
  
  /// Whether the value has an error
  bool get hasFlyError => when(
    data: (_) => false,
    loading: () => false,
    error: (_, __) => true,
  );
  
  /// Get the data or null
  T? get dataOrNull => when(
    data: (data) => data,
    loading: () => null,
    error: (_, __) => null,
  );
  
  /// Get the error or null
  Object? get errorOrNull => when(
    data: (_) => null,
    loading: () => null,
    error: (error, _) => error,
  );
  
  /// Get the stack trace or null
  StackTrace? get stackTraceOrNull => when(
    data: (_) => null,
    loading: () => null,
    error: (_, stackTrace) => stackTrace,
  );
  
  /// Map the data to a new type
  AsyncValue<R> mapData<R>(R Function(T data) mapper) => when(
    data: (data) => AsyncValue.data(mapper(data)),
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
  
  /// Map the data to a new AsyncValue
  AsyncValue<R> mapAsync<R>(AsyncValue<R> Function(T data) mapper) => when(
    data: (data) => mapper(data),
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
  
  /// Get the data or return a default value
  T getOrElse(T defaultValue) => when(
    data: (data) => data,
    loading: () => defaultValue,
    error: (_, __) => defaultValue,
  );
  
  /// Get the data or compute a default value
  T getOrElseCompute(T Function() defaultValueComputer) => when(
    data: (data) => data,
    loading: () => defaultValueComputer(),
    error: (_, __) => defaultValueComputer(),
  );
  
  /// Get the data or throw if error
  T getOrThrow() => when(
    data: (data) => data,
    loading: () => throw Exception('AsyncValue is still loading'),
    error: (error, stackTrace) => throw error,
  );
  
  /// Handle the value with different functions
  R handle<R>({
    required R Function(T data) data,
    required R Function() loading,
    required R Function(Object error, StackTrace? stackTrace) error,
  }) => when(
    data: data,
    loading: loading,
    error: error,
  );
  
  /// Handle the value with optional functions
  R maybeWhen<R>({
    required R Function() orElse,
    R Function(T data)? data,
    R Function()? loading,
    R Function(Object error, StackTrace? stackTrace)? error,
  }) => when(
    data: data ?? (_) => orElse(),
    loading: loading ?? () => orElse(),
    error: error ?? (_, __) => orElse(),
  );
}

/// Extension methods for AsyncValue<List<T>>
extension FlyAsyncValueListExtension<T> on AsyncValue<List<T>> {
  /// Whether the list is empty
  bool get isEmpty => when(
    data: (data) => data.isEmpty,
    loading: () => true,
    error: (_, __) => true,
  );
  
  /// Whether the list is not empty
  bool get isNotEmpty => !isEmpty;
  
  /// Get the length of the list
  int get length => when(
    data: (data) => data.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
  
  /// Get the first element or null
  T? get firstOrNull => when(
    data: (data) => data.isNotEmpty ? data.first : null,
    loading: () => null,
    error: (_, __) => null,
  );
  
  /// Get the last element or null
  T? get lastOrNull => when(
    data: (data) => data.isNotEmpty ? data.last : null,
    loading: () => null,
    error: (_, __) => null,
  );
  
  /// Check if the list contains an element
  bool contains(T element) => when(
    data: (data) => data.contains(element),
    loading: () => false,
    error: (_, __) => false,
  );
  
  /// Find the first element that matches the predicate
  T? firstWhereOrNull(bool Function(T element) test) => when(
    data: (data) {
      try {
        return data.firstWhere(test);
      } catch (e) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
  
  /// Find the last element that matches the predicate
  T? lastWhereOrNull(bool Function(T element) test) => when(
    data: (data) {
      try {
        return data.lastWhere(test);
      } catch (e) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
  
  /// Filter the list
  AsyncValue<List<T>> where(bool Function(T element) test) => mapData((data) => data.where(test).toList());
  
  /// Map the list elements
  AsyncValue<List<R>> mapList<R>(R Function(T element) mapper) => mapData((data) => data.map(mapper).toList());
  
  /// Sort the list
  AsyncValue<List<T>> sorted([int Function(T a, T b)? compare]) => mapData((data) {
    final sorted = List<T>.from(data)..sort(compare);
    return sorted;
  });
  
  /// Reverse the list
  AsyncValue<List<T>> reversed() => mapData((data) => data.reversed.toList());
  
  /// Take the first n elements
  AsyncValue<List<T>> take(int count) => mapData((data) => data.take(count).toList());
  
  /// Skip the first n elements
  AsyncValue<List<T>> skip(int count) => mapData((data) => data.skip(count).toList());
  
  /// Get a sublist
  AsyncValue<List<T>> sublist(int start, [int? end]) => mapData((data) => data.sublist(start, end));
}

/// Extension methods for AsyncValue<Map<K, V>>
extension FlyAsyncValueMapExtension<K, V> on AsyncValue<Map<K, V>> {
  /// Whether the map is empty
  bool get isEmpty => when(
    data: (data) => data.isEmpty,
    loading: () => true,
    error: (_, __) => true,
  );
  
  /// Whether the map is not empty
  bool get isNotEmpty => !isEmpty;
  
  /// Get the length of the map
  int get length => when(
    data: (data) => data.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
  
  /// Check if the map contains a key
  bool containsKey(K key) => when(
    data: (data) => data.containsKey(key),
    loading: () => false,
    error: (_, __) => false,
  );
  
  /// Check if the map contains a value
  bool containsValue(V value) => when(
    data: (data) => data.containsValue(value),
    loading: () => false,
    error: (_, __) => false,
  );
  
  /// Get a value by key
  V? getValue(K key) => when(
    data: (data) => data[key],
    loading: () => null,
    error: (_, __) => null,
  );
  
  /// Get all keys
  AsyncValue<Iterable<K>> get keys => mapData((data) => data.keys);
  
  /// Get all values
  AsyncValue<Iterable<V>> get values => mapData((data) => data.values);
  
  /// Get all entries
  AsyncValue<Iterable<MapEntry<K, V>>> get entries => mapData((data) => data.entries);
  
  /// Map the map values
  AsyncValue<Map<K, R>> mapValues<R>(R Function(V value) mapper) => mapData((data) => data.map((key, value) => MapEntry(key, mapper(value))));
  
  /// Map the map keys
  AsyncValue<Map<R, V>> mapKeys<R>(R Function(K key) mapper) => mapData((data) => data.map((key, value) => MapEntry(mapper(key), value)));
  
  /// Filter the map
  AsyncValue<Map<K, V>> where(bool Function(K key, V value) test) => mapData((data) => data.entries.where((entry) => test(entry.key, entry.value)).fold<Map<K, V>>({}, (map, entry) => {...map, entry.key: entry.value}));
  
  /// Remove entries where the value is null
  AsyncValue<Map<K, V>> removeNullValues() => mapData((data) => Map<K, V>.from(data)..removeWhere((key, value) => value == null));
}
