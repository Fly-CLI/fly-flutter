import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:foundation_project/core/navigation/app.dart';
import 'package:foundation_project/core/navigation/app_navigation.dart';
import 'package:foundation_project/features/home/presentation/screens/home_screen.dart';
import 'package:foundation_project/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:foundation_project/features/notes/presentation/screens/notes_screen.dart';
import 'package:foundation_project/features/settings/presentation/screens/settings_screen.dart';
import 'package:foundation_project/l10n/app_localizations.dart';
import 'package:foundation_project/shared/navigation/main_navigation_screen.dart';

/// App router configuration
class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = App.navigatorKey;

  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: Feature.home.route,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationScreen(child: child);
        },
        routes: [
          GoRoute(
            path: Feature.home.route,
            name: Feature.home.name,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: Feature.tasks.route,
            name: Feature.tasks.name,
            builder: (context, state) => const TasksScreen(),
          ),
          GoRoute(
            path: Feature.notes.route,
            name: Feature.notes.name,
            builder: (context, state) => const NotesScreen(),
          ),
          GoRoute(
            path: Feature.settings.route,
            name: Feature.settings.name,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      // Detail routes (outside shell for full screen)
      GoRoute(
        path: Feature.taskDetail.route,
        name: Feature.taskDetail.name,
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          final id = state.pathParameters['id'] ?? '';
          // TODO: Navigate to task detail screen
          return Scaffold(
            appBar: AppBar(title: Text(l10n.taskDetailTitle(id))),
            body: Center(child: Text(l10n.taskDetailComingSoon)),
          );
        },
      ),
      GoRoute(
        path: Feature.noteDetail.route,
        name: Feature.noteDetail.name,
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
        path: Feature.taskForm.route,
        name: Feature.taskForm.name,
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          // TODO: Navigate to task form screen
          return Scaffold(
            appBar: AppBar(title: Text(l10n.addEditTask)),
            body: Center(child: Text(l10n.taskFormComingSoon)),
          );
        },
      ),
      GoRoute(
        path: Feature.noteForm.route,
        name: Feature.noteForm.name,
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

