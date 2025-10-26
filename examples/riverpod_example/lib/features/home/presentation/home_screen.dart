import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:riverpod_example/features/home/providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(counterProvider);
    final todos = ref.watch(todosProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riverpod Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to Riverpod Example!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This is a production-ready Flutter project created with Fly CLI.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            
            // Counter Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Counter Demo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Count: $counter',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            ref.read(counterProvider.notifier).increment();
                          },
                          child: const Text('Increment'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(counterProvider.notifier).decrement();
                          },
                          child: const Text('Decrement'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(counterProvider.notifier).reset();
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Todos Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Todos Demo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    todos.when(
                      data: (todoList) => Column(
                        children: [
                          if (todoList.isEmpty)
                            const Text('No todos yet. Add one below!')
                          else
                            ...todoList.map(
                              (todo) => ListTile(
                                title: Text(todo.title),
                                subtitle: Text(todo.description),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => ref
                                      .read(todosProvider.notifier)
                                      .removeTodo(todo.id),
                                ),
                              ),
                            ),
                        ],
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stack) => Text('Error: $error'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(todosProvider.notifier)
                          .addTodo(
                            'Sample Todo ${DateTime.now().millisecondsSinceEpoch}',
                            'This is a sample todo created at ${DateTime.now()}',
                          ),
                      child: const Text('Add Sample Todo'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
