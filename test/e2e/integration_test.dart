import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import '../helpers/cli_test_helper.dart';

void main() {
  group('E2E Integration Tests', () {
    late Directory tempDir;
    late CliTestHelper cli;

    setUp(() {
      final testRunId = DateTime.now().millisecondsSinceEpoch;
      tempDir = Directory('${Directory.current.path}/test_generated/e2e_$testRunId');
      tempDir.createSync(recursive: true);
      cli = CliTestHelper(tempDir);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('Project Creation E2E', () {
      test('create minimal project with all features', () async {
        const projectName = 'test_minimal_project';
        final projectPath = path.join(tempDir.path, projectName);

        // Test project creation
        final result = await cli.createProject(
          projectName,
          organization: 'com.test',
          platforms: ['ios', 'android'],
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, isNotEmpty);

        // Parse JSON output
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['success'] as bool, isTrue);
        final data = output['data'] as Map<String, dynamic>;
        final projectNameOutput = data['project_name'] as String;
        final templateOutput = data['template'] as String;
        expect(projectNameOutput, equals(projectName));
        expect(templateOutput, equals('minimal'));

        // Verify project structure
        expect(Directory(projectPath).existsSync(), isTrue);
        expect(File(path.join(projectPath, 'pubspec.yaml')).existsSync(), isTrue);
        expect(File(path.join(projectPath, 'lib', 'main.dart')).existsSync(), isTrue);
        expect(File(path.join(projectPath, 'test', 'widget_test.dart')).existsSync(), isTrue);
        expect(File(path.join(projectPath, 'README.md')).existsSync(), isTrue);

        // Verify pubspec.yaml content
        final pubspecContent = File(path.join(projectPath, 'pubspec.yaml')).readAsStringSync();
        expect(pubspecContent.contains('name: $projectName'), isTrue);
        expect(pubspecContent.contains('description: A new Flutter project'), isTrue);
        expect(pubspecContent.contains('flutter:'), isTrue);

        // Verify main.dart content
        final mainContent = File(path.join(projectPath, 'lib', 'main.dart')).readAsStringSync();
        expect(mainContent.contains('MinimalExampleApp'), isTrue);
        expect(mainContent.contains('MinimalExampleHomePage'), isTrue);

        // Verify test content
        final testContent = File(path.join(projectPath, 'test', 'widget_test.dart')).readAsStringSync();
        expect(testContent.contains('MinimalExampleApp'), isTrue);
        expect(testContent.contains('testWidgets'), isTrue);
      });

      test('create riverpod project with all features', () async {
        const projectName = 'test_riverpod_project';
        final projectPath = path.join(tempDir.path, projectName);

        // Test project creation
        final result = await cli.createProject(
          projectName,
          template: 'riverpod',
          organization: 'com.test',
          platforms: ['ios', 'android', 'web'],
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, isNotEmpty);

        // Parse JSON output
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['success'] as bool, isTrue);
        final data = output['data'] as Map<String, dynamic>;
        final projectNameOutput = data['project_name'] as String;
        final templateOutput = data['template'] as String;
        expect(projectNameOutput, equals(projectName));
        expect(templateOutput, equals('riverpod'));

        // Verify project structure
        expect(Directory(projectPath).existsSync(), isTrue);
        expect(File(path.join(projectPath, 'pubspec.yaml')).existsSync(), isTrue);
        expect(File(path.join(projectPath, 'lib', 'main.dart')).existsSync(), isTrue);
        expect(File(path.join(projectPath, 'test', 'widget_test.dart')).existsSync(), isTrue);

        // Verify feature structure
        expect(Directory(path.join(projectPath, 'lib', 'features')).existsSync(), isTrue);
        expect(Directory(path.join(projectPath, 'lib', 'core')).existsSync(), isTrue);
        expect(Directory(path.join(projectPath, 'lib', 'features', 'home')).existsSync(), isTrue);
        expect(Directory(path.join(projectPath, 'lib', 'features', 'profile')).existsSync(), isTrue);

        // Verify pubspec.yaml content
        final pubspecContent = File(path.join(projectPath, 'pubspec.yaml')).readAsStringSync();
        expect(pubspecContent.contains('name: $projectName'), isTrue);
        expect(pubspecContent.contains('flutter_riverpod:'), isTrue);
        expect(pubspecContent.contains('go_router:'), isTrue);

        // Verify main.dart content
        final mainContent = File(path.join(projectPath, 'lib', 'main.dart')).readAsStringSync();
        expect(mainContent.contains('RiverpodExampleApp'), isTrue);
        expect(mainContent.contains('ProviderScope'), isTrue);
      });

      test('create project with plan mode', () async {
        const projectName = 'test_plan_project';

        // Test plan mode
        final result = await cli.runCommand('create', args: [projectName, '--template=minimal', '--plan']);

        expect(result.exitCode, equals(0));
        expect(result.stdout, isNotEmpty);

        // Parse JSON output
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['success'] as bool, isTrue);
        final data = output['data'] as Map<String, dynamic>;
        final projectNameOutput = data['project_name'] as String;
        expect(projectNameOutput, equals(projectName));

        // Verify project was NOT created in plan mode
        final projectPath = path.join(tempDir.path, projectName);
        expect(Directory(projectPath).existsSync(), isFalse);
      });

      test('create project with invalid name fails gracefully', () async {
        const projectName = 'Invalid Project Name!';

        // Test invalid project name
        final result = await cli.createProject(projectName);

        expect(result.exitCode, equals(1));
        expect(result.stdout, isNotEmpty);

        // Parse JSON output
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['success'] as bool, isFalse);
        final error = output['error'] as Map<String, dynamic>;
        final message = error['message'] as String;
        expect(message, contains('Invalid project name'));
      });
    });

    group('Add Commands E2E', () {
      late Directory testProject;

      setUpAll(() {
        testProject = Directory(path.join(tempDir.path, 'test_project'));
        testProject.createSync();
        
        // Create a minimal Flutter project structure
        File(path.join(testProject.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_project
description: A test project
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
''');
        
        Directory(path.join(testProject.path, 'lib')).createSync();
        Directory(path.join(testProject.path, 'test')).createSync();
      });

      test('add screen command works', () async {
        final result = await cli.addScreen(
          'test_screen',
          feature: 'home',
          type: 'generic',
          withViewModel: true,
          withTests: true,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, isNotEmpty);

        // Parse JSON output
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['success'] as bool, isTrue);
        final data = output['data'] as Map<String, dynamic>;
        final screenName = data['screen_name'] as String;
        expect(screenName, equals('test_screen'));

        // Verify files were created
        expect(File(path.join(testProject.path, 'lib', 'features', 'home', 'presentation', 'test_screen_screen.dart')).existsSync(), isTrue);
        expect(File(path.join(testProject.path, 'lib', 'features', 'home', 'providers', 'test_screen_provider.dart')).existsSync(), isTrue);
        expect(File(path.join(testProject.path, 'test', 'features', 'home', 'test_screen_screen_test.dart')).existsSync(), isTrue);
      });

      test('add service command works', () async {
        final result = await cli.addService(
          'test_service',
          feature: 'core',
          type: 'api',
          baseUrl: 'https://api.example.com',
          withTests: true,
          withMocks: true,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, isNotEmpty);

        // Parse JSON output
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['success'] as bool, isTrue);
        final data = output['data'] as Map<String, dynamic>;
        final serviceName = data['service_name'] as String;
        expect(serviceName, equals('test_service'));

        // Verify files were created
        expect(File(path.join(testProject.path, 'lib', 'features', 'core', 'services', 'test_service_service.dart')).existsSync(), isTrue);
        expect(File(path.join(testProject.path, 'test', 'features', 'core', 'services', 'test_service_service_test.dart')).existsSync(), isTrue);
        expect(File(path.join(testProject.path, 'test', 'features', 'core', 'mocks', 'test_service_service_mock.dart')).existsSync(), isTrue);
      });
    });

    group('Utility Commands E2E', () {
      test('doctor command works', () async {
        final result = await cli.runCommand('doctor');

        expect(result.exitCode, equals(0));
        expect(result.stdout, isNotEmpty);

        // Parse JSON output
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['success'] as bool, isTrue);
        final data = output['data'] as Map<String, dynamic>;
        final status = data['status'] as String;
        expect(status, equals('healthy'));
      });

      test('version command works', () async {
        final result = await cli.runCommand('version');

        expect(result.exitCode, equals(0));
        expect(result.stdout, isNotEmpty);

        // Parse JSON output
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['success'] as bool, isTrue);
        final data = output['data'] as Map<String, dynamic>;
        expect(data['version'], isNotEmpty);
      });

      test('schema export command works', () async {
        final result = await cli.runCommand('schema', args: ['export']);

        expect(result.exitCode, equals(0));
        expect(result.stdout, isNotEmpty);

        // Parse JSON output
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['success'] as bool, isTrue);
        final data = output['data'] as Map<String, dynamic>;
        final cliName = data['cli_name'] as String;
        expect(cliName, equals('fly'));
        final commands = data['commands'] as List<dynamic>;
        expect(commands, isA<List<dynamic>>());
        expect(commands.length, greaterThan(0));
      });

      test('context export command works', () async {
        // Create a test Flutter project
        final testProject = Directory(path.join(tempDir.path, 'context_test'));
        testProject.createSync();
        
        File(path.join(testProject.path, 'pubspec.yaml')).writeAsStringSync('''
name: context_test
description: A test project for context export
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
''');

        final result = await cli.runCommand('context', args: ['export', '--output=.ai/project_context.md', '--include-dependencies=true', '--include-structure=true', '--include-conventions=true']);

        expect(result.exitCode, equals(0));
        expect(result.stdout, isNotEmpty);

        // Parse JSON output
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['success'] as bool, isTrue);
        final data = output['data'] as Map<String, dynamic>;
        final outputPath = data['output_path'] as String;
        expect(outputPath, contains('.ai/project_context.md'));

        // Verify context file was created
        expect(File(path.join(testProject.path, '.ai', 'project_context.md')).existsSync(), isTrue);
      });
    });

    group('Error Handling E2E', () {
      test('invalid command fails gracefully', () async {
        final result = await cli.runCommand('invalid_command');

        expect(result.exitCode, equals(1));
        expect(result.stderr, isNotEmpty);
      });

      test('missing required arguments fail gracefully', () async {
        final result = await cli.runCommand('create');

        expect(result.exitCode, equals(1));
        expect(result.stdout, isNotEmpty);

        // Parse JSON output
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['success'] as bool, isFalse);
        final error = output['error'] as Map<String, dynamic>;
        final message = error['message'] as String;
        expect(message, contains('Project name is required'));
      });

      test('invalid template fails gracefully', () async {
        final result = await cli.createProject('test_project', template: 'invalid_template');

        expect(result.exitCode, equals(1));
        expect(result.stdout, isNotEmpty);

        // Parse JSON output
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['success'] as bool, isFalse);
        final error = output['error'] as Map<String, dynamic>;
        final message = error['message'] as String;
        expect(message, contains('Template "invalid_template" not found'));
      });
    });

    group('Performance E2E', () {
      test('project creation completes within reasonable time', () async {
        const projectName = 'performance_test_project';
        final stopwatch = Stopwatch()..start();

        final result = await cli.createProject(projectName);

        stopwatch.stop();

        expect(result.exitCode, equals(0));
        expect(stopwatch.elapsedMilliseconds, lessThan(30000)); // Should complete within 30 seconds

        // Parse JSON output
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['success'] as bool, isTrue);
        expect((output['data'] as Map<String, dynamic>)['duration_ms'], lessThan(30000));
      });

      test('multiple project creation works efficiently', () async {
        final projectNames = ['project1', 'project2', 'project3'];
        final stopwatch = Stopwatch()..start();

        for (final projectName in projectNames) {
          final result = await cli.createProject(projectName);

          expect(result.exitCode, equals(0));
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(60000)); // Should complete within 60 seconds for 3 projects
      });
    });

    group('Cross-Platform E2E', () {
      test('commands work on current platform', () async {
        // Test basic command functionality
        final result = await cli.runCommand('--version');

        expect(result.exitCode, equals(0));
        expect(result.stdout, isNotEmpty);
      });

      test('file operations work correctly', () async {
        const projectName = 'platform_test_project';
        final projectPath = path.join(tempDir.path, projectName);

        final result = await cli.createProject(projectName);

        expect(result.exitCode, equals(0));

        // Verify platform-specific file operations work
        expect(Directory(projectPath).existsSync(), isTrue);
        expect(File(path.join(projectPath, 'pubspec.yaml')).existsSync(), isTrue);
        
        // Test file reading
        final pubspecContent = File(path.join(projectPath, 'pubspec.yaml')).readAsStringSync();
        expect(pubspecContent, isNotEmpty);
        expect(pubspecContent.contains('name: $projectName'), isTrue);
      });
    });
  });
}
