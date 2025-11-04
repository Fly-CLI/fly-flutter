import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/analytics/analytics_providers.dart';
import 'package:foundation_project/core/navigation/app.dart';

/// Enum for application features with their corresponding routes
///
/// To add a new feature:
/// 1. Add the feature with its route and protection status
/// 2. Set isProtected: true for features that require authentication
/// 3. Set isProtected: false for public features
enum Feature {
  // Main features
  home('/', isProtected: false),
  tasks('/tasks', isProtected: true),
  notes('/notes', isProtected: true),
  settings('/settings', isProtected: true),

  // Detail features
  taskDetail('/tasks/:id', isProtected: true),
  noteDetail('/notes/:id', isProtected: true),

  // Form features
  taskForm('/tasks/form', isProtected: true),
  noteForm('/notes/form', isProtected: true);

  const Feature(this.route, {required this.isProtected});

  final String route;
  final bool isProtected;

  /// Helper method to check if this feature requires authentication
  bool get requiresAuth => isProtected;

  /// Helper method to check if this feature is public
  bool get isPublic => !isProtected;

  /// Helper method to get all protected features
  static List<Feature> get protectedFeatures =>
      Feature.values.where((feature) => feature.isProtected).toList();

  /// Helper method to get all public features
  static List<Feature> get publicFeatures =>
      Feature.values.where((feature) => !feature.isProtected).toList();
}

/// Navigation service for handling app navigation
class AppNavigation {
  static final AppNavigation _instance = AppNavigation._internal();

  factory AppNavigation() => _instance;

  AppNavigation._internal();

  /// Global provider container reference (set during app initialization)
  static ProviderContainer? _providerContainer;

  /// Initialize navigation with provider container
  ///
  /// This should be called during app initialization to enable automatic
  /// feature tracking for recently accessed items.
  static void initialize(ProviderContainer container) {
    _providerContainer = container;
  }

  /// Track feature access (internal helper)
  ///
  /// Automatically called by navigation methods to track recently accessed features.
  /// Failures are silently ignored to ensure navigation is never blocked.
  static void _trackFeatureAccess(Feature feature) {
    if (_providerContainer == null) return;

    try {
      final trackingService = _providerContainer!.read(
        recentlyAccessedTrackingServiceProvider,
      );
      trackingService.trackFeatureAccess(feature);
    } catch (e) {
      // Silently fail - tracking is not critical for navigation
    }
  }

  /// Navigate to a feature
  static Future<T?> navigateTo<T>(Feature feature, {Object? arguments}) {
    _trackFeatureAccess(feature);

    return App.navigatorKey.currentState!.pushNamed<T>(
      feature.route,
      arguments: arguments,
    );
  }

  /// Navigate to a feature and replace current route
  static Future<T?> navigateToReplacement<T>(
    Feature feature, {
    Object? arguments,
  }) {
    _trackFeatureAccess(feature);

    return App.navigatorKey.currentState!.pushReplacementNamed<T, void>(
      feature.route,
      arguments: arguments,
    );
  }

  /// Navigate to a feature and clear all previous routes
  static Future<T?> navigateToAndClear<T>(
    Feature feature, {
    Object? arguments,
  }) {
    _trackFeatureAccess(feature);

    return App.navigatorKey.currentState!.pushNamedAndRemoveUntil<T>(
      feature.route,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Navigate to a feature and clear until a specific feature
  static Future<T?> navigateToAndClearUntil<T>(
    Feature feature,
    Feature untilFeature, {
    Object? arguments,
  }) {
    _trackFeatureAccess(feature);

    return App.navigatorKey.currentState!.pushNamedAndRemoveUntil<T>(
      feature.route,
      (route) => route.settings.name == untilFeature.route,
      arguments: arguments,
    );
  }

  /// Go back
  static void goBack<T>([T? result]) {
    if (App.navigatorKey.currentState!.canPop()) {
      App.navigatorKey.currentState!.pop<T>(result);
    }
  }

  /// Check if can go back
  static bool canGoBack() {
    return App.navigatorKey.currentState!.canPop();
  }

  /// Navigate to feature with optional parameters
  static Future<T?> navigateToFeature<T>(
    Feature feature, {
    Map<String, dynamic>? params,
  }) {
    return navigateTo<T>(feature, arguments: params);
  }
}

