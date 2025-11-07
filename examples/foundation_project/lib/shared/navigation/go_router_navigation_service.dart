import 'package:go_router/go_router.dart';
import 'package:foundation_project/core/foundation/navigation/navigation_service.dart';

/// Example implementation of NavigationService using GoRouter
///
/// This is an optional example showing how to implement NavigationService
/// for projects using GoRouter. It demonstrates how to override the default
/// NavigationService provider to use a custom routing library.
///
/// To use this implementation, override the navigationServiceProvider:
/// ```dart
/// final container = ProviderContainer(
///   overrides: [
///     navigationServiceProvider.overrideWithValue(
///       GoRouterNavigationService(router: AppRouter.router),
///     ),
///   ],
/// );
/// ```
///
/// This file is in the shared/ folder because it's project-specific and
/// not part of the core reusable foundation.
class GoRouterNavigationService implements NavigationService<String> {
  /// The GoRouter instance to use for navigation
  final GoRouter router;

  /// Creates a GoRouterNavigationService
  ///
  /// [router] - The GoRouter instance to use for navigation
  GoRouterNavigationService({required this.router});

  @override
  Future<T?> navigateTo<T>(String route, {Object? arguments}) async {
    // GoRouter doesn't return a Future from go(), so we use a completer
    // In practice, GoRouter's navigation is synchronous from the API perspective
    // The result is typically handled through the route's builder or listeners
    router.go(route, extra: arguments);
    
    // Since GoRouter doesn't provide a direct way to get the result when
    // a route is popped, we return null. In practice, results are typically
    // handled through state management or callbacks.
    return null;
  }

  @override
  void navigateBack<T>([T? result]) {
    if (router.canPop()) {
      router.pop(result);
    }
  }

  @override
  Future<T?> navigateReplace<T>(String route, {Object? arguments}) async {
    // GoRouter's pushReplacement is done via go() with a new route
    // The old route is replaced by the new one
    router.go(route, extra: arguments);
    return null;
  }

  @override
  Future<T?> navigateClearStack<T>(String route, {Object? arguments}) async {
    // GoRouter's pushNamedAndRemoveUntil equivalent is go() followed by
    // navigating to the route, which clears the stack
    // Note: GoRouter manages routes differently, so this is a simplified approach
    router.go(route, extra: arguments);
    return null;
  }

  @override
  bool canGoBack() {
    return router.canPop();
  }
}

