import 'package:flutter/material.dart';
{{#use_riverpod}}
import 'package:flutter_riverpod/flutter_riverpod.dart';
{{/use_riverpod}}
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fly_core/fly_core.dart';
import 'package:fly_navigation/fly_navigation.dart';

import 'shared/navigation/app_navigator.dart';
import 'shared/navigation/app_router.dart';
import 'shared/themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  GlobalContainer.initialize();

  runApp(
{{#use_riverpod}}
    UncontrolledProviderScope(
      container: GlobalContainer.instance,
      child: const _FlyFoundationApp(),
    ),
{{/use_riverpod}}
{{^use_riverpod}}
    const _FlyFoundationApp(),
{{/use_riverpod}}
  );
}

class _FlyFoundationApp extends {{#use_riverpod}}ConsumerWidget{{/use_riverpod}}{{^use_riverpod}}StatelessWidget{{/use_riverpod}} {
  const _FlyFoundationApp();

  @override
  Widget build(BuildContext context{{#use_riverpod}}, WidgetRef ref{{/use_riverpod}}) {
    final navigationManager = NavigationManager.from(
      initialRoute: AppRouteConfig.initialRoute,
      onGenerateRoute: AppRouteConfig.onGenerateRoute,
      onUnknownRoute: AppRouteConfig.onUnknownRoute,
      navigatorObserversFactory: () => <NavigatorObserver>[
        AppNavigationObserver(),
      ],
    );

    return MaterialApp(
      title: '{{project_name.pascalCase()}}',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      navigatorKey: navigationManager.navigatorKey,
      initialRoute: navigationManager.initialRoute,
      onGenerateRoute: navigationManager.onGenerateRoute,
      onUnknownRoute: navigationManager.onUnknownRoute,
      navigatorObservers: navigationManager.navigatorObservers,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return Semantics(
          label: AppLocalizations.of(context)?.appTitle,
          explicitChildNodes: true,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              boldText: true,
              accessibleNavigation: true,
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

