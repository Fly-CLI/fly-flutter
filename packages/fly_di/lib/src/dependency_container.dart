/// Abstract interface for dependency injection containers.
///
/// This interface abstracts away the specific implementation details of
/// dependency injection frameworks (like Riverpod, GetIt, etc.), allowing
/// the foundation to work with any DI framework.
///
/// ## Purpose
///
/// By using this interface, foundation components can access dependencies
/// without being tightly coupled to a specific DI framework. This makes
/// the foundation more flexible and testable.
///
/// ## Implementation
///
/// Applications should provide an implementation of this interface for their
/// chosen DI framework. For Riverpod-based projects, use [RiverpodDependencyContainer].
///
/// ## Usage
///
/// ```dart
/// // In your app initialization
/// final container = RiverpodDependencyContainer();
/// DependencyContainer.setInstance(container);
/// container.initialize();
///
/// // In your components
/// final logger = DependencyContainer.instance.read<FlyLogger>(loggerProvider);
/// ```
///
/// ## Testing
///
/// ```dart
/// // In tests
/// final testContainer = MockDependencyContainer();
/// DependencyContainer.setInstance(testContainer);
/// testContainer.initialize();
/// ```
abstract class DependencyContainer {
  /// Gets the current dependency container instance.
  ///
  /// Throws [StateError] if accessed before initialization.
  /// Call [initialize] first during app startup.
  static DependencyContainer get instance {
    if (_instance == null) {
      throw StateError(
        'DependencyContainer not initialized. '
        'Call DependencyContainer.setInstance() and then initialize() first.',
      );
    }
    return _instance!;
  }

  /// Sets the global dependency container instance.
  ///
  /// This should be called once during app startup before [initialize].
  /// Typically called in `main()` before any components access dependencies.
  ///
  /// Throws [StateError] if an instance is already set.
  static void setInstance(DependencyContainer container) {
    if (_instance != null) {
      throw StateError(
        'DependencyContainer instance already set. '
        'Call reset() first if you need to replace it.',
      );
    }
    _instance = container;
  }

  /// Resets the global dependency container instance.
  ///
  /// Useful for testing to allow setting a new instance.
  /// Disposes the current container before clearing.
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }

  /// Checks if a dependency container instance has been set.
  ///
  /// Returns `true` if [setInstance] has been called.
  /// Returns `false` if not set or after [reset] has been called.
  static bool get isSet => _instance != null;

  static DependencyContainer? _instance;

  /// Initializes the dependency container.
  ///
  /// Should be called once during app startup after [setInstance].
  /// Throws [StateError] if called more than once.
  void initialize();

  /// Reads a dependency from the container.
  ///
  /// [provider] - The provider or key to read from the container.
  ///
  /// Returns the dependency instance.
  ///
  /// Throws [StateError] if the container is not initialized.
  /// Throws [ArgumentError] if the provider is not found.
  T read<T>(Object provider);

  /// Checks if the container has been initialized.
  ///
  /// Returns `true` if [initialize] has been called.
  /// Returns `false` otherwise.
  bool get isInitialized;

  /// Disposes the container and cleans up resources.
  ///
  /// Should be called when the container is no longer needed,
  /// typically during app shutdown or test teardown.
  void dispose();
}

