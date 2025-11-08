import 'package:flutter/material.dart';
import 'package:fly_navigation/src/navigation_service.dart';

/// Default implementation of NavigationService using standard Flutter Navigator
///
/// This implementation uses a global NavigatorKey to perform navigation
/// operations without requiring BuildContext.
///
/// Example usage:
/// ```dart
/// final service = DefaultNavigationService(
///   navigatorKey: App.navigatorKey,
/// );
/// await service.navigateTo('/home');
/// ```
class DefaultNavigationService implements NavigationService<String> {
  /// Creates a DefaultNavigationService
  ///
  /// [navigatorKey] - The global NavigatorKey to use for navigation
  DefaultNavigationService({required this.navigatorKey});

  /// The NavigatorKey to use for navigation
  final GlobalKey<NavigatorState> navigatorKey;

  /// Navigate to a route
  ///
  /// [route] - The route to navigate to
  /// [arguments] - Optional arguments to pass to the route
  @override
  Future<T?> navigateTo<T>(String route, {Object? arguments}) {
    final state = navigatorKey.currentState;
    if (state == null) {
      throw StateError(
        'Navigator not initialized. Ensure navigatorKey is attached '
        'to a Navigator widget.',
      );
    }
    return state.pushNamed<T>(route, arguments: arguments);
  }

  /// Navigate back with optional result
  ///
  /// [result] - Optional result value to return to the previous route
  @override
  void navigateBack<T>([T? result]) {
    final state = navigatorKey.currentState;
    if (state == null) {
      throw StateError(
        'Navigator not initialized. Ensure navigatorKey is attached '
        'to a Navigator widget.',
      );
    }
    if (state.canPop()) {
      state.pop<T>(result);
    }
  }

  /// Navigate and replace current route
  ///
  /// [route] - The route to navigate to
  /// [arguments] - Optional arguments to pass to the route
  @override
  Future<T?> navigateReplace<T>(String route, {Object? arguments}) {
    final state = navigatorKey.currentState;
    if (state == null) {
      throw StateError(
        'Navigator not initialized. Ensure navigatorKey is attached '
        'to a Navigator widget.',
      );
    }
    return state.pushReplacementNamed<T, void>(
      route,
      arguments: arguments,
    );
  }

  /// Navigate and clear entire stack
  ///
  /// [route] - The route to navigate to
  /// [arguments] - Optional arguments to pass to the route
  @override
  Future<T?> navigateClearStack<T>(String route, {Object? arguments}) {
    final state = navigatorKey.currentState;
    if (state == null) {
      throw StateError(
        'Navigator not initialized. Ensure navigatorKey is attached '
        'to a Navigator widget.',
      );
    }
    return state.pushNamedAndRemoveUntil<T>(
      route,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Check if can navigate back
  ///
  /// Returns true if there is a route that can be popped.
  @override
  bool canGoBack() {
    final state = navigatorKey.currentState;
    if (state == null) {
      return false;
    }
    return state.canPop();
  }
}
