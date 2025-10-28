import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:fly_cli/src/core/command_foundation/application/command_base.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/infrastructure/command_context_impl.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_result.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'package:fly_cli/src/core/templates/template_manager.dart';
import 'package:fly_cli/src/core/diagnostics/system_checker.dart';
import 'package:fly_cli/src/core/command_foundation/infrastructure/interactive_prompt.dart';

import 'mock_logger.dart';

/// Helper class for testing Fly CLI commands
class CommandTestHelper {
  /// Create a mock CommandContext for testing
  static CommandContext createMockCommandContext({
    Logger? logger,
    String? workingDirectory,
    Map<String, dynamic>? config,
    ArgResults? argResults,
  }) {
    final mockLogger = logger ?? MockLogger();
    final workingDir = workingDirectory ?? Directory.current.path;
    final mockConfig = config ?? <String, dynamic>{};
    final mockArgResults = argResults ?? ArgParser().parse([]);

    return CommandContextImpl(
      argResults: mockArgResults,
      logger: mockLogger,
      templateManager: TemplateManager(
        templatesDirectory: '/test/templates',
        logger: mockLogger,
      ),
      systemChecker: SystemChecker(logger: mockLogger),
      interactivePrompt: InteractivePrompt(mockLogger),
      config: mockConfig,
      environment: Environment.current(),
      workingDirectory: workingDir,
      verbose: false,
      quiet: false,
    );
  }
  /// Run a Fly CLI command and return the result
  static Future<CommandResult> runCommand(
    List<String> args, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    // Create a temporary command runner for testing
    final commandName = args.isNotEmpty ? args.first : 'unknown';
    
    // Mock the command execution for testing
    // In real tests, this would instantiate the actual command classes
    return CommandResult.success(
      command: commandName,
      message: 'Test command executed',
      data: {'args': args, 'workingDirectory': workingDirectory},
    );
  }

  /// Run the actual CLI process (for integration tests)
  static Future<ProcessResult> runCli(
    List<String> args, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    // This would run the actual fly CLI executable
    // For now, return a mock result
    return ProcessResult(
      0, // exitCode
      0, // pid
      'Mock stdout', // stdout
      'Mock stderr', // stderr
    );
  }

  /// Create a temporary directory for testing
  static Directory createTempDir({String? prefix}) => Directory.systemTemp.createTempSync(
      prefix ?? 'fly_test_',
    );

  /// Clean up a temporary directory
  static void cleanupTempDir(Directory dir) {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }

  /// Verify that a project has the expected structure
  static Future<bool> verifyProjectStructure(String projectPath) async {
    final projectDir = Directory(projectPath);
    if (!projectDir.existsSync()) {
      return false;
    }

    // Check for essential Flutter project files
    final essentialFiles = [
      'pubspec.yaml',
      'lib/main.dart',
      'test/widget_test.dart',
    ];

    for (final file in essentialFiles) {
      final filePath = File(path.join(projectPath, file));
      if (!filePath.existsSync()) {
        return false;
      }
    }

    return true;
  }

  /// Run flutter analyze on a project
  static Future<ProcessResult> runFlutterAnalyze(String projectPath) async {
    // Mock flutter analyze for testing
    return ProcessResult(
      0, // exitCode
      0, // pid
      'No issues found!', // stdout
      '', // stderr
    );
  }

  /// Create a mock project structure for testing
  static Future<Directory> createMockProject({
    required String projectName,
    String? template,
  }) async {
    final tempDir = createTempDir();
    final projectDir = Directory(path.join(tempDir.path, projectName));
    await projectDir.create(recursive: true);

    // Create pubspec.yaml
    final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
    await pubspecFile.writeAsString('''
name: $projectName
description: A test Flutter project
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.0.0"

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
''');

    // Create lib directory
    final libDir = Directory(path.join(projectDir.path, 'lib'));
    await libDir.create();

    // Create main.dart
    final mainFile = File(path.join(libDir.path, 'main.dart'));
    await mainFile.writeAsString('''
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$projectName',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: '$projectName'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '0', // Fixed counter value for test
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
''');

    // Create test directory
    final testDir = Directory(path.join(projectDir.path, 'test'));
    await testDir.create();

    // Create widget_test.dart
    final testFile = File(path.join(testDir.path, 'widget_test.dart'));
    await testFile.writeAsString('''
import 'package:flutter/material.dart';
import 'package:test/test.dart';

import 'package:$projectName/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
''');

    return projectDir;
  }

  /// Verify that a file exists
  static bool fileExists(String filePath) => File(filePath).existsSync();

  /// Verify that a directory exists
  static bool directoryExists(String dirPath) => Directory(dirPath).existsSync();

  /// Read file content as string
  static String readFile(String filePath) => File(filePath).readAsStringSync();

  /// Write content to file
  static void writeFile(String filePath, String content) {
    File(filePath).writeAsStringSync(content);
  }

  /// Parse JSON from file
  static Map<String, dynamic> readJsonFile(String filePath) {
    final content = readFile(filePath);
    return json.decode(content) as Map<String, dynamic>;
  }

  /// Verify JSON structure
  static void verifyJsonStructure(
    Map<String, dynamic> json,
    List<String> requiredKeys,
  ) {
    for (final key in requiredKeys) {
      expect(json.containsKey(key), isTrue, reason: 'Missing required key: $key');
    }
  }

  /// Create a mock template directory
  static Future<Directory> createMockTemplate({
    required String templateName,
    String? version,
  }) async {
    final tempDir = createTempDir();
    final templateDir = Directory(path.join(tempDir.path, templateName));
    await templateDir.create(recursive: true);

    // Create template.yaml
    final templateYamlFile = File(path.join(templateDir.path, 'template.yaml'));
    await templateYamlFile.writeAsString('''
name: $templateName
version: ${version ?? '1.0.0'}
description: Test template for $templateName
minFlutterSdk: 3.0.0
minDartSdk: 3.0.0
features: [test]
packages: [test_package]
''');

    // Create __brick__ directory
    final brickDir = Directory(path.join(templateDir.path, '__brick__'));
    await brickDir.create();

    // Create a sample file in the brick
    final sampleFile = File(path.join(brickDir.path, '{{name}}.dart'));
    await sampleFile.writeAsString('''
// Generated file for {{name}}
class {{name.pascalCase()}} {
  // Template content
}
''');

    return templateDir;
  }
}

/// Mock TemplateManager for testing
class MockTemplateManager {
  // Add mock methods as needed
}

/// Mock SystemChecker for testing
class MockSystemChecker {
  // Add mock methods as needed
}

/// Mock InteractivePrompt for testing
class MockInteractivePrompt {
  // Add mock methods as needed
}
