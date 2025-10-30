/// Simple service container for dependency injection
class ServiceContainer {
  /// Creates a new service container
  ServiceContainer();

  final Map<Type, dynamic> _singletons = {};
  final Map<Type, dynamic Function()> _factories = {};

  /// Register a singleton service
  void registerSingleton<T>(T instance) {
    _singletons[T] = instance;
  }

  /// Register a factory (for lazy singletons)
  void registerFactory<T>(T Function() factory) {
    _factories[T] = factory;
  }

  /// Get a service
  T get<T>() {
    // Check if we have a singleton
    if (_singletons.containsKey(T)) {
      return _singletons[T] as T;
    }

    // Check if we have a factory
    if (_factories.containsKey(T)) {
      final instance = _factories[T]!() as T;
      _singletons[T] = instance; // Cache it
      return instance;
    }

    throw Exception('Service of type $T not registered');
  }

  /// Check if a service is registered
  bool isRegistered<T>() => 
    _singletons.containsKey(T) || _factories.containsKey(T);
}