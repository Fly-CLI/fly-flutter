import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fly_core/fly_core.dart';

import '../providers/home_provider.dart';

class HomeScreen extends BaseScreen<HomeViewModel> {
  const HomeScreen({super.key});

  @override
  ProviderListenable<HomeViewModel> get viewModelProvider => homeViewModelNotifierProvider;

  @override
  Widget buildContent(BuildContext context, HomeViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{{project_name}}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final counter = ref.watch(counterProvider);
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome to {{project_name}}!',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 16),
                Text(
                  'This is a Riverpod Flutter project created with Fly CLI.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Text(
                  'Counter: $counter',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => ref.read(counterNotifierProvider.notifier).increment(),
                      child: const Text('Increment'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => ref.read(counterNotifierProvider.notifier).decrement(),
                      child: const Text('Decrement'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => ref.read(counterNotifierProvider.notifier).reset(),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
