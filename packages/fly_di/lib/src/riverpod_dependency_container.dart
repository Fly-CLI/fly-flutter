import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fly_di/src/dependency_container.dart';
import 'package:fly_di/src/global_container.dart';

/// Riverpod-based implementation of [DependencyContainer].
///
/// This implementation wraps the existing [GlobalContainer] to provide
/// a framework-agnostic interface for dependency injection.
///
/// ## Usage
///
/// ```dart
/// void main() {
///   final container = RiverpodDependencyContainer();
///   DependencyContainer.setInstance(container);
///   container.initialize();
///
///   // Now you can use DependencyContainer.instance.read() throughout your app
///   runApp(MyApp());
/// }
/// ```
///
/// ## Testing
///
/// ```dart
/// void main() {
///   test('my test', () {
///     final testContainer = ProviderContainer(
///       overrides: [myProvider.overrideWith((ref) => MockService())],
///     );
///     final container = RiverpodDependencyContainer.withContainer(testContainer);
///     DependencyContainer.setInstance(container);
///     container.initialize();
///
///     // Your test code here
///
///     DependencyContainer.reset();
///   });
/// }
/// ```
class RiverpodDependencyContainer implements DependencyContainer {
  ProviderContainer? _container;
  final ProviderContainer? _preInitializedContainer;

  /// Creates a new [RiverpodDependencyContainer].
  ///
  /// The container will be initialized when [initialize] is called.
  RiverpodDependencyContainer() : _preInitializedContainer = null;

  /// Creates a [RiverpodDependencyContainer] with a pre-initialized container.
  ///
  /// This is useful for testing when you want to provide a custom container
  /// with overridden providers.
  ///
  /// [container] - The pre-initialized ProviderContainer to use.
  RiverpodDependencyContainer.withContainer(ProviderContainer container)
      : _preInitializedContainer = container,
        _container = null;

  @override
  void initialize() {
    if (_container != null || _preInitializedContainer != null) {
      throw StateError('RiverpodDependencyContainer already initialized');
    }

    // Use GlobalContainer for backward compatibility
    if (!GlobalContainer.isInitialized) {
      GlobalContainer.initialize();
    }
    _container = GlobalContainer.instance;
  }

  @override
  T read<T>(Object provider) {
    final container = _preInitializedContainer ?? _container;
    if (container == null) {
      throw StateError(
        'RiverpodDependencyContainer not initialized. Call initialize() first.',
      );
    }

    try {
      // ProviderContainer.read accepts ProviderListenable<T>
      // We cast to dynamic to avoid type checking issues since ProviderBase
      // might not be exported from flutter_riverpod
      return container.read<T>(provider as dynamic);
    } catch (e) {
      throw ArgumentError(
        'Failed to read provider ${provider.runtimeType}: $e',
      );
    }
  }

  @override
  bool get isInitialized =>
      _container != null || _preInitializedContainer != null;

  @override
  void dispose() {
    // Only dispose if we created the container ourselves
    // Don't dispose pre-initialized containers (they're managed externally)
    if (_container != null && _preInitializedContainer == null) {
      // Don't dispose GlobalContainer.instance as it might be used elsewhere
      // Just clear our reference
      _container = null;
    }
  }

  /// Gets the underlying ProviderContainer.
  ///
  /// This allows direct access to Riverpod-specific features when needed.
  /// Use sparingly to maintain framework independence.
  ProviderContainer? get providerContainer =>
      _preInitializedContainer ?? _container;
}

