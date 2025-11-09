import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fly_navigation/src/app.dart';
import 'package:fly_navigation/src/standard_navigation_service.dart';
import 'package:fly_navigation/src/navigation_service.dart';

/// Provider for NavigationService
///
/// Default implementation uses standard Flutter Navigator.
/// Override this provider to use custom routing libraries
/// (go_router, auto_route, etc.).
///
/// Example override for GoRouter:
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
/// For Mason brick template generation, the NavigatorKey should be a
/// template variable:
/// ```dart
/// final navigationServiceProvider =
///     Provider<NavigationService<String>>((ref) {
///   return DefaultNavigationService(
///     navigatorKey: {{navigator_key}}, // Template variable
///   );
/// });
/// ```
///
/// For Feature enum-based navigation, use AppNavigation directly:
/// ```dart
/// final appNavigationProvider =
///     Provider<NavigationService<Feature>>((ref) {
///   return AppNavigation.instance;
/// });
/// ```
final navigationServiceProvider = Provider<NavigationService<String>>((ref) {
  return StandardNavigationService(
    navigatorKey: App.navigatorKey,
  );
});
