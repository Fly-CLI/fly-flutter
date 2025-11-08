import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fly_core/fly_core.dart';
import 'package:foundation_project/core/providers/providers.dart';
import 'package:foundation_project/core/storage/storage_providers.dart';
import 'package:foundation_project/l10n/app_localizations.dart';
import 'package:foundation_project/shared/navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  GlobalContainer.initialize();

  // Initialize storage services
  final regularStorage = GlobalContainer.instance.read(regularStorageProvider);
  final secureStorage = GlobalContainer.instance.read(secureStorageProvider);
  await regularStorage.init();
  await secureStorage.init();

  // Initialize app data manager
  final appDataManager = GlobalContainer.instance.read(appDataManagerProvider);
  await appDataManager.init();

  runApp(
    UncontrolledProviderScope(
      container: GlobalContainer.instance,
      child: const FoundationProjectApp(),
    ),
  );
}

class FoundationProjectApp extends StatelessWidget {
  const FoundationProjectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Task & Notes Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: AppRouter.router,
    );
  }
}
