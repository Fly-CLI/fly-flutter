import 'package:flutter/material.dart';
import 'package:foundation_project/core/di/global_container.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_emitter.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_providers.dart';
import 'package:foundation_project/core/navigation/app.dart';
import 'package:foundation_project/core/foundation/mvvm/services/navigation_service.dart';

/// Enum for application features with their corresponding routes
///
/// To add a new feature:
/// 1. Add the feature with its route and protection status
/// 2. Set isProtected: true for features that require authentication
/// 3. Set isProtected: false for public features
enum FeatureScreenType {
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

  const FeatureScreenType(this.route, {required this.isProtected});

  final String route;
  final bool isProtected;

  /// Helper method to check if this feature requires authentication
  bool get requiresAuth => isProtected;

  /// Helper method to check if this feature is public
  bool get isPublic => !isProtected;

  /// Helper method to get all protected features
  static List<FeatureScreenType> get protectedFeatures =>
      FeatureScreenType.values.where((feature) => feature.isProtected).toList();

  /// Helper method to get all public features
  static List<FeatureScreenType> get publicFeatures =>
      FeatureScreenType.values.where((feature) => !feature.isProtected).toList();
}

/// Enhanced navigation service implementing NavigationService with Feature enum
///
/// This service implements NavigationService with Feature enum as the route type,
/// providing type-safe navigation with automatic lifecycle event emission.
///
/// Example usage:
/// ```dart
/// // Using NavigationService interface with Feature enum
/// final service = AppNavigation.instance;
/// await service.navigateTo(Feature.home);
///
/// // Direct navigation
/// AppNavigation.instance.navigateTo(Feature.tasks);
/// ```
class FlyRouter implements NavigationService<FeatureScreenType> {
  /// Singleton instance
  static final FlyRouter _instance = FlyRouter._internal();

  /// Get the singleton instance
  static FlyRouter get instance => _instance;

  /// Private constructor for singleton
  FlyRouter._internal();

  /// The NavigatorKey to use for navigation
  final GlobalKey<NavigatorState> navigatorKey = App.navigatorKey;

  /// Get the lifecycle emitter instance
  ///
  /// Accesses the emitter via GlobalContainer.
  /// Returns null if GlobalContainer is not initialized.
  AppLifecycleEmitter? get _emitter {
    try {
      if (!GlobalContainer.isInitialized) return null;
      return GlobalContainer.instance.read(lifecycleEmitterProvider);
    } catch (e) {
      // Silently fail - emitter access is not critical for navigation
      return null;
    }
  }

  /// Emit navigation started event
  ///
  /// Silently fails if emitter is not available to ensure navigation
  /// is never blocked by lifecycle events.
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
  /// is never blocked by lifecycle events.
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
  // NavigationService<Feature> Interface Implementation
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
  /// This method automatically emits lifecycle events for navigation tracking.
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
