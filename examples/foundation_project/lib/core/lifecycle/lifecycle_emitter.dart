import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';
import 'package:foundation_project/core/lifecycle/managers/event_stream_manager.dart';
import 'package:foundation_project/shared/localization/localizations.dart';

/// Registry entry for a controller
class ControllerRegistryEntry {
  /// Unique identifier for this controller
  final String key;

  /// The event type this controller handles
  final Type eventType;

  /// The manager instance for this controller
  final IEventStreamManager<LifecycleEvent> manager;

  /// Type matcher function that checks if an event matches this entry's type
  final bool Function(LifecycleEvent) typeMatcher;

  ControllerRegistryEntry({
    required this.key,
    required this.eventType,
    required this.manager,
    required this.typeMatcher,
  });
}

/// Generic lifecycle event emitter
///
/// Manages a dynamic registry of controllers.
/// All APIs work with LifecycleEvent base class.
/// No concrete event types in this class.
///
/// **Key Principles:**
/// - Generic APIs only - work with LifecycleEvent base class
/// - Dynamic registry - controllers added/removed at runtime
/// - No hardcoded event types
/// - Type-safe registration with generic type parameter
///
/// **Thread Safety:** Designed for single-threaded Flutter main isolate usage.
/// **Lifecycle:** Always call `dispose()` when disposing the emitter.
///
/// Example:
/// ```dart
/// final emitter = AppLifecycleEmitter();
/// emitter.register<NavigationEvent>(
///   key: 'navigation',
///   manager: NavigationStreamManager(),
/// );
///
/// emitter.getStream('navigation')?.listen((event) {
///   if (event is NavigationStartedEvent) {
///     // Handle navigation started
///   }
/// });
///
/// emitter.emit(NavigationStartedEvent(feature: Feature.home));
/// ```
class AppLifecycleEmitter {
  final List<ControllerRegistryEntry> _controllers = [];
  bool _isDisposed = false;

  /// Register a controller for a specific event type
  ///
  /// [T] - The event type (NavigationEvent, ScreenEvent, etc.)
  /// [key] - Unique identifier for this controller
  /// [manager] - The stream manager for this event type
  ///
  /// Throws [StateError] if a controller with the same key already exists.
  void register<T extends LifecycleEvent>({
    required String key,
    required IEventStreamManager<T> manager,
  }) {
    if (_isDisposed) {
      throw StateError(localizations.lifecycleEmitterDisposed);
    }

    // Check if key already exists
    if (_controllers.any((entry) => entry.key == key)) {
      throw StateError(localizations.lifecycleControllerAlreadyRegistered(key));
    }

    _controllers.add(ControllerRegistryEntry(
      key: key,
      eventType: T,
      manager: manager as IEventStreamManager<LifecycleEvent>,
      typeMatcher: (event) => event is T,
    ),);
  }

  /// Unregister a controller by key
  ///
  /// Returns true if the controller was found and removed, false otherwise.
  /// The controller is disposed before removal.
  bool unregister(String key) {
    final index = _controllers.indexWhere((entry) => entry.key == key);
    if (index == -1) {
      return false;
    }

    final entry = _controllers[index];
    entry.manager.dispose();
    _controllers.removeAt(index);
    return true;
  }

  /// Get stream by key
  ///
  /// Returns the stream for the given key, or null if not found.
  /// The stream returns LifecycleEvent (base type), use type checking/casting for specific types.
  ///
  /// **Type Safety Note:** This method returns `Stream<LifecycleEvent>?` (base type).
  /// For type-safe access to specific event types, use the extension methods:
  /// - `getNavigationStream()` for NavigationEvent
  /// - `getScreenStream()` for ScreenEvent
  /// - `getEventsOfType<T>(key)` for custom event types
  ///
  /// Example:
  /// ```dart
  /// // Type-safe (recommended)
  /// emitter.getNavigationStream().listen((event) {
  ///   if (event is NavigationStartedEvent) {
  ///     // Handle navigation started
  ///   }
  /// });
  ///
  /// // Generic (less type-safe)
  /// emitter.getStream('navigation')?.listen((event) {
  ///   if (event is NavigationStartedEvent) {
  ///     // Handle navigation started
  ///   }
  /// });
  /// ```
  Stream<LifecycleEvent>? getStream(String key) {
    if (_isDisposed) {
      return null;
    }

    final entry = _controllers.firstWhere(
      (e) => e.key == key,
      orElse: () => throw StateError(localizations.lifecycleNoControllerRegistered(key)),
    );

    // Return as base type - use extensions for type-safe access
    return entry.manager.stream;
  }

  /// Get all registered keys
  ///
  /// Returns a list of all registered controller keys.
  List<String> get registeredKeys => _controllers.map((e) => e.key).toList();

  /// Check if a key is registered
  bool isRegistered(String key) {
    return _controllers.any((entry) => entry.key == key);
  }

  /// Emit event to all matching controllers
  ///
  /// Emits the event to all controllers that handle the event's type.
  /// Returns true if the event was emitted to at least one controller, false otherwise.
  ///
  /// [event] - The lifecycle event to emit
  bool emit(LifecycleEvent event) {
    if (_isDisposed) {
      return false;
    }

    bool emitted = false;

    for (final entry in _controllers) {
      // Use type matcher to check if this controller handles this event type
      // This properly handles sealed class hierarchies where concrete events
      // (e.g., NavigationStartedEvent) should match base types (e.g., NavigationEvent)
      if (entry.typeMatcher(event)) {
        if (entry.manager.emit(event)) {
          emitted = true;
        }
      }
    }

    return emitted;
  }

  /// Check if emitter is disposed
  bool get isDisposed => _isDisposed;

  /// Dispose all controllers
  ///
  /// MUST be called when the emitter is disposed to prevent memory leaks.
  /// Disposes all registered controllers and clears the registry.
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;

    for (final entry in _controllers) {
      entry.manager.dispose();
    }

    _controllers.clear();
  }
}
