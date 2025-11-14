import 'package:flutter/material.dart';
import 'package:fly_navigation/src/navigation_service.dart';

/// Navigator 2.0 implementation of [NavigationService].
///
/// This implementation uses Flutter's Navigator 2.0 API with a custom
/// router delegate. It provides a bridge between the abstract [NavigationService]
/// interface and Navigator 2.0's declarative navigation.
///
/// ## Usage
///
/// ```dart
/// final delegate = CustomRouterDelegate();
///
/// final service = Navigator2NavigationService(delegate: delegate);
/// await service.navigateTo('/home');
/// ```
///
/// Note: This is a placeholder implementation and will be fully implemented in Phase 3.
class Navigator2NavigationService implements NavigationService<String> {
  /// Creates a Navigator2NavigationService
  ///
  /// [delegate] - The custom router delegate to use for navigation
  Navigator2NavigationService({required this.delegate});

  /// The custom router delegate to use for navigation
  final dynamic delegate; // Using dynamic to avoid direct dependency

  @override
  Future<T?> navigateTo<T>(String route, {Object? arguments}) {
    throw UnimplementedError(
      'Navigator 2.0 navigation is not yet implemented. '
      'Use StandardNavigator or GoRouterNavigationService for now.',
    );
  }

  @override
  void navigateBack<T>([T? result]) {
    throw UnimplementedError(
      'Navigator 2.0 navigation is not yet implemented. '
      'Use StandardNavigator or GoRouterNavigationService for now.',
    );
  }

  @override
  Future<T?> navigateReplace<T>(String route, {Object? arguments}) {
    throw UnimplementedError(
      'Navigator 2.0 navigation is not yet implemented. '
      'Use StandardNavigator or GoRouterNavigationService for now.',
    );
  }

  @override
  Future<T?> navigateClearStack<T>(String route, {Object? arguments}) {
    throw UnimplementedError(
      'Navigator 2.0 navigation is not yet implemented. '
      'Use StandardNavigator or GoRouterNavigationService for now.',
    );
  }

  @override
  bool canGoBack() {
    throw UnimplementedError(
      'Navigator 2.0 navigation is not yet implemented. '
      'Use StandardNavigator or GoRouterNavigationService for now.',
    );
  }
}

