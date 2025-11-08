import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fly_core/fly_core.dart';
import 'package:fly_events/fly_events.dart';
import 'package:foundation_project/core/event_system/events.dart';
import 'package:fly_navigation/fly_navigation.dart';
import 'package:foundation_project/shared/navigation/app_router.dart';
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

  @override
  Future<T?> navigateTo<T>(FeatureScreenType route, {Object? arguments}) {
    _emitNavigationStarted(route);

    try {
      final resolvedPath = _resolveRoutePath(route, arguments);
      final isShellRoute = route == FeatureScreenType.home ||
          route == FeatureScreenType.tasks ||
          route == FeatureScreenType.notes ||
          route == FeatureScreenType.settings;

      if (isShellRoute) {
        _router.go(resolvedPath, extra: arguments);
      } else {
        _router.push(resolvedPath, extra: arguments);
      }

      _emitNavigationCompleted(route);
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
      final resolvedPath = _resolveRoutePath(route, arguments);
      _router.go(resolvedPath, extra: arguments);
      _emitNavigationCompleted(route);
      return Future<T?>.value(null);
    } catch (error) {
      _emitNavigationCompleted(route);
      return Future<T?>.value(null);
    }
  }

  @override
  Future<T?> navigateClearStack<T>(FeatureScreenType route,
      {Object? arguments}) {
    _emitNavigationStarted(route);

    try {
      final resolvedPath = _resolveRoutePath(route, arguments);
      _router.go(resolvedPath, extra: arguments);
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

  Future<T?> navigateToAndClearUntil<T>(
    FeatureScreenType feature,
    FeatureScreenType untilFeature, {
    Object? arguments,
  }) {
    _emitNavigationStarted(feature);

    try {
      final resolvedPath = _resolveRoutePath(feature, arguments);
      _router.go(resolvedPath, extra: arguments);
      _emitNavigationCompleted(feature);
      return Future<T?>.value(null);
    } catch (error) {
      _emitNavigationCompleted(feature);
      return Future<T?>.value(null);
    }
  }

  String _resolveRoutePath(FeatureScreenType route, Object? arguments) {
    var path = route.route;
    if (path.contains(':')) {
      final id = _extractIdentifier(arguments);
      if (id != null && id.isNotEmpty) {
        path = path.replaceAll(':id', id);
      }
    }
    return path;
  }

  String? _extractIdentifier(Object? arguments) {
    if (arguments == null) return null;
    if (arguments is String) return arguments;

    if (arguments is Map) {
      final idValue = arguments['id'];
      if (idValue is String) {
        return idValue;
      }
      final taskValue = arguments['task'];
      final taskId = _tryReadId(taskValue);
      if (taskId != null) {
        return taskId;
      }
    }

    final directId = _tryReadId(arguments);
    if (directId != null) {
      return directId;
    }

    return null;
  }

  String? _tryReadId(Object? value) {
    try {
      final dynamic dynamicValue = value;
      if (dynamicValue == null) return null;
      final taskId = dynamicValue.taskId;
      if (taskId is String && taskId.isNotEmpty) {
        return taskId;
      }
    } catch (_) {
      // ignore
    }

    try {
      final dynamic dynamicValue = value;
      if (dynamicValue == null) return null;
      final id = dynamicValue.id;
      if (id is String && id.isNotEmpty) {
        return id;
      }
    } catch (_) {
      // ignore
    }

    return null;
  }
}
