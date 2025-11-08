import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fly_navigation/fly_navigation.dart';
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

/// App router configuration
class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = App.navigatorKey;

  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: FeatureScreenType.home.route,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationScreen(child: child);
        },
        routes: [
          GoRoute(
            path: FeatureScreenType.home.route,
            name: FeatureScreenType.home.name,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: FeatureScreenType.tasks.route,
            name: FeatureScreenType.tasks.name,
            builder: (context, state) => const TasksScreen(),
          ),
          GoRoute(
            path: FeatureScreenType.notes.route,
            name: FeatureScreenType.notes.name,
            builder: (context, state) => const NotesScreen(),
          ),
          GoRoute(
            path: FeatureScreenType.settings.route,
            name: FeatureScreenType.settings.name,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      // Detail routes (outside shell for full screen)
      GoRoute(
        path: FeatureScreenType.taskDetail.route,
        name: FeatureScreenType.taskDetail.name,
        builder: (context, state) {
          final extra = state.extra;
          Task? initialTask;
          String? taskId = state.pathParameters['id'];

          if (extra is TaskDetailScreenArgs) {
            taskId = extra.taskId;
            initialTask = extra.initialTask;
          } else if (extra is Task) {
            initialTask = extra;
            taskId = extra.id;
          } else if (extra is Map) {
            final idValue = extra['id'];
            if (idValue is String) {
              taskId ??= idValue;
            }
            final taskValue = extra['task'];
            if (taskValue is Task) {
              initialTask = taskValue;
              taskId ??= taskValue.id;
            }
          } else if (extra is String) {
            taskId ??= extra;
          }

          if (taskId == null || taskId.isEmpty) {
            final l10n = AppLocalizations.of(context);
            return Scaffold(
              appBar: AppBar(title: Text(l10n.taskDetail)),
              body: Center(child: Text(l10n.taskNotFound)),
            );
          }

          return TaskDetailScreen(
            taskId: taskId,
            initialTask: initialTask,
          );
        },
      ),
      GoRoute(
        path: FeatureScreenType.noteDetail.route,
        name: FeatureScreenType.noteDetail.name,
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          final id = state.pathParameters['id'] ?? '';
          // TODO: Navigate to note detail screen
          return Scaffold(
            appBar: AppBar(title: Text(l10n.noteDetailTitle(id))),
            body: Center(child: Text(l10n.noteDetailComingSoon)),
          );
        },
      ),
      // Form routes (outside shell for full screen)
      GoRoute(
        path: FeatureScreenType.taskForm.route,
        name: FeatureScreenType.taskForm.name,
        builder: (context, state) {
          final extra = state.extra;
          Task? initialTask;
          if (extra is TaskFormScreenArgs) {
            initialTask = extra.initialTask;
          } else if (extra is Task) {
            initialTask = extra;
          } else if (extra is Map) {
            final taskValue = extra['task'];
            if (taskValue is Task) {
              initialTask = taskValue;
            }
          }
          return TaskFormScreen(initialTask: initialTask);
        },
      ),
      GoRoute(
        path: FeatureScreenType.noteForm.route,
        name: FeatureScreenType.noteForm.name,
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          // TODO: Navigate to note form screen
          return Scaffold(
            appBar: AppBar(title: Text(l10n.addEditNote)),
            body: Center(child: Text(l10n.noteFormComingSoon)),
          );
        },
      ),
    ],
  );
}
