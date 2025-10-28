import 'dart:io';
import 'package:path/path.dart' as path;

/// Test fixtures and helpers for analysis system testing
class AnalysisTestFixtures {
  /// Create a minimal Flutter project structure for testing
  static Future<Directory> createMinimalFlutterProject(Directory tempDir) async {
    final projectDir = Directory(path.join(tempDir.path, 'minimal_project'));
    await projectDir.create(recursive: true);

    // Create pubspec.yaml
    final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
    await pubspecFile.writeAsString(minimalPubspecContent);

    // Create lib directory with main.dart
    final libDir = Directory(path.join(projectDir.path, 'lib'));
    await libDir.create(recursive: true);

    final mainFile = File(path.join(libDir.path, 'main.dart'));
    await mainFile.writeAsString(minimalMainContent);

    return projectDir;
  }

  /// Create a complex Flutter project with multiple features
  static Future<Directory> createComplexFlutterProject(Directory tempDir) async {
    final projectDir = Directory(path.join(tempDir.path, 'complex_project'));
    await projectDir.create(recursive: true);

    // Create pubspec.yaml with dependencies
    final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
    await pubspecFile.writeAsString(complexPubspecContent);

    // Create lib directory structure
    final libDir = Directory(path.join(projectDir.path, 'lib'));
    await libDir.create(recursive: true);

    // Create features directory
    final featuresDir = Directory(path.join(libDir.path, 'features'));
    await featuresDir.create(recursive: true);

    // Create home feature
    final homeDir = Directory(path.join(featuresDir.path, 'home'));
    await homeDir.create(recursive: true);

    await File(path.join(homeDir.path, 'home_screen.dart')).writeAsString(homeScreenContent);
    await File(path.join(homeDir.path, 'home_viewmodel.dart')).writeAsString(homeViewModelContent);

    // Create profile feature
    final profileDir = Directory(path.join(featuresDir.path, 'profile'));
    await profileDir.create(recursive: true);

    await File(path.join(profileDir.path, 'profile_screen.dart')).writeAsString(profileScreenContent);
    await File(path.join(profileDir.path, 'profile_service.dart')).writeAsString(profileServiceContent);

    // Create core directory
    final coreDir = Directory(path.join(libDir.path, 'core'));
    await coreDir.create(recursive: true);

    // Create router directory
    final routerDir = Directory(path.join(coreDir.path, 'router'));
    await routerDir.create(recursive: true);
    await File(path.join(routerDir.path, 'app_router.dart')).writeAsString(routerContent);

    // Create theme directory
    final themeDir = Directory(path.join(coreDir.path, 'theme'));
    await themeDir.create(recursive: true);
    await File(path.join(themeDir.path, 'app_theme.dart')).writeAsString(themeContent);

    // Create main.dart
    final mainFile = File(path.join(libDir.path, 'main.dart'));
    await mainFile.writeAsString(complexMainContent);

    // Create test directory
    final testDir = Directory(path.join(projectDir.path, 'test'));
    await testDir.create(recursive: true);

    await File(path.join(testDir.path, 'widget_test.dart')).writeAsString(widgetTestContent);

    // Create README.md for documented convention
    await File(path.join(projectDir.path, 'README.md')).writeAsString('# Complex Test Project\n\nA complex Flutter project for testing.');

    return projectDir;
  }

  /// Create a Fly project with manifest
  static Future<Directory> createFlyProject(Directory tempDir) async {
    final projectDir = Directory(path.join(tempDir.path, 'fly_project'));
    await projectDir.create(recursive: true);

    // Create pubspec.yaml with Fly packages
    final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
    await pubspecFile.writeAsString(flyPubspecContent);

    // Create fly_project.yaml manifest
    final manifestFile = File(path.join(projectDir.path, 'fly_project.yaml'));
    await manifestFile.writeAsString(flyManifestContent);

    // Create lib directory
    final libDir = Directory(path.join(projectDir.path, 'lib'));
    await libDir.create(recursive: true);

    await File(path.join(libDir.path, 'main.dart')).writeAsString(flyMainContent);

    return projectDir;
  }

  /// Create a project with problematic dependencies
  static Future<Directory> createProblematicProject(Directory tempDir) async {
    final projectDir = Directory(path.join(tempDir.path, 'problematic_project'));
    await projectDir.create(recursive: true);

    final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
    await pubspecFile.writeAsString(problematicPubspecContent);

    final libDir = Directory(path.join(projectDir.path, 'lib'));
    await libDir.create(recursive: true);

    await File(path.join(libDir.path, 'main.dart')).writeAsString(problematicMainContent);

    return projectDir;
  }

  /// Create a large project for performance testing
  static Future<Directory> createLargeProject(Directory tempDir) async {
    final projectDir = Directory(path.join(tempDir.path, 'large_project'));
    await projectDir.create(recursive: true);

    final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
    await pubspecFile.writeAsString(largeProjectPubspecContent);

    final libDir = Directory(path.join(projectDir.path, 'lib'));
    await libDir.create(recursive: true);

    // Create fewer files to simulate large project but keep test fast
    for (int i = 0; i < 10; i++) {
      final featureDir = Directory(path.join(libDir.path, 'feature_$i'));
      await featureDir.create(recursive: true);

      await File(path.join(featureDir.path, 'screen_$i.dart')).writeAsString(generateLargeFileContent(i));
      await File(path.join(featureDir.path, 'service_$i.dart')).writeAsString(generateLargeFileContent(i + 1000));
    }

    await File(path.join(libDir.path, 'main.dart')).writeAsString(largeProjectMainContent);

    return projectDir;
  }

