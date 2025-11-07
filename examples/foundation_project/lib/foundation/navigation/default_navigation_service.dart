import 'package:flutter/material.dart';
import 'package:foundation_project/foundation/navigation/navigation_service.dart';

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
  /// The NavigatorKey to use for navigation
  final GlobalKey<NavigatorState> navigatorKey;

  /// Creates a DefaultNavigationService
  ///
  /// [navigatorKey] - The global NavigatorKey to use for navigation
  DefaultNavigationService({required this.navigatorKey});

  @override
  Future<T?> navigateTo<T>(String route, {Object? arguments}) {
    final state = navigatorKey.currentState;
    if (state == null) {
      throw StateError(
        'Navigator not initialized. Ensure navigatorKey is attached to a Navigator widget.',
      );
    }
    return state.pushNamed<T>(route, arguments: arguments);
  }

  @override
  void navigateBack<T>([T? result]) {
    final state = navigatorKey.currentState;
    if (state == null) {
      throw StateError(
        'Navigator not initialized. Ensure navigatorKey is attached to a Navigator widget.',
      );
    }
    if (state.canPop()) {
      state.pop<T>(result);
    }
  }

  @override
  Future<T?> navigateReplace<T>(String route, {Object? arguments}) {
    final state = navigatorKey.currentState;
    if (state == null) {
      throw StateError(
        'Navigator not initialized. Ensure navigatorKey is attached to a Navigator widget.',
      );
    }
    return state.pushReplacementNamed<T, void>(
      route,
      arguments: arguments,
    );
  }

  @override
  Future<T?> navigateClearStack<T>(String route, {Object? arguments}) {
    final state = navigatorKey.currentState;
    if (state == null) {
      throw StateError(
        'Navigator not initialized. Ensure navigatorKey is attached to a Navigator widget.',
      );
    }
    return state.pushNamedAndRemoveUntil<T>(
      route,
      (route) => false,
      arguments: arguments,
    );
  }

  @override
  bool canGoBack() {
    final state = navigatorKey.currentState;
    if (state == null) {
      return false;
    }
    return state.canPop();
  }
}

