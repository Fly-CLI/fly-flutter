/*
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fly_state/src/interfaces/state_manager.dart';
import 'package:fly_state/src/interfaces/state_provider.dart';
import 'package:fly_state/src/implementations/riverpod/riverpod_state_provider.dart';

/// Riverpod implementation of [StateManager].
///
/// This implementation uses Riverpod as the underlying state management
/// framework. It provides a bridge between the abstract [StateManager]
/// interface and Riverpod's specific APIs.
///
/// ## Usage
///
/// ```dart
/// // Initialize the state manager
/// final stateManager = RiverpodStateManager();
/// stateManager.initialize();
///
/// // Create a provider
/// final counterProvider = stateManager.createProvider<int>(
///   'counter',
///   initialValue: 0,
/// );
///
/// // Use in widgets
/// Consumer(
///   builder: (context, ref, child) {
///     final value = stateManager.watch(counterProvider);
///     return Text('Count: $value');
///   },
/// )
/// ```
class RiverpodStateManager implements StateManager {
  RiverpodStateManager();

  ProviderContainer? _container;
  final Map<String, RiverpodStateProvider<Object?>> _providers = {};

  @override
  void initialize() {
    if (_container != null) {
      throw StateError('RiverpodStateManager already initialized');
    }
    _container = ProviderContainer();
  }

  @override
  StateProvider<T> createProvider<T>(
    String name, {
    required T initialValue,
  }) {
    if (!isInitialized) {
      throw StateError(
        'RiverpodStateManager not initialized. Call initialize() first.',
      );
    }

    if (_providers.containsKey(name)) {
      throw ArgumentError('Provider with name "$name" already exists');
    }

    final provider = RiverpodStateProvider<T>(
      name: name,
      initialValue: initialValue,
      container: _container!,
    );

    _providers[name] = provider as RiverpodStateProvider<Object?>;
    return provider;
  }

  @override
  T read<T>(StateProvider<T> provider) {
    if (!isInitialized) {
      throw StateError(
        'RiverpodStateManager not initialized. Call initialize() first.',
      );
    }

    if (provider is! RiverpodStateProvider<T>) {
      throw ArgumentError(
        'Provider must be a RiverpodStateProvider. '
        'Use createProvider() to create providers.',
      );
    }

    return provider.read();
  }

  @override
  T watch<T>(StateProvider<T> provider) {
    if (!isInitialized) {
      throw StateError(
        'RiverpodStateManager not initialized. Call initialize() first.',
      );
    }

    if (provider is! RiverpodStateProvider<T>) {
      throw ArgumentError(
        'Provider must be a RiverpodStateProvider. '
        'Use createProvider() to create providers.',
      );
    }

    // Note: Riverpod's watch() requires a WidgetRef, which is context-dependent.
    // For watching in widgets, use Consumer or ConsumerWidget with the provider directly:
    // Consumer(builder: (context, ref, child) {
    //   final value = ref.watch(provider.provider);
    //   return YourWidget(value: value);
    // })
    // For non-widget contexts, use read() instead.
    // This method is kept for interface compatibility but delegates to read().
    return provider.read();
  }

  @override
  void update<T>(StateProvider<T> provider, T value) {
    if (!isInitialized) {
      throw StateError(
        'RiverpodStateManager not initialized. Call initialize() first.',
      );
    }

    if (provider is! RiverpodStateProvider<T>) {
      throw ArgumentError(
        'Provider must be a RiverpodStateProvider. '
        'Use createProvider() to create providers.',
      );
    }

    provider.update(value);
  }

  @override
  void dispose<T>(StateProvider<T> provider) {
    if (provider is! RiverpodStateProvider<T>) {
      throw ArgumentError(
        'Provider must be a RiverpodStateProvider. '
        'Use createProvider() to create providers.',
      );
    }

    _providers.remove(provider.name);
    provider.dispose();
  }

  @override
  bool get isInitialized => _container != null;

  @override
  void dispose() {
    for (final provider in _providers.values) {
      provider.dispose();
    }
    _providers.clear();
    _container?.dispose();
    _container = null;
  }

  /// Gets the underlying Riverpod ProviderContainer.
  ///
  /// This allows direct access to Riverpod-specific features when needed.
  /// Use with caution as it breaks the abstraction.
  ProviderContainer? get container => _container;
}

*/
