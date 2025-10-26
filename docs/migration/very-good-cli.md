# Migration from Very Good CLI

This guide will help you migrate from Very Good CLI to Fly CLI, taking advantage of AI-native features and improved developer experience.

## Why Migrate?

### Very Good CLI Limitations

- **Single architecture**: Only supports Very Good's specific patterns
- **No AI integration**: Human-readable output only
- **Limited customization**: Fixed project structure
- **No state management**: Basic MVVM only

### Fly CLI Advantages

- **AI-native**: Machine-readable JSON output for AI assistants
- **Multi-architecture**: Choose between minimal and Riverpod templates
- **Flexible**: Customizable project structure and patterns
- **Modern**: Built for the AI era with Cursor, Copilot integration

## Migration Process

### 1. Install Fly CLI

```bash
# Install Fly CLI
dart pub global activate fly_cli

# Verify installation
fly --version
```

### 2. Analyze Your Current Project

```bash
# Navigate to your Very Good CLI project
cd your_very_good_project

# Analyze the structure
find lib -name "*.dart" | head -20
```

### 3. Create New Project with Fly CLI

```bash
# Create a new Riverpod project (recommended for production)
fly create my_new_app --template=riverpod

# Or create a minimal project for simple apps
fly create my_new_app --template=minimal
```

### 4. Migrate Your Code

#### Very Good CLI Structure
```
lib/
├── app/
│   ├── app.dart
│   └── bootstrap.dart
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   └── utils/
├── features/
│   └── counter/
│       ├── counter.dart
│       ├── data/
│       ├── domain/
│       └── presentation/
└── l10n/
```

#### Fly CLI Riverpod Structure
```
lib/
├── main.dart
├── core/
│   ├── router/
│   └── theme/
├── features/
│   ├── home/
│   │   ├── presentation/
│   │   └── providers/
│   └── profile/
│       ├── presentation/
│       └── providers/
└── shared/
```

## Code Migration Examples

### 1. App Bootstrap

#### Very Good CLI (app/app.dart)
```dart
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Very Good App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CounterPage(),
    );
  }
}
```

#### Fly CLI (lib/main.dart)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/router/app_router.dart';
import 'package:my_app/core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp.router(
      title: 'My App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
```

### 2. State Management

#### Very Good CLI (CounterCubit)
```dart
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
}
```

#### Fly CLI (CounterProvider)
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'counter_provider.g.dart';

@riverpod
class CounterNotifier extends _$CounterNotifier {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() => state--;
}
```

### 3. UI Components

#### Very Good CLI (CounterPage)
```dart
class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: BlocBuilder<CounterCubit, int>(
        builder: (context, state) {
          return Center(
            child: Text('$state'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<CounterCubit>().increment(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

#### Fly CLI (CounterScreen)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/features/counter/providers/counter_provider.dart';

class CounterScreen extends ConsumerWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: Center(
        child: Text('$count'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(counterNotifierProvider.notifier).increment(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### 4. Network Layer

#### Very Good CLI (ApiClient)
```dart
class ApiClient {
  ApiClient({required this.dio}) : _dio = dio;
  
  final Dio _dio;

  Future<Response<T>> get<T>(String path) async {
    return _dio.get<T>(path);
  }
}
```

#### Fly CLI (ApiClient)
```dart
import 'package:fly_networking/fly_networking.dart';

class ApiClient {
  ApiClient({required this.httpClient});
  
  final ApiClient httpClient;

