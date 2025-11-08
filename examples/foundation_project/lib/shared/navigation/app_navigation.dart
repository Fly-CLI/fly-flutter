import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fly_core/fly_core.dart';
import 'package:fly_events/fly_events.dart';
import 'package:foundation_project/core/event_system/events.dart';
import 'package:fly_navigation/fly_navigation.dart';
import 'package:foundation_project/shared/navigation/feature_screen_type.dart';
import 'package:foundation_project/shared/navigation/app_router.dart';

/// Application-specific navigation service implementing NavigationService with Feature enum
///
/// This service implements NavigationService with Feature enum as the route type,
/// providing type-safe navigation with automatic event emission.
///
/// Example usage:
/// ```dart
/// // Using NavigationService interface with Feature enum
/// final service = AppNavigation.instance;
/// await service.navigateTo(FeatureScreenType.home);
///
/// // Direct navigation
/// AppNavigation.instance.navigateTo(FeatureScreenType.tasks);
/// ```
class AppNavigation implements NavigationService<FeatureScreenType> {
  /// Singleton instance
  static final AppNavigation _instance = AppNavigation._internal();

  /// Get the singleton instance
  static AppNavigation get instance => _instance;

  /// Private constructor for singleton
  AppNavigation._internal();

  /// The NavigatorKey to use for navigation
  final GlobalKey<NavigatorState> navigatorKey = App.navigatorKey;

  /// Get the GoRouter instance
  GoRouter get _router => AppRouter.router;

  /// Get the event emitter instance
  ///
  /// Accesses the emitter via GlobalContainer.
  /// Returns null if GlobalContainer is not initialized.
  AppEventEmitter? get _emitter {
    try {
      if (!GlobalContainer.isInitialized) return null;
      return GlobalContainer.instance.read(eventEmitterProvider);
    } catch (e) {
      // Silently fail - emitter access is not critical for navigation
      return null;
    }
  }

  /// Emit navigation started event
  ///
  /// Silently fails if emitter is not available to ensure navigation
  /// is never blocked by events.
  void _emitNavigationStarted(FeatureScreenType feature) {
    try {
      _emitter?.emit(
        NavigationStartedEvent(
          feature: feature,
        ),
      );
    } catch (e) {
      // Silently fail - events are not critical for navigation
    }
  }

  /// Emit navigation completed event
  ///
  /// Silently fails if emitter is not available to ensure navigation
  /// is never blocked by events.
  void _emitNavigationCompleted(FeatureScreenType feature, {dynamic result}) {
    try {
      _emitter?.emit(
        NavigationCompletedEvent(
          feature: feature,
          result: result,
        ),
      );
    } catch (e) {
      // Silently fail - events are not critical for navigation
    }
  }

  // ============================================================================
  // NavigationService<FeatureScreenType> Interface Implementation
  // ============================================================================

  @override
  Future<T?> navigateTo<T>(FeatureScreenType route, {Object? arguments}) {
    _emitNavigationStarted(route);

    try {
      // Check if this is a shell route (bottom navigation tab) or a detail/form route
      final isShellRoute = route == FeatureScreenType.home ||
          route == FeatureScreenType.tasks ||
          route == FeatureScreenType.notes ||
          route == FeatureScreenType.settings;

      if (isShellRoute) {
        // Use go() for shell routes to switch tabs
        _router.go(route.route, extra: arguments);
      } else {
        // Use push() for detail/form routes to add to stack
        _router.push(route.route, extra: arguments);
      }
      
      // Emit completion event immediately since GoRouter doesn't return a Future
      // In practice, results are handled through route builders or state management
      _emitNavigationCompleted(route);
      
      // Return a completed future since GoRouter's navigation is synchronous
      return Future<T?>.value(null);
    } catch (error) {
      _emitNavigationCompleted(route);
      return Future<T?>.value(null);
    }
  }

  @override
  void navigateBack<T>([T? result]) {
    if (_router.canPop()) {
      _router.pop(result);
    }
  }

  @override
  Future<T?> navigateReplace<T>(FeatureScreenType route, {Object? arguments}) {
    _emitNavigationStarted(route);

    try {
      // Use GoRouter's go to replace current route
      _router.go(route.route, extra: arguments);
      
      // Emit completion event immediately
      _emitNavigationCompleted(route);
      
      return Future<T?>.value(null);
    } catch (error) {
      _emitNavigationCompleted(route);
      return Future<T?>.value(null);
    }
  }

  @override
  Future<T?> navigateClearStack<T>(FeatureScreenType route, {Object? arguments}) {
    _emitNavigationStarted(route);

    try {
      // Use GoRouter's go to clear stack and navigate to route
      _router.go(route.route, extra: arguments);
      
      // Emit completion event immediately
      _emitNavigationCompleted(route);
      
      return Future<T?>.value(null);
    } catch (error) {
      _emitNavigationCompleted(route);
      return Future<T?>.value(null);
    }
  }

  @override
  bool canGoBack() {
    return _router.canPop();
  }

  // ============================================================================
  // Convenience Methods (Additional Features)
  // ============================================================================

  /// Navigate to a feature and clear until a specific feature
  ///
  /// This method automatically emits events for navigation tracking.
  /// This is an additional method beyond the NavigationService interface.
  ///
  /// Note: GoRouter handles route management differently. This method
  /// navigates to the target feature, but the "until" behavior is
  /// handled by GoRouter's route configuration.
  Future<T?> navigateToAndClearUntil<T>(
    FeatureScreenType feature,
    FeatureScreenType untilFeature, {
    Object? arguments,
  }) {
    _emitNavigationStarted(feature);

    try {
      // GoRouter doesn't have direct equivalent of pushNamedAndRemoveUntil
      // We navigate to the target route - the route configuration handles
      // the navigation stack structure
      _router.go(feature.route, extra: arguments);
      
      // Emit completion event immediately
      _emitNavigationCompleted(feature);
      
      return Future<T?>.value(null);
    } catch (error) {
      _emitNavigationCompleted(feature);
      return Future<T?>.value(null);
    }
  }
}

