import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:foundation_project/foundation/navigation/app.dart';
import 'package:foundation_project/foundation/navigation/fly_router.dart';
import 'package:foundation_project/shared/navigation/feature_screen_type.dart';
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
          final l10n = AppLocalizations.of(context);
          // TODO: Navigate to task form screen
          return Scaffold(
            appBar: AppBar(title: Text(l10n.addEditTask)),
            body: Center(child: Text(l10n.taskFormComingSoon)),
          );
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

