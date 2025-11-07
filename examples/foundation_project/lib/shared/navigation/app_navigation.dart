import 'package:flutter/material.dart';
import 'package:foundation_project/foundation/di/global_container.dart';
import 'package:foundation_project/foundation/events/event_emitter.dart';
import 'package:foundation_project/core/event_system/events.dart';
import 'package:foundation_project/foundation/events/event_providers.dart';
import 'package:foundation_project/foundation/navigation/app.dart';
import 'package:foundation_project/foundation/navigation/navigation_service.dart';
import 'package:foundation_project/shared/navigation/feature_screen_type.dart';

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

    final state = navigatorKey.currentState;
    if (state == null) {
      throw StateError(
        'Navigator not initialized. Ensure navigatorKey is attached to a Navigator widget.',
      );
    }

    final future = state.pushNamed<T>(
      route.route,
      arguments: arguments,
    );

    // Emit completion event when navigation completes
    future.then((result) {
      _emitNavigationCompleted(route, result: result);
    }).catchError((error) {
      // Still emit completion even on error
      _emitNavigationCompleted(route);
    });

    return future;
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
  Future<T?> navigateReplace<T>(FeatureScreenType route, {Object? arguments}) {
    _emitNavigationStarted(route);

    final state = navigatorKey.currentState;
    if (state == null) {
      throw StateError(
        'Navigator not initialized. Ensure navigatorKey is attached to a Navigator widget.',
      );
    }

    final future = state.pushReplacementNamed<T, void>(
      route.route,
      arguments: arguments,
    );

    // Emit completion event when navigation completes
    future.then((result) {
      _emitNavigationCompleted(route, result: result);
    }).catchError((error) {
      // Still emit completion even on error
      _emitNavigationCompleted(route);
    });

    return future;
  }

  @override
  Future<T?> navigateClearStack<T>(FeatureScreenType route, {Object? arguments}) {
    _emitNavigationStarted(route);

    final state = navigatorKey.currentState;
    if (state == null) {
      throw StateError(
        'Navigator not initialized. Ensure navigatorKey is attached to a Navigator widget.',
      );
    }

    final future = state.pushNamedAndRemoveUntil<T>(
      route.route,
      (route) => false,
      arguments: arguments,
    );

    // Emit completion event when navigation completes
    future.then((result) {
      _emitNavigationCompleted(route, result: result);
    }).catchError((error) {
      // Still emit completion even on error
      _emitNavigationCompleted(route);
    });

    return future;
  }

  @override
  bool canGoBack() {
    final state = navigatorKey.currentState;
    if (state == null) {
      return false;
    }
    return state.canPop();
  }

  // ============================================================================
  // Convenience Methods (Additional Features)
  // ============================================================================

  /// Navigate to a feature and clear until a specific feature
  ///
  /// This method automatically emits events for navigation tracking.
  /// This is an additional method beyond the NavigationService interface.
  Future<T?> navigateToAndClearUntil<T>(
    FeatureScreenType feature,
    FeatureScreenType untilFeature, {
    Object? arguments,
  }) {
    _emitNavigationStarted(feature);

    final state = navigatorKey.currentState;
    if (state == null) {
      throw StateError(
        'Navigator not initialized. Ensure navigatorKey is attached to a Navigator widget.',
      );
    }

    final future = state.pushNamedAndRemoveUntil<T>(
      feature.route,
      (route) => route.settings.name == untilFeature.route,
      arguments: arguments,
    );

    // Emit completion event when navigation completes
    future.then((result) {
      _emitNavigationCompleted(feature, result: result);
    }).catchError((error) {
      // Still emit completion even on error
      _emitNavigationCompleted(feature);
    });

    return future;
  }
}

