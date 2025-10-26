/// Service registration types
enum ServiceLifetime {
  /// Create new instance each time
  transient,
  
  /// Create once per scope
  scoped,
  
  /// Create once for entire application lifetime
  singleton,
}

/// Service registration descriptor
class ServiceDescriptor {
  const ServiceDescriptor({
    required this.serviceType,
    required this.implementationType,
    required this.factory,
    required this.lifetime,
  });

  final Type serviceType;
  final Type implementationType;
  final ServiceFactory factory;
  final ServiceLifetime lifetime;
}

/// Factory function for creating service instances
typedef ServiceFactory = dynamic Function(ServiceContainer container);

/// Service container for dependency injection
class ServiceContainer {
  ServiceContainer();

  final Map<Type, ServiceDescriptor> _services = {};
  final Map<Type, dynamic> _instances = {};
  final Set<Type> _building = {};

  /// Register a service with factory function
  ServiceContainer register<T>(
    ServiceFactory factory, {
    ServiceLifetime lifetime = ServiceLifetime.transient,
  }) {
    _services[T] = ServiceDescriptor(
      serviceType: T,
      implementationType: T,
      factory: factory,
      lifetime: lifetime,
    );
    return this;
  }

  /// Register a service with implementation type
  ServiceContainer registerType<T, TImpl>(
    ServiceFactory factory, {
    ServiceLifetime lifetime = ServiceLifetime.transient,
  }) {
    _services[T] = ServiceDescriptor(
      serviceType: T,
      implementationType: TImpl,
      factory: factory,
      lifetime: lifetime,
    );
    return this;
  }

  /// Register a singleton service
  ServiceContainer registerSingleton<T>(T instance) {
    _services[T] = ServiceDescriptor(
      serviceType: T,
      implementationType: T,
      factory: (_) => instance,
      lifetime: ServiceLifetime.singleton,
    );
    _instances[T] = instance;
    return this;
  }

  /// Register a singleton service with factory
  ServiceContainer registerSingletonFactory<T>(
    ServiceFactory factory,
  ) {
    _services[T] = ServiceDescriptor(
      serviceType: T,
      implementationType: T,
      factory: factory,
      lifetime: ServiceLifetime.singleton,
    );
    return this;
  }

  /// Get a service instance
  T get<T>() {
    final descriptor = _services[T];
    if (descriptor == null) {
      throw ServiceNotFoundException('Service of type $T is not registered');
    }

    // Return singleton instance if exists
    if (descriptor.lifetime == ServiceLifetime.singleton) {
      if (_instances.containsKey(T)) {
        return _instances[T] as T;
      }
    }

    // Check for circular dependencies
    if (_building.contains(T)) {
      throw CircularDependencyException('Circular dependency detected for type $T');
    }

    try {
      _building.add(T);
      final instance = descriptor.factory(this) as T;
      
      // Cache singleton instances
      if (descriptor.lifetime == ServiceLifetime.singleton) {
        _instances[T] = instance;
      }
      
      return instance;
    } finally {
      _building.remove(T);
    }
  }

  /// Try to get a service instance, returns null if not registered
  T? tryGet<T>() {
    try {
      return get<T>();
    } on ServiceNotFoundException {
      return null;
    }
  }

  /// Check if a service is registered
  bool isRegistered<T>() => _services.containsKey(T);

  /// Clear all registrations and instances
  void clear() {
    _services.clear();
    _instances.clear();
    _building.clear();
  }

  /// Get all registered service types
  Iterable<Type> get registeredTypes => _services.keys;
}

/// Exception thrown when a service is not found
class ServiceNotFoundException implements Exception {
  const ServiceNotFoundException(this.message);
  final String message;
  
  @override
  String toString() => 'ServiceNotFoundException: $message';
}

/// Exception thrown when circular dependency is detected
class CircularDependencyException implements Exception {
  const CircularDependencyException(this.message);
  final String message;
  
  @override
  String toString() => 'CircularDependencyException: $message';
}
