/*
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Riverpod implementation of [StateProvider].
///
/// This implementation wraps a Riverpod StateNotifierProvider to provide
/// state management functionality.
class RiverpodStateProvider<T> implements StateProvider<T> {
  RiverpodStateProvider({
    required this.name,
    required T initialValue,
    required ProviderContainer container,
  })  : _initialValue = initialValue,
        _container = container {
    _provider = StateNotifierProvider<StateNotifier<T>, T>(
      (_) => _StateNotifierImpl<T>(initialValue),
      name: name,
    );
  }

  final String name;
  final T _initialValue;
  final ProviderContainer _container;
  late final StateNotifierProvider<StateNotifier<T>, T> _provider;

  @override
  T get value => _container.read(_provider);

  /// Gets the underlying Riverpod provider.
  ///
  /// This allows direct access to Riverpod-specific features when needed.
  /// Use with Consumer or ConsumerWidget to watch the provider.
  StateNotifierProvider<StateNotifier<T>, T> get provider => _provider;

  /// Reads the current value from the provider.
  T read() => _container.read(_provider);

  /// Updates the value of the provider.
  void update(T value) {
    _container.read(_provider.notifier).update(value);
  }

  /// Disposes the provider.
  void dispose() {
    // Riverpod providers are automatically disposed when the container is disposed
    // No explicit disposal needed
  }
}

/// Internal state notifier implementation.
class _StateNotifierImpl<T> extends StateNotifier<T> {
  _StateNotifierImpl(T initialState) : super(initialState);

  void update(T value) {
    state = value;
  }
}

*/
