import 'package:flutter/material.dart';
import 'package:foundation_project/features/home/domain/models/task.dart';
import 'package:foundation_project/features/home/presentation/screens/home_screen.dart';
import 'package:foundation_project/features/notes/presentation/screens/notes_screen.dart';
import 'package:foundation_project/features/settings/presentation/screens/settings_screen.dart';
import 'package:foundation_project/features/tasks/presentation/navigation/task_route_args.dart';
import 'package:foundation_project/features/tasks/presentation/screens/detail/task_detail_screen.dart';
import 'package:foundation_project/features/tasks/presentation/screens/form/task_form_screen.dart';
import 'package:foundation_project/features/tasks/presentation/screens/list/tasks_screen.dart';
import 'package:foundation_project/l10n/app_localizations.dart';
import 'package:foundation_project/shared/navigation/feature_screen_type.dart';
import 'package:foundation_project/shared/navigation/main_navigation_screen.dart';

/// Signature for route handlers used by the navigation registry.
typedef RouteHandler = Widget Function(
  BuildContext context,
  Map<String, dynamic>? arguments,
);

/// Central registry mapping [FeatureScreen] to route handlers.
class RouteHandlerRegistry {
  static RouteHandler? getHandler(FeatureScreen feature) {
    switch (feature) {
      case FeatureScreen.home:
        return (context, args) => const MainNavigationScreen(
          feature: FeatureScreen.notes,
          child: HomeScreen(),
        );
      case FeatureScreen.tasks:
        return (context, args) => const TasksScreen();
      case FeatureScreen.notes:
        return (context, args) => const NotesScreen();
      case FeatureScreen.settings:
        return (context, args) => const SettingsScreen();
      case FeatureScreen.taskDetail:
        return (context, args) {
          final l10n = AppLocalizations.of(context);
          final data = args ?? <String, dynamic>{};
          Task? initialTask;
          String? taskId = _readIdFromArgs(data);

          final rawArgs = data['args'];
          if (rawArgs is TaskDetailScreenArgs) {
            taskId = rawArgs.taskId;
            initialTask ??= rawArgs.initialTask;
          }

          final payload = data['payload'];
          if (payload is TaskDetailScreenArgs) {
            taskId = payload.taskId;
            initialTask ??= payload.initialTask;
          } else if (payload is Task) {
            taskId ??= payload.id;
            initialTask ??= payload;
          } else if (payload is String) {
            taskId ??= payload;
          }

          final taskValue = data['task'];
            if (taskValue is Task) {
              taskId ??= taskValue.id;
            initialTask ??= taskValue;
          }

          final initialTaskValue = data['initialTask'];
          if (initialTaskValue is Task) {
            initialTask ??= initialTaskValue;
          }

          if (taskId == null || taskId.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: Text(l10n.taskDetail)),
              body: Center(child: Text(l10n.taskNotFound)),
            );
          }

          return TaskDetailScreen(
            taskId: taskId,
            initialTask: initialTask,
          );
        };
      case FeatureScreen.noteDetail:
        return (context, args) {
          final l10n = AppLocalizations.of(context);
          final data = args ?? <String, dynamic>{};
          final id = (data['id'] ?? data['noteId'] ?? '') as String? ?? '';
          return Scaffold(
            appBar: AppBar(title: Text(l10n.noteDetailTitle(id))),
            body: Center(child: Text(l10n.noteDetailComingSoon)),
          );
        };
      case FeatureScreen.taskForm:
        return (context, args) {
          final data = args ?? <String, dynamic>{};
          Task? initialTask;

          final rawArgs = data['args'];
          if (rawArgs is TaskFormScreenArgs) {
            initialTask = rawArgs.initialTask;
          }

          final taskValue = data['task'];
            if (taskValue is Task) {
            initialTask ??= taskValue;
            }

          final initialTaskValue = data['initialTask'];
          if (initialTaskValue is Task) {
            initialTask ??= initialTaskValue;
          }

          return TaskFormScreen(initialTask: initialTask);
        };
      case FeatureScreen.noteForm:
        return (context, args) {
          final l10n = AppLocalizations.of(context);
          return Scaffold(
            appBar: AppBar(title: Text(l10n.addEditNote)),
            body: Center(child: Text(l10n.noteFormComingSoon)),
          );
        };
    }
  }

  static bool hasHandler(FeatureScreen feature) {
    return getHandler(feature) != null;
  }

  static Set<FeatureScreen> get registeredFeatures =>
      FeatureScreen.values.toSet();

  static String? _readIdFromArgs(Map<String, dynamic> args) {
    final idValue = args['taskId'] ?? args['id'];
    if (idValue is String && idValue.isNotEmpty) {
      return idValue;
    }
    final taskValue = args['task'];
    if (taskValue is Task && taskValue.id.isNotEmpty) {
      return taskValue.id;
    }
    return null;
  }
}

/// Route configuration used by `MaterialApp`.
class AppRouteConfig {
  static const String initialRoute = '/';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final requestedRoute = settings.name ?? initialRoute;
    final feature = _getFeatureFromRoute(requestedRoute);

    if (feature == null) {
      return _unknownRoute(settings);
    }

    final handler = RouteHandlerRegistry.getHandler(feature);
    if (handler == null) {
      return _unknownRoute(settings);
    }

    final normalizedArgs = _normalizeArguments(settings.arguments);
    final params = _extractParams(requestedRoute, feature.route);
    final mergedArgs = {
      if (normalizedArgs != null) ...normalizedArgs,
      if (params.isNotEmpty) ...params,
    };

    return MaterialPageRoute(
      builder: (context) => handler(
        context,
        mergedArgs.isEmpty ? null : mergedArgs,
      ),
      settings: RouteSettings(
        name: requestedRoute,
        arguments: mergedArgs.isEmpty ? settings.arguments : mergedArgs,
      ),
    );
  }

  static Route<dynamic>? onUnknownRoute(RouteSettings settings) {
    return _unknownRoute(settings);
  }

  static Route<dynamic> _unknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: const Center(
          child: Text('The requested page was not found.'),
        ),
      ),
      settings: settings,
    );
  }

  static FeatureScreen? _getFeatureFromRoute(String route) {
    for (final feature in FeatureScreen.values) {
      if (!feature.route.contains(':') && route == feature.route) {
        return feature;
      }
    }

    for (final feature in FeatureScreen.values) {
      if (feature.route.contains(':') &&
          _routeMatchesPattern(route, feature.route)) {
        return feature;
      }
    }

    return null;
  }

  static bool _routeMatchesPattern(String route, String pattern) {
    final routeSegments = route.split('/');
    final patternSegments = pattern.split('/');

    if (routeSegments.length != patternSegments.length) {
      return false;
    }

    for (var i = 0; i < patternSegments.length; i++) {
      final patternSegment = patternSegments[i];
      if (!patternSegment.startsWith(':') &&
          patternSegment != routeSegments[i]) {
        return false;
      }
    }
    return true;
  }

  static Map<String, dynamic>? _normalizeArguments(Object? arguments) {
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

    return <String, dynamic>{'payload': arguments};
  }

  static Map<String, String> _extractParams(String route, String pattern) {
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
}
