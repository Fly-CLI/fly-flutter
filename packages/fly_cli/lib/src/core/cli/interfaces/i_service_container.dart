/// Interface for service container dependency injection
///
/// This interface provides abstraction over the service container implementation,
/// allowing for easier testing and swapping of implementations.
abstract class IServiceContainer {
  /// Register a singleton service
  ///
  /// [instance] - The service instance to register
  void registerSingleton<T>(T instance);

  /// Register a factory (for lazy singletons)
  ///
  /// [factory] - The factory function to create the service
  void registerFactory<T>(T Function() factory);

  /// Get a service
  ///
  /// Throws an exception if the service is not registered.
  ///
  /// [T] - The type of service to retrieve
  T get<T>();

  /// Check if a service is registered
  ///
  /// Returns true if the service is registered, false otherwise.
  ///
  /// [T] - The type of service to check
  bool isRegistered<T>();
}
