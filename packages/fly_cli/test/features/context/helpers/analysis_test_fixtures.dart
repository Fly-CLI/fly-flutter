import 'dart:io';
import 'package:path/path.dart' as path;

/// Test fixtures for analysis tests
class AnalysisTestFixtures {
  /// Create a minimal Flutter project for testing
  static Future<Directory> createMinimalFlutterProject(Directory tempDir) async {
    final projectDir = Directory(path.join(tempDir.path, 'minimal_project'));
    await projectDir.create(recursive: true);

    // Create pubspec.yaml
    final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
    await pubspecFile.writeAsString(minimalPubspecContent);

    // Create lib directory
    final libDir = Directory(path.join(projectDir.path, 'lib'));
    await libDir.create();

    // Create main.dart
    final mainFile = File(path.join(libDir.path, 'main.dart'));
    await mainFile.writeAsString(minimalMainContent);

    return projectDir;
  }

  /// Create a complex Flutter project for testing
  static Future<Directory> createComplexFlutterProject(Directory tempDir) async {
    final projectDir = Directory(path.join(tempDir.path, 'complex_project'));
    await projectDir.create(recursive: true);

    // Create pubspec.yaml
    final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
    await pubspecFile.writeAsString(complexPubspecContent);

    // Create lib directory structure
    final libDir = Directory(path.join(projectDir.path, 'lib'));
    await libDir.create();

    // Create core directories
    final coreDir = Directory(path.join(libDir.path, 'core'));
    await coreDir.create();
    
    final routerDir = Directory(path.join(coreDir.path, 'router'));
    await routerDir.create();
    
    final themeDir = Directory(path.join(coreDir.path, 'theme'));
    await themeDir.create();

    // Create features directory
    final featuresDir = Directory(path.join(libDir.path, 'features'));
    await featuresDir.create();

    // Create main.dart
    final mainFile = File(path.join(libDir.path, 'main.dart'));
    await mainFile.writeAsString(complexMainContent);

    // Create router file
    final routerFile = File(path.join(routerDir.path, 'app_router.dart'));
    await routerFile.writeAsString(routerContent);

    // Create theme file
    final themeFile = File(path.join(themeDir.path, 'app_theme.dart'));
    await themeFile.writeAsString(themeContent);

    // Create feature files
    final homeDir = Directory(path.join(featuresDir.path, 'home'));
    await homeDir.create();
    
    final homeFile = File(path.join(homeDir.path, 'home_screen.dart'));
    await homeFile.writeAsString(homeScreenContent);

    // Create README.md for documented convention
    await File(path.join(projectDir.path, 'README.md')).writeAsString('# Complex Test Project\n\nA complex Flutter project for testing.');

    return projectDir;
  }

  /// Create a Fly project for testing
  static Future<Directory> createFlyProject(Directory tempDir) async {
    final projectDir = Directory(path.join(tempDir.path, 'fly_project'));
    await projectDir.create(recursive: true);

    // Create pubspec.yaml
    final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
    await pubspecFile.writeAsString(flyPubspecContent);

    // Create fly_project.yaml
    final flyManifestFile = File(path.join(projectDir.path, 'fly_project.yaml'));
    await flyManifestFile.writeAsString(flyManifestContent);

    // Create lib directory
    final libDir = Directory(path.join(projectDir.path, 'lib'));
    await libDir.create();

    // Create main.dart
    final mainFile = File(path.join(libDir.path, 'main.dart'));
    await mainFile.writeAsString(flyMainContent);

    return projectDir;
  }

  /// Create a problematic project for error testing
  static Future<Directory> createProblematicProject(Directory tempDir) async {
    final projectDir = Directory(path.join(tempDir.path, 'problematic_project'));
    await projectDir.create(recursive: true);

    // Create pubspec.yaml with conflicts
    final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
    await pubspecFile.writeAsString(malformedPubspecContent);

    // Create lib directory with files containing conflicting patterns
    final libDir = Directory(path.join(projectDir.path, 'lib'));
    await libDir.create();

    // Create file with riverpod pattern
    final riverpodFile = File(path.join(libDir.path, 'riverpod_file.dart'));
    await riverpodFile.writeAsString('''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RiverpodWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container();
  }
}
''');

    // Create file with bloc pattern
    final blocFile = File(path.join(libDir.path, 'bloc_file.dart'));
    await blocFile.writeAsString('''
import 'package:flutter_bloc/flutter_bloc.dart';

class BlocWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CounterBloc, CounterState>(
      builder: (context, state) => Container(),
    );
  }
}
''');

    // Create file with provider pattern
    final providerFile = File(path.join(libDir.path, 'provider_file.dart'));
    await providerFile.writeAsString('''
import 'package:provider/provider.dart';

class ProviderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyModel(),
      child: Container(),
    );
  }
}
''');

    return projectDir;
  }

  /// Create a large project for performance testing
  static Future<Directory> createLargeProject(Directory tempDir) async {
    final projectDir = Directory(path.join(tempDir.path, 'large_project'));
    await projectDir.create(recursive: true);

    // Create pubspec.yaml
    final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
    await pubspecFile.writeAsString(complexPubspecContent);

    // Create lib directory
    final libDir = Directory(path.join(projectDir.path, 'lib'));
    await libDir.create();

    // Create many files for performance testing
    for (int i = 0; i < 50; i++) {
      final file = File(path.join(libDir.path, 'file_$i.dart'));
      await file.writeAsString('// File $i\nclass File${i}Class {\n  void method$i() {\n    print("File $i");\n  }\n}');
    }

    return projectDir;
  }

  // Test content constants
  static const String minimalPubspecContent = '''
name: minimal_test
description: A minimal test project
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.0.0'

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
version: 2.0.0+2

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.0
  go_router: ^12.0.0
  dio: ^5.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
''';

  static const String flyPubspecContent = '''
name: fly_test
description: A Fly test project
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.0.0'

dependencies:
  flutter:
    sdk: flutter
  fly_core: ^0.1.0
  fly_state: ^0.1.0
  fly_networking: ^0.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
''';

  static const String malformedPubspecContent = '''
name: malformed_test
description: A problematic test project with conflicts
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.0
  flutter_bloc: ^8.1.0
  provider: ^6.0.0
  dio: ^5.3.0
  http: ^1.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
''';

  static const String flyManifestContent = '''
name: fly_test
template: riverpod
organization: test_org
description: A Fly test project
platforms:
  - ios
  - android
  - web
screens:
  - name: home
    type: list
    features:
      - search
services:
  - name: auth
    type: firebase
    features:
      - authentication
packages:
  - dio
  - flutter_riverpod
''';

  static const String minimalMainContent = '''
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minimal Test',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(child: Text('Hello World')),
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
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Complex Test',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
''';

  static const String flyMainContent = '''
import 'package:flutter/material.dart';
import 'package:fly_core/fly_core.dart';

void main() {
  runApp(FlyApp());
}
''';

  static const String routerContent = '''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/home_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => HomeScreen(),
      ),
    ],
  );
}
''';

  static const String themeContent = '''
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
''';

  static const String homeScreenContent = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(child: Text('Welcome to Home')),
    );
  }
}
''';
}
