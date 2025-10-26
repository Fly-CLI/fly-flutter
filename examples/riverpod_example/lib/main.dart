import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:riverpod_example/core/router/app_router.dart';
import 'package:riverpod_example/core/theme/app_theme.dart';

void main() {
  runApp(
    ProviderScope(
      // Disable automatic retry mechanism for better control
      retry: (retryCount, error) => null,
      child: const RiverpodExampleApp(),
    ),
  );
}

class RiverpodExampleApp extends ConsumerWidget {
  const RiverpodExampleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'Riverpod Example',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