  /// Generate content for large files
  static String generateLargeFileContent(int seed) {
    final buffer = StringBuffer();
    buffer.writeln('// Generated file $seed');
    buffer.writeln('import \'package:flutter/material.dart\';');
    buffer.writeln('');

    for (int i = 0; i < 20; i++) {
      buffer.writeln('class GeneratedClass${seed}_$i {');
      buffer.writeln('  final String name;');
      buffer.writeln('  final int value;');
      buffer.writeln('');
      buffer.writeln('  GeneratedClass${seed}_$i({required this.name, required this.value});');
      buffer.writeln('');
      buffer.writeln('  void method$i() {');
      buffer.writeln('    // Complex logic here');
      for (int j = 0; j < 5; j++) {
        buffer.writeln('    if (value > $j) {');
        buffer.writeln('      print(\'Value is greater than $j\');');
        buffer.writeln('    }');
      }
      buffer.writeln('  }');
      buffer.writeln('}');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  // Test content constants
  static const String minimalPubspecContent = '''
name: minimal_test
description: A minimal test project
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
''';

  static const String complexPubspecContent = '''
name: complex_test
description: A complex test project
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.0
  go_router: ^12.0.0
  dio: ^5.3.0
  freezed_annotation: ^2.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  freezed: ^2.4.0
  json_annotation: ^4.8.0
''';

  static const String flyPubspecContent = '''
name: fly_test
description: A Fly test project
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  fly_core: ^0.1.0
  fly_state: ^0.1.0
  fly_networking: ^0.1.0
  flutter_riverpod: ^2.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
''';

  static const String problematicPubspecContent = '''
name: problematic_test
description: A problematic test project
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.0
  flutter_bloc: ^8.1.0
  provider: ^6.0.0
  dio: ^5.3.0
  http: ^1.1.0
  flutter_webview_plugin: ^0.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
''';

  static const String largeProjectPubspecContent = '''
name: large_test
description: A large test project
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.0
  go_router: ^12.0.0
  dio: ^5.3.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.8.0
  cached_network_image: ^3.3.0
  shared_preferences: ^2.2.0
  path_provider: ^2.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  freezed: ^2.4.0
''';

  static const String flyManifestContent = '''
name: fly_test
template: riverpod
organization: test_org
description: A Fly test project
platforms:
  - ios
  - android
screens:
  - name: home
    type: screen
    features:
      - navigation
  - name: profile
    type: screen
    features:
      - user_data
services:
  - name: api
    type: rest
    api_base: https://api.example.com
packages:
  - dio
  - flutter_riverpod
''';

  static const String minimalMainContent = '''
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minimal Test',
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minimal Test')),
      body: const Center(child: Text('Hello World')),
    );
  }
}
''';

  static const String complexMainContent = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Complex Test',
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
''';

  static const String flyMainContent = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fly_core/fly_core.dart';

void main() {
  runApp(const ProviderScope(child: FlyApp()));
}

class FlyApp extends StatelessWidget {
  const FlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fly Test',
      home: const BaseScreen(),
    );
  }
}
''';

  static const String problematicMainContent = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CounterNotifier()),
        BlocProvider(create: (_) => CounterBloc()),
      ],
      child: MaterialApp(
        title: 'Problematic Test',
        home: const MyHomePage(),
      ),
    );
  }
}

class CounterNotifier extends ChangeNotifier {
  int _count = 0;
  int get count => _count;
  
  void increment() {
    _count++;
    notifyListeners();
  }
}

class CounterBloc extends Bloc<int, int> {
  CounterBloc() : super(0);
}
''';

  static const String largeProjectMainContent = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(const ProviderScope(child: LargeApp()));
}

class LargeApp extends ConsumerWidget {
  const LargeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Large Test',
      home: const LargeHomePage(),
    );
  }
}

class LargeHomePage extends StatelessWidget {
  const LargeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Large Test')),
      body: const Center(child: Text('Large Project')),
    );
  }
}
''';

  static const String homeScreenContent = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_viewmodel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(homeViewModelProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Text('Count: \${viewModel.count}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(homeViewModelProvider.notifier).increment(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
''';

  static const String homeViewModelContent = '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeViewModel extends StateNotifier<int> {
  HomeViewModel() : super(0);

  void increment() => state++;
}

final homeViewModelProvider = StateNotifierProvider<HomeViewModel, int>(
  (ref) => HomeViewModel(),
);
''';

  static const String profileScreenContent = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        data: (profile) => Center(child: Text('Name: \${profile.name}')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: \$error')),
      ),
    );
  }
}
''';

  static const String profileServiceContent = '''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

class Profile {
  final String name;
  final String email;
  
  Profile({required this.name, required this.email});
}

class ProfileService {
  final Dio _dio;
  
  ProfileService(this._dio);
  
  Future<Profile> getProfile() async {
    final response = await _dio.get('/profile');
    return Profile(
      name: response.data['name'],
      email: response.data['email'],
    );
  }
}

final profileProvider = FutureProvider<Profile>((ref) async {
  final service = ProfileService(Dio());
  return service.getProfile();
});
''';

  static const String routerContent = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_screen.dart';
import '../../features/profile/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
''';

  static const String themeContent = '''
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.dark,
      useMaterial3: true,
    );
  }
}
''';

  static const String widgetTestContent = '''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:complex_test/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Complex Test'), findsOneWidget);
  });
}
''';
}