  Future<ApiResponse<T>> get<T>(String path) async {
    return httpClient.get<T>(path);
  }
}
```

## Migration Checklist

### Phase 1: Project Setup
- [ ] Install Fly CLI
- [ ] Create new project with appropriate template
- [ ] Set up basic project structure
- [ ] Configure dependencies

### Phase 2: Core Migration
- [ ] Migrate main app setup
- [ ] Set up routing (GoRouter)
- [ ] Configure theming
- [ ] Set up state management (Riverpod)

### Phase 3: Feature Migration
- [ ] Migrate each feature module
- [ ] Convert Cubits to Riverpod providers
- [ ] Update UI components
- [ ] Migrate network layer

### Phase 4: Testing & Polish
- [ ] Update tests
- [ ] Test all functionality
- [ ] Update documentation
- [ ] Deploy and verify

## Automated Migration Script

Create a migration script to help with the process:

```bash
#!/bin/bash

# Migration script from Very Good CLI to Fly CLI

echo "🚀 Starting migration from Very Good CLI to Fly CLI..."

# 1. Create new project
echo "📦 Creating new Fly CLI project..."
fly create my_migrated_app --template=riverpod

# 2. Navigate to new project
cd my_migrated_app

# 3. Generate project context for AI assistance
echo "🤖 Generating AI context..."
fly context export --include-dependencies=true

# 4. Add screens based on old project structure
echo "📱 Adding screens..."
fly add screen home --feature=home --with-viewmodel=true --with-tests=true
fly add screen profile --feature=profile --with-viewmodel=true --with-tests=true

# 5. Add services
echo "🔧 Adding services..."
fly add service user_api --feature=core --type=api --with-tests=true --with-mocks=true

echo "✅ Migration setup complete!"
echo "📝 Next steps:"
echo "   1. Copy your business logic to the new structure"
echo "   2. Update tests"
echo "   3. Test all functionality"
echo "   4. Deploy and verify"
```

## Common Migration Patterns

### 1. Cubit to Riverpod

```dart
// Before (Very Good CLI)
class UserCubit extends Cubit<UserState> {
  UserCubit(this._userRepository) : super(const UserState.initial());
  
  final UserRepository _userRepository;
  
  Future<void> loadUser() async {
    emit(const UserState.loading());
    try {
      final user = await _userRepository.getUser();
      emit(UserState.loaded(user));
    } catch (e) {
      emit(UserState.error(e.toString()));
    }
  }
}

// After (Fly CLI)
@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  AsyncValue<User> build() {
    loadUser();
    return const AsyncValue.loading();
  }
  
  Future<void> loadUser() async {
    state = const AsyncValue.loading();
    try {
      final user = await ref.read(userRepositoryProvider).getUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
```

### 2. Repository Pattern

```dart
// Before (Very Good CLI)
class UserRepository {
  UserRepository({required this.apiClient});
  
  final ApiClient apiClient;
  
  Future<User> getUser() async {
    final response = await apiClient.get('/user');
    return User.fromJson(response.data);
  }
}

// After (Fly CLI)
@riverpod
class UserRepository extends _$UserRepository {
  @override
  UserRepository build() => UserRepository();
  
  Future<User> getUser() async {
    final response = await ref.read(apiClientProvider).get<User>('/user');
    return response.when(
      success: (data) => User.fromJson(data),
      error: (error) => throw error,
    );
  }
}
```

## Troubleshooting

### Common Issues

**Dependency conflicts:**
```bash
# Clean and reinstall
flutter clean
flutter pub get
```

**State management errors:**
```bash
# Regenerate Riverpod code
flutter pub run build_runner build --delete-conflicting-outputs
```

**Routing issues:**
```bash
# Check GoRouter configuration
fly context export --include-structure=true
```

### Getting Help

- **GitHub Issues**: [Report migration issues](https://github.com/fly-cli/fly/issues)
- **Discord**: [Join community](https://discord.gg/fly-cli)
- **Documentation**: [Browse docs](/)

## Next Steps

After migration:

1. **[Explore AI Integration](/ai-integration/overview)** - Set up AI coding assistants
2. **[Learn Commands](/guide/commands)** - Master all Fly CLI commands
3. **[Check Examples](/examples/riverpod-example)** - See real-world examples
4. **[Join Community](https://discord.gg/fly-cli)** - Get help and share experiences
