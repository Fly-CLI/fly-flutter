import 'app_event.dart';
import 'managers/event_stream_manager.dart';

/// Registry entry for a controller
class ControllerRegistryEntry {
  /// Unique identifier for this controller
  final String key;

  /// The event type this controller handles
  final Type eventType;

  /// The manager instance for this controller
  final IEventStreamManager<AppEvent> manager;

  /// Type matcher function that checks if an event matches this entry's type
  final bool Function(AppEvent) typeMatcher;

  ControllerRegistryEntry({
    required this.key,
    required this.eventType,
    required this.manager,
    required this.typeMatcher,
  });
}

/// Generic app event emitter
///
/// Manages a dynamic registry of controllers.
/// All APIs work with AppEvent base class.
/// No concrete event types in this class.
///
/// **Key Principles:**
/// - Generic APIs only - work with AppEvent base class
/// - Dynamic registry - controllers added/removed at runtime
/// - No hardcoded event types
/// - Type-safe registration with generic type parameter
///
/// **Thread Safety:** Designed for single-threaded Flutter main isolate usage.
/// **Lifecycle:** Always call `dispose()` when disposing the emitter.
///
/// Example:
/// ```dart
/// final emitter = AppEventEmitter();
/// emitter.register<NavigationEvent>(
///   key: 'navigation',
///   manager: EventStreamManager.create<NavigationEvent>(),
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
class AppEventEmitter {
  final List<ControllerRegistryEntry> _controllers = [];
  final Map<Type, ControllerRegistryEntry> _typeRegistry = {};
  bool _isDisposed = false;

  /// Register a controller for a specific event type using a string key
  ///
  /// [T] - The event type (NavigationEvent, ScreenEvent, etc.)
  /// [key] - Unique identifier for this controller
  /// [manager] - The stream manager for this event type
  ///
  /// Throws [StateError] if a controller with the same key already exists.
  void register<T extends AppEvent>({
    required String key,
    required IEventStreamManager<T> manager,
  }) {
    if (_isDisposed) {
      throw StateError('Event emitter has been disposed');
    }

    // Check if key already exists
    if (_controllers.any((entry) => entry.key == key)) {
      throw StateError('Controller with key "$key" is already registered');
    }

    final entry = ControllerRegistryEntry(
      key: key,
      eventType: T,
      manager: manager as IEventStreamManager<AppEvent>,
      typeMatcher: (event) => event is T,
    );

    _controllers.add(entry);
    _typeRegistry[T] = entry;
  }

  /// Register a controller for a specific event type using the type itself as the key
  ///
  /// This is a type-safe alternative to `register<T>(key: ...)` that eliminates
  /// the need for magic strings. The event type `T` is used as the implicit key.
  ///
  /// [T] - The event type (NavigationEvent, ScreenEvent, etc.)
  /// [manager] - Optional manager instance. If not provided, a default manager is created.
  ///
  /// Throws [StateError] if a controller for this type is already registered.
  ///
  /// Example:
  /// ```dart
  /// emitter.registerType<NavigationEvent>();
  /// // Equivalent to: emitter.register<NavigationEvent>(key: 'NavigationEvent', manager: ...)
  /// ```
  void registerType<T extends AppEvent>({
    IEventStreamManager<T>? manager,
  }) {
    if (_isDisposed) {
      throw StateError('Event emitter has been disposed');
    }

    // Check if type already registered
    if (_typeRegistry.containsKey(T)) {
      throw StateError(
        'Controller for type "${T.toString()}" is already registered',
      );
    }

    final effectiveManager = manager ?? EventStreamManager.create<T>();
    final key = T.toString();

    final entry = ControllerRegistryEntry(
      key: key,
      eventType: T,
      manager: effectiveManager as IEventStreamManager<AppEvent>,
      typeMatcher: (event) => event is T,
    );

    _controllers.add(entry);
    _typeRegistry[T] = entry;
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
    _typeRegistry.remove(entry.eventType);
    _controllers.removeAt(index);
    return true;
  }

  /// Unregister a controller by type
  ///
  /// Returns true if the controller was found and removed, false otherwise.
  /// The controller is disposed before removal.
  bool unregisterType<T extends AppEvent>() {
    final entry = _typeRegistry.remove(T);
    if (entry == null) {
      return false;
    }

    entry.manager.dispose();
    _controllers.remove(entry);
    return true;
  }

  /// Get stream by key
  ///
  /// Returns the stream for the given key, or null if not found.
  /// The stream returns AppEvent (base type), use type checking/casting for specific types.
  ///
  /// **Type Safety Note:** This method returns `Stream<AppEvent>?` (base type).
  /// For type-safe access to specific event types, use `getStreamFor<T>()` instead.
  ///
  /// Example:
  /// ```dart
  /// // Type-safe (recommended)
  /// emitter.getStreamFor<NavigationEvent>().listen((event) {
  ///   if (event is NavigationStartedEvent) {
  ///     // Handle navigation started
  ///   }
  /// });
  ///
  /// // Generic (less type-safe, uses string keys)
  /// emitter.getStream('navigation')?.listen((event) {
  ///   if (event is NavigationStartedEvent) {
  ///     // Handle navigation started
  ///   }
  /// });
  /// ```
  Stream<AppEvent>? getStream(String key) {
    if (_isDisposed) {
      return null;
    }

    final entry = _controllers.firstWhere(
      (e) => e.key == key,
      orElse: () => throw StateError('No controller registered with key "$key"'),
    );

    // Return as base type - use getStreamFor<T>() for type-safe access
    return entry.manager.stream;
  }

  /// Get type-safe stream for a specific event type
  ///
  /// Returns a strongly-typed stream for the given event type `T`.
  /// Returns an empty stream if the type is not registered.
  ///
  /// This is the recommended way to access event streams as it provides
  /// compile-time type safety and eliminates the need for magic strings.
  ///
  /// [T] - The event type to get the stream for
  ///
  /// Example:
  /// ```dart
  /// final stream = emitter.getStreamFor<NavigationEvent>();
  /// stream.listen((event) {
  ///   // event is NavigationEvent, not AppEvent
  ///   if (event is NavigationStartedEvent) {
  ///     // Handle navigation started
  ///   }
  /// });
  /// ```
  Stream<T> getStreamFor<T extends AppEvent>() {
    if (_isDisposed) {
      return Stream<T>.empty();
    }

    final entry = _typeRegistry[T];
    if (entry == null) {
      return Stream<T>.empty();
    }

    return entry.manager.stream.cast<T>();
  }

  /// Get all registered keys
  ///
  /// Returns a list of all registered controller keys.
  List<String> get registeredKeys => _controllers.map((e) => e.key).toList();

  /// Check if a key is registered
  bool isRegistered(String key) {
    return _controllers.any((entry) => entry.key == key);
  }

  /// Check if a type is registered
  bool isTypeRegistered<T extends AppEvent>() {
    return _typeRegistry.containsKey(T);
  }

  /// Emit event to all matching controllers
  ///
  /// Emits the event to all controllers that handle the event's type.
  /// Returns true if the event was emitted to at least one controller, false otherwise.
  ///
  /// [event] - The app event to emit
  bool emit(AppEvent event) {
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
    _typeRegistry.clear();
  }
}

