import 'package:flutter/material.dart';
import 'package:fly_navigation/src/navigation_service.dart';
import 'package:fly_navigation/src/standard_navigator.dart';
import 'package:fly_navigation/src/implementations/go_router_navigation_service.dart';
import 'package:fly_navigation/src/implementations/auto_route_navigation_service.dart';
import 'package:fly_navigation/src/implementations/navigator2_navigation_service.dart';

/// Enumeration of supported navigation types.
enum NavigationType {
  /// Standard Flutter Navigator (default)
  standard,

  /// GoRouter navigation
  goRouter,

  /// AutoRoute navigation (not yet implemented)
  autoRoute,

  /// Navigator 2.0 navigation (not yet implemented)
  navigator2,
}

/// Factory for creating navigation service instances.
///
/// This factory provides a centralized way to create navigation service
/// instances based on the selected navigation type.
///
/// ## Usage
///
/// ```dart
/// // Create a standard navigation service
/// final service = NavigationServiceFactory.create(
///   NavigationType.standard,
///   navigatorKey: AppNavigation.globalKey,
/// );
///
/// // Create a GoRouter navigation service
/// final router = GoRouter(routes: [...]);
/// final service = NavigationServiceFactory.create(
///   NavigationType.goRouter,
///   router: router,
/// );
/// ```
class NavigationServiceFactory {
  /// Creates a navigation service instance for the given type.
  ///
  /// For [NavigationType.standard], requires [navigatorKey].
  /// For [NavigationType.goRouter], requires [router].
  /// For [NavigationType.autoRoute], requires [router] (AutoRoute router).
  /// For [NavigationType.navigator2], requires [delegate].
  ///
  /// Returns a [NavigationService] instance.
  ///
  /// Throws [ArgumentError] if required parameters are missing or if the type
  /// is not yet implemented.
  static NavigationService<String> create(
    NavigationType type, {
    GlobalKey<NavigatorState>? navigatorKey,
    dynamic router,
    dynamic delegate,
  }) {
    switch (type) {
      case NavigationType.standard:
        if (navigatorKey == null) {
          throw ArgumentError(
            'navigatorKey is required for NavigationType.standard',
          );
        }
        return StandardNavigator(navigatorKey: navigatorKey);
      case NavigationType.goRouter:
        throw ArgumentError(
          'router is required for NavigationType.goRouter',
        );
      case NavigationType.autoRoute:
        if (router == null) {
          throw ArgumentError(
            'router is required for NavigationType.autoRoute',
          );
        }
        return AutoRouteNavigationService(router: router);
      case NavigationType.navigator2:
        if (delegate == null) {
          throw ArgumentError(
            'delegate is required for NavigationType.navigator2',
          );
        }
        return Navigator2NavigationService(delegate: delegate);
    }
  }

  /// Creates a navigation service from a string identifier.
  ///
  /// [identifier] - String identifier (e.g., 'standard', 'goRouter', 'autoRoute', 'navigator2')
  /// [navigatorKey] - Required for 'standard' type
  /// [router] - Required for 'goRouter' and 'autoRoute' types
  /// [delegate] - Required for 'navigator2' type
  ///
  /// Returns a [NavigationService] instance.
  ///
  /// Throws [ArgumentError] if the identifier is not recognized or required
  /// parameters are missing.
  static NavigationService<String> createFromString(
    String identifier, {
    GlobalKey<NavigatorState>? navigatorKey,
    dynamic router,
    dynamic delegate,
  }) {
    final type = NavigationType.values.firstWhere(
      (type) => type.name == identifier.toLowerCase(),
      orElse: () => throw ArgumentError(
        'Unknown navigation type: $identifier. '
        'Supported types: ${NavigationType.values.map((e) => e.name).join(", ")}',
      ),
    );
    return create(
      type,
      navigatorKey: navigatorKey,
      router: router,
      delegate: delegate,
    );
  }
}

