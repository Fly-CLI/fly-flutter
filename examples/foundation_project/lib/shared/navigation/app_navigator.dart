import 'package:flutter/material.dart';
import 'package:fly_core/fly_core.dart';
import 'package:fly_events/fly_events.dart';
import 'package:fly_navigation/fly_navigation.dart';
import 'package:foundation_project/core/event_system/events.dart';
import 'package:foundation_project/features/home/domain/models/task.dart';
import 'package:foundation_project/features/tasks/presentation/navigation/task_route_args.dart';
import 'package:foundation_project/shared/navigation/feature_screen_type.dart';

/// Navigation service providing type-safe navigation using [FeatureScreen].
///
/// This implementation mirrors the StockAI navigation design by exposing
/// navigator-key based helpers while retaining the Fly event emission hooks.
class AppNavigator implements NavigationService<FeatureScreen> {
  AppNavigator._internal();

  static final AppNavigator _instance = AppNavigator._internal();

  /// Singleton accessor used across the app and tests.
  static AppNavigator get instance => _instance;

  /// Global navigator key shared with `MaterialApp`.
  final GlobalKey<NavigatorState> navigatorKey = App.navigatorKey;

  AppEventEmitter? get _emitter {
    try {
      if (!GlobalContainer.isInitialized) return null;
      return GlobalContainer.instance.read(eventEmitterProvider);
    } catch (_) {
      return null;
    }
  }

  void _emitNavigationStarted(FeatureScreen feature) {
    try {
      _emitter?.emit(NavigationStartedEvent(feature: feature));
    } catch (_) {}
  }

  void _emitNavigationCompleted(
    FeatureScreen feature, {
    Object? result,
  }) {
    try {
      _emitter?.emit(
        NavigationCompletedEvent(
          feature: feature,
          result: result,
        ),
      );
    } catch (_) {}
  }

  @override
  Future<T?> navigateTo<T>(
    FeatureScreen feature, {
    Object? arguments,
  }) async {
    _emitNavigationStarted(feature);

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _emitNavigationCompleted(feature);
      return null;
    }

