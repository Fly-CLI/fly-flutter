import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global ProviderContainer singleton for the entire app
///
/// Provides a centralized access point to the ProviderContainer with
/// support for testing through the [overrideForTesting] method.
class GlobalContainer {
  /// Private constructor to prevent instantiation
  GlobalContainer._();

  static ProviderContainer? _instance;

  /// Gets the current ProviderContainer instance
  ///
  /// Throws [StateError] if accessed before initialization.
  /// Call [initialize] first during app startup.
  static ProviderContainer get instance {
    if (_instance == null) {
      throw StateError(
        'GlobalContainer not initialized. Call GlobalContainer.initialize() first.',
      );
    }
    return _instance!;
  }

  /// Initializes the global container
  ///
  /// Should be called once during app startup in main().
  /// Throws [StateError] if called more than once.
  static void initialize() {
    if (_instance != null) {
      throw StateError('GlobalContainer already initialized');
    }
    _instance = ProviderContainer();
  }

  /// Overrides the container for testing purposes
  ///
  /// This should only be used in tests to provide a custom container
  /// with overridden providers. In production code, use [initialize] instead.
  static void overrideForTesting(ProviderContainer testContainer) {
    _instance = testContainer;
  }

  /// Resets the container (useful for testing)
  ///
  /// Disposes the current container and clears the instance.
  /// This allows tests to start with a fresh container.
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }

  /// Checks if the container has been initialized
  ///
  /// Returns `true` if [initialize] or [overrideForTesting] has been called.
  /// Returns `false` if not initialized or after [reset] has been called.
  static bool get isInitialized => _instance != null;
}

