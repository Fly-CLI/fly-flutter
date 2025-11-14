import 'package:fly_navigation/src/navigation_service.dart';

/// AutoRoute implementation of [NavigationService].
///
/// This implementation uses AutoRoute as the underlying navigation framework.
/// It provides a bridge between the abstract [NavigationService] interface
/// and AutoRoute's specific APIs.
///
/// ## Usage
///
/// ```dart
/// final appRouter = AppRouter();
///
/// final service = AutoRouteNavigationService(router: appRouter);
/// await service.navigateTo('/home');
/// ```
///
/// Note: This implementation requires the `auto_route` package.
/// This is a placeholder implementation and will be fully implemented in Phase 3.
class AutoRouteNavigationService implements NavigationService<String> {
  /// Creates an AutoRouteNavigationService
  ///
  /// [router] - The AutoRoute router instance to use for navigation
  AutoRouteNavigationService({required this.router});

  /// The AutoRoute router instance to use for navigation
  // ignore: avoid_relative_lib_imports
  final dynamic router; // Using dynamic to avoid direct dependency

  @override
  Future<T?> navigateTo<T>(String route, {Object? arguments}) {
    throw UnimplementedError(
      'AutoRoute navigation is not yet implemented. '
      'Use StandardNavigator or GoRouterNavigationService for now.',
    );
  }

  @override
  void navigateBack<T>([T? result]) {
    throw UnimplementedError(
      'AutoRoute navigation is not yet implemented. '
      'Use StandardNavigator or GoRouterNavigationService for now.',
    );
  }

  @override
  Future<T?> navigateReplace<T>(String route, {Object? arguments}) {
    throw UnimplementedError(
      'AutoRoute navigation is not yet implemented. '
      'Use StandardNavigator or GoRouterNavigationService for now.',
    );
  }

  @override
  Future<T?> navigateClearStack<T>(String route, {Object? arguments}) {
    throw UnimplementedError(
      'AutoRoute navigation is not yet implemented. '
      'Use StandardNavigator or GoRouterNavigationService for now.',
    );
  }

  @override
  bool canGoBack() {
    throw UnimplementedError(
      'AutoRoute navigation is not yet implemented. '
      'Use StandardNavigator or GoRouterNavigationService for now.',
    );
  }
}