    try {
      final normalizedArgs = _prepareArguments(feature, arguments);
      final result = await navigator.pushNamed<T>(
        feature.route,
        arguments: normalizedArgs,
      );
      _emitNavigationCompleted(feature, result: result);
      return result;
    } catch (_) {
      _emitNavigationCompleted(feature);
      return null;
    }
  }

  @override
  Future<T?> navigateReplace<T>(
    FeatureScreen feature, {
    Object? arguments,
  }) async {
    _emitNavigationStarted(feature);

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _emitNavigationCompleted(feature);
      return null;
    }

    try {
      final normalizedArgs = _prepareArguments(feature, arguments);
      final result = await navigator.pushReplacementNamed<T, void>(
        feature.route,
        arguments: normalizedArgs,
      );
      _emitNavigationCompleted(feature, result: result);
      return result;
    } catch (_) {
      _emitNavigationCompleted(feature);
      return null;
    }
  }

  @override
  Future<T?> navigateClearStack<T>(
    FeatureScreen feature, {
    Object? arguments,
  }) async {
    _emitNavigationStarted(feature);

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _emitNavigationCompleted(feature);
      return null;
    }

    try {
      final normalizedArgs = _prepareArguments(feature, arguments);
      final result = await navigator.pushNamedAndRemoveUntil<T>(
        feature.route,
        (route) => false,
        arguments: normalizedArgs,
      );
      _emitNavigationCompleted(feature, result: result);
      return result;
    } catch (_) {
      _emitNavigationCompleted(feature);
      return null;
    }
  }

  Future<T?> navigateToAndClearUntil<T>(
    FeatureScreen feature,
    FeatureScreen untilFeature, {
    Object? arguments,
  }) async {
    _emitNavigationStarted(feature);

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _emitNavigationCompleted(feature);
      return null;
    }

    try {
      final normalizedArgs = _prepareArguments(feature, arguments);
      final result = await navigator.pushNamedAndRemoveUntil<T>(
        feature.route,
        (route) => route.settings.name == untilFeature.route,
        arguments: normalizedArgs,
      );
      _emitNavigationCompleted(feature, result: result);
      return result;
    } catch (_) {
      _emitNavigationCompleted(feature);
      return null;
    }
  }

  @override
  void navigateBack<T>([T? result]) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    if (navigator.canPop()) {
      navigator.pop<T>(result);
    }
  }

  @override
  bool canGoBack() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return false;
    }

    return navigator.canPop();
  }

  /// Convenience helper mirroring StockAI's feature helpers.
  Future<T?> navigateToFeature<T>(
    FeatureScreen feature, {
    Map<String, dynamic>? params,
  }) {
    return navigateTo<T>(feature, arguments: params);
  }

  /// Navigate directly to the home screen.
  Future<T?> navigateToHome<T>() {
    return navigateToFeature<T>(FeatureScreen.home);
  }

  /// Navigate to tasks list.
  Future<T?> navigateToTasks<T>() {
    return navigateToFeature<T>(FeatureScreen.tasks);
  }

  /// Navigate to notes list.
  Future<T?> navigateToNotes<T>() {
    return navigateToFeature<T>(FeatureScreen.notes);
  }

  /// Navigate to task form with optional initial task.
  Future<T?> navigateToTaskForm<T>({Task? initialTask}) {
    return navigateTo<T>(
      FeatureScreen.taskForm,
      arguments: TaskFormScreenArgs(initialTask: initialTask),
    );
  }

  /// Navigate to task detail with optional initial task payload.
  Future<T?> navigateToTaskDetail<T>({
    required String taskId,
    Task? initialTask,
  }) {
    return navigateTo<T>(
      FeatureScreen.taskDetail,
      arguments: TaskDetailScreenArgs(
        taskId: taskId,
        initialTask: initialTask,
      ),
    );
  }

  /// Navigate to note form (placeholder for future implementation).
  Future<T?> navigateToNoteForm<T>() {
    return navigateToFeature<T>(FeatureScreen.noteForm);
  }

  /// Retrieve the current route name if available.
  String? getCurrentRoute() {
    String? currentRoute;
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return null;
    }

    navigator.popUntil((route) {
      currentRoute = route.settings.name;
      return true;
    });
    return currentRoute;
  }

  /// Generate a route path with dynamic parameters replaced.
  String generateRoute(String baseRoute, Map<String, String> params) {
    var route = baseRoute;
    params.forEach((key, value) {
      route = route.replaceAll(':$key', value);
    });
    return route;
  }

  /// Extract dynamic parameters from a route path.
  Map<String, String> extractParams(String route, String pattern) {
    final params = <String, String>{};
    final routeSegments = route.split('/');
    final patternSegments = pattern.split('/');

    for (var i = 0;
        i < patternSegments.length && i < routeSegments.length;
        i++) {
      final patternSegment = patternSegments[i];
      if (patternSegment.startsWith(':')) {
        final paramName = patternSegment.substring(1);
        params[paramName] = routeSegments[i];
      }
    }

    return params;
  }

  Map<String, dynamic>? _prepareArguments(
    FeatureScreen feature,
    Object? arguments,
  ) {
    if (arguments == null) {
      return null;
    }

    if (arguments is Map<String, dynamic>) {
      return Map<String, dynamic>.from(arguments);
    }

    if (arguments is Map) {
      return arguments.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    if (arguments is TaskDetailScreenArgs) {
      return <String, dynamic>{
        'taskId': arguments.taskId,
        'initialTask': arguments.initialTask,
        'args': arguments,
      }..removeWhere((key, value) => value == null);
    }

    if (arguments is TaskFormScreenArgs) {
      return <String, dynamic>{
        'initialTask': arguments.initialTask,
        'args': arguments,
      }..removeWhere((key, value) => value == null);
    }

    if (arguments is Task) {
      return <String, dynamic>{
        'task': arguments,
        'id': arguments.id,
      }..removeWhere((key, value) => value == null);
    }

    if (arguments is String) {
      return <String, dynamic>{'id': arguments};
    }

    final identifier = _extractIdentifier(arguments);
    final normalized = <String, dynamic>{'payload': arguments};
    if (identifier != null && identifier.isNotEmpty) {
      normalized['id'] = identifier;
    }
    return normalized;
  }

  String? _extractIdentifier(Object? arguments) {
    if (arguments == null) {
      return null;
    }

    if (arguments is String) {
      return arguments;
    }

    if (arguments is Map) {
      final idValue = arguments['id'];
      if (idValue is String && idValue.isNotEmpty) {
        return idValue;
      }
      final taskValue = arguments['task'];
      final taskId = _tryReadId(taskValue);
      if (taskId != null) {
        return taskId;
      }
    }

    return _tryReadId(arguments);
  }

  String? _tryReadId(Object? value) {
    try {
      final dynamic dynamicValue = value;
      if (dynamicValue == null) return null;
      final taskId = dynamicValue.taskId;
      if (taskId is String && taskId.isNotEmpty) {
        return taskId;
      }
    } catch (_) {}

    try {
      final dynamic dynamicValue = value;
      if (dynamicValue == null) return null;
      final id = dynamicValue.id;
      if (id is String && id.isNotEmpty) {
        return id;
      }
    } catch (_) {}

    return null;
  }
}

/// Navigation observer mirroring the StockAI debug observer.
class AppNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logNavigation('PUSH', route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _logNavigation('POP', route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _logNavigation('REPLACE', newRoute, oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _logNavigation('REMOVE', route, previousRoute);
  }

  void _logNavigation(
    String action,
    Route<dynamic>? route,
    Route<dynamic>? previousRoute,
  ) {
    debugPrint(
      'Navigation: $action - ${route?.settings.name} '
      '(from: ${previousRoute?.settings.name})',
    );
  }
}
