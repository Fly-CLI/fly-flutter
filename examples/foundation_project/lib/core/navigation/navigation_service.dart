/// Abstract interface for navigation operations with generic route types
///
/// [R] - The route type (e.g., String, Feature enum, custom route class)
///
/// This interface provides router-agnostic navigation functionality,
/// allowing projects to use Navigator, go_router, auto_route, or any
/// other navigation solution by implementing this interface.
///
/// The service uses a global NavigatorKey internally, eliminating the
/// need for BuildContext in navigation operations.
///
/// Route types must be convertible to String for underlying navigation.
/// For example:
/// - String routes work directly
/// - Feature enum has a `route` property (String)
/// - Custom types should provide String conversion
///
/// Example usage:
/// ```dart
/// // String-based service
/// NavigationService<String> service;
/// await service.navigateTo('/home');
///
/// // Feature enum-based service
/// NavigationService<Feature> service;
/// await service.navigateTo(Feature.home);
/// ```
abstract class NavigationService<R> {
  /// Navigate to a route
  ///
  /// [route] - The route to navigate to (type R)
  /// [arguments] - Optional arguments to pass to the route
  ///
  /// Returns a Future that completes when the route is popped, with
  /// the optional result value.
  Future<T?> navigateTo<T>(R route, {Object? arguments});

  /// Navigate back with optional result
  ///
  /// [result] - Optional result value to return to the previous route
  void navigateBack<T>([T? result]);

  /// Navigate and replace current route
  ///
  /// [route] - The route to navigate to (type R)
  /// [arguments] - Optional arguments to pass to the route
  ///
  /// Returns a Future that completes when the route is popped, with
  /// the optional result value.
  Future<T?> navigateReplace<T>(R route, {Object? arguments});

  /// Navigate and clear entire stack
  ///
  /// [route] - The route to navigate to (type R)
  /// [arguments] - Optional arguments to pass to the route
  ///
  /// Returns a Future that completes when the route is popped, with
  /// the optional result value.
  Future<T?> navigateClearStack<T>(R route, {Object? arguments});

  /// Check if can navigate back
  ///
  /// Returns true if there is a route that can be popped.
  bool canGoBack();
}
