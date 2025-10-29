import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import '../helpers/cli_test_helper.dart';

void main() {
  group('JSON Output Validation', () {
    late Directory tempDir;
    late CliTestHelper cli;

    setUp(() {
      final testRunId = DateTime.now().millisecondsSinceEpoch;
      tempDir = Directory('${Directory.current.path}/test_generated/json_$testRunId');
      tempDir.createSync(recursive: true);
      cli = CliTestHelper(tempDir);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('Create Command JSON Output', () {
      test('successful project creation returns valid JSON', () async {
        const projectName = 'json_create_test';
        
        final result = await cli.createProject(projectName);

        expect(result.exitCode, equals(0));
        expect(result.stdout, isNotEmpty);
        
        // Parse and validate JSON
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output, isA<Map<String, dynamic>>());
        expect(output['success'], isTrue);
        expect(output['command'] as String, equals('create'));
        expect(output['message'] as String, isA<String>());
        expect(output['data'], isA<Map<String, dynamic>>());
        expect((output['data'] as Map<String, dynamic>)['project_name'], equals(projectName));
        expect((output['data'] as Map<String, dynamic>)['template'], equals('minimal'));
        expect((output['data'] as Map<String, dynamic>)['files_generated'], isA<int>());
        expect((output['data'] as Map<String, dynamic>)['duration_ms'], isA<int>());
        expect((output['data'] as Map<String, dynamic>)['target_directory'], isA<String>());
        expect(output['next_steps'], isA<List>());
        
        // Clean up the created project
        final projectDir = Directory(path.join(tempDir.path, projectName));
        if (projectDir.existsSync()) {
          projectDir.deleteSync(recursive: true);
        }
      });

      test('failed project creation returns valid error JSON', () async {
        final result = await cli.createProject('Invalid Project Name!');

        expect(result.exitCode, equals(1));
        expect(result.stdout, isNotEmpty);
        
        // Parse and validate error JSON
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output, isA<Map<String, dynamic>>());
        expect(output['success'], isFalse);
        expect(output['command'] as String, equals('create'));
        expect(output['error'], isA<Map<String, dynamic>>());
        expect(output['error']['message'], isA<String>());
        expect(output['error']['suggestion'], isA<String>());
      });

      test('plan mode returns valid JSON', () async {
        const projectName = 'json_plan_test';
        
        final result = await cli.runCommand('create', args: [projectName, '--template=minimal', '--plan']);

        expect(result.exitCode, equals(0));
        expect(result.stdout, isNotEmpty);
        
        // Parse and validate plan JSON
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output, isA<Map<String, dynamic>>());
        expect(output['success'], isTrue);
        expect(output['command'] as String, equals('create'));
        expect(output['data'], isA<Map<String, dynamic>>());
        expect((output['data'] as Map<String, dynamic>)['project_name'], equals(projectName));
        expect((output['data'] as Map<String, dynamic>)['template'], equals('minimal'));
        expect((output['data'] as Map<String, dynamic>)['estimated_duration_ms'], isA<int>());
        expect((output['data'] as Map<String, dynamic>)['files_to_create'], isA<int>());
      });
    });

    group('Add Commands JSON Output', () {
      late Directory testProject;

      setUpAll(() {
        testProject = Directory(path.join(tempDir.path, 'add_commands_json_test'));
        testProject.createSync();

        // Create a minimal Flutter project structure
        File(path.join(testProject.path, 'pubspec.yaml')).writeAsStringSync('''
name: add_commands_json_test
description: A test project for add commands JSON output
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

      test('add screen command returns valid JSON', () async {
        final result = await cli.addScreen(
          'test_screen',
          feature: 'home',
          type: 'generic',
          withViewModel: true,
          withTests: true,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, isNotEmpty);
        
        // Parse and validate JSON
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output, isA<Map<String, dynamic>>());
        expect(output['success'], isTrue);
        expect(output['command'] as String, equals('add screen'));
        expect(output['message'] as String, isA<String>());
        expect(output['data'], isA<Map<String, dynamic>>());
        expect((output['data'] as Map<String, dynamic>)['screen_name'], equals('test_screen'));
        expect((output['data'] as Map<String, dynamic>)['feature'], equals('home'));
        expect((output['data'] as Map<String, dynamic>)['type'], equals('generic'));
        expect((output['data'] as Map<String, dynamic>)['files_generated'], isA<int>());
        expect((output['data'] as Map<String, dynamic>)['duration_ms'], isA<int>());
      });

      test('add service command returns valid JSON', () async {
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
        
        // Parse and validate JSON
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output, isA<Map<String, dynamic>>());
        expect(output['success'], isTrue);
        expect(output['command'] as String, equals('add service'));
        expect(output['message'] as String, isA<String>());
        expect(output['data'], isA<Map<String, dynamic>>());
        expect((output['data'] as Map<String, dynamic>)['service_name'], equals('test_service'));
        expect(output['data']['feature'], equals('core'));
        expect(output['data']['type'], equals('api'));
        expect((output['data'] as Map<String, dynamic>)['base_url'], equals('https://api.example.com'));
        expect((output['data'] as Map<String, dynamic>)['files_generated'], isA<int>());
        expect((output['data'] as Map<String, dynamic>)['duration_ms'], isA<int>());
      });
    });

    group('Utility Commands JSON Output', () {
      test('doctor command returns valid JSON', () async {
        final result = await cli.runCommand('doctor');

        expect(result.exitCode, equals(0));
        expect(result.stdout, isNotEmpty);
        
        // Parse and validate JSON
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output, isA<Map<String, dynamic>>());
        expect(output['success'], isTrue);
        expect(output['command'] as String, equals('doctor'));
        expect(output['message'] as String, isA<String>());
        expect(output['data'], isA<Map<String, dynamic>>());
        expect((output['data'] as Map<String, dynamic>)['status'], isA<String>());
        expect((output['data'] as Map<String, dynamic>)['checks'], isA<List<dynamic>>());
      });

      test('version command returns valid JSON', () async {
        final result = await cli.runCommand('version');

        expect(result.exitCode, equals(0));
        expect(result.stdout, isNotEmpty);
        
        // Parse and validate JSON
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output, isA<Map<String, dynamic>>());
        expect(output['success'], isTrue);
        expect(output['command'] as String, equals('version'));
        expect(output['message'] as String, isA<String>());
        expect(output['data'], isA<Map<String, dynamic>>());
        expect((output['data'] as Map<String, dynamic>)['version'], isA<String>());
        expect((output['data'] as Map<String, dynamic>)['version'], isNotEmpty);
      });

      test('schema export command returns valid JSON', () async {
        final result = await cli.runCommand('schema', args: ['export']);

        expect(result.exitCode, equals(0));
        expect(result.stdout, isNotEmpty);
        
        // Parse and validate JSON
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output, isA<Map<String, dynamic>>());
        expect(output['success'], isTrue);
        expect(output['command'] as String, equals('schema export'));
        expect(output['message'] as String, isA<String>());
        expect(output['data'], isA<Map<String, dynamic>>());
        expect((output['data'] as Map<String, dynamic>)['cli_name'], equals('fly'));
        expect((output['data'] as Map<String, dynamic>)['commands'], isA<List<dynamic>>());
        expect(((output['data'] as Map<String, dynamic>)['commands'] as List<dynamic>).length, greaterThan(0));
      });

      test('context export command returns valid JSON', () async {
        // Create a test Flutter project
        final testProject = Directory(path.join(tempDir.path, 'context_json_test'));
        testProject.createSync();
        
        File(path.join(testProject.path, 'pubspec.yaml')).writeAsStringSync('''
name: context_json_test
description: A test project for context export JSON output
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
        
        // Parse and validate JSON
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output, isA<Map<String, dynamic>>());
        expect(output['success'], isTrue);
        expect(output['command'] as String, equals('context export'));
        expect(output['message'] as String, isA<String>());
        expect(output['data'], isA<Map<String, dynamic>>());
        expect((output['data'] as Map<String, dynamic>)['output_path'], isA<String>());
        expect((output['data'] as Map<String, dynamic>)['output_path'], contains('.ai/project_context.md'));
      });
    });

    group('JSON Schema Validation', () {
      test('all JSON outputs follow consistent schema', () async {
        final commands = [
          ['--version'],
          ['doctor'],
          ['schema', 'export'],
        ];
        
        for (final command in commands) {
          final result = await cli.runCliCommand(command);
          expect(result.exitCode, equals(0));
          expect(result.stdout, isNotEmpty);
          
          // Parse and validate JSON schema
          final output = json.decode(result.stdout as String) as Map<String, dynamic>;
          expect(output, isA<Map<String, dynamic>>());
          expect(output['success'], isA<bool>());
          expect(output['command'], isA<String>());
          expect(output['message'] as String, isA<String>());
          expect(output['data'], isA<Map<String, dynamic>>());
        }
      });

      test('error JSON outputs follow consistent schema', () async {
        final commands = [
          ['create', 'Invalid Name!'],
          ['create', 'test', '--template=invalid'],
        ];
        
        for (final command in commands) {
          final result = await cli.runCliCommand(command);
          expect(result.exitCode, equals(1));
          expect(result.stdout, isNotEmpty);
          
          // Parse and validate error JSON schema
          final output = json.decode(result.stdout as String) as Map<String, dynamic>;
          expect(output, isA<Map<String, dynamic>>());
          expect(output['success'], isFalse);
          expect(output['command'], isA<String>());
          expect(output['error'], isA<Map<String, dynamic>>());
          expect(output['error']['message'], isA<String>());
          expect(output['error']['suggestion'], isA<String>());
        }
      });
    });

    group('JSON Content Validation', () {
      test('JSON contains no sensitive information', () async {
        final result = await cli.runCommand('doctor');

        expect(result.exitCode, equals(0));
        
        final outputString = result.stdout;
        expect(outputString.contains('password'), isFalse);
        expect(outputString.contains('secret'), isFalse);
        expect(outputString.contains('token'), isFalse);
        expect(outputString.contains('key'), isFalse);
      });

      test('JSON contains proper error messages', () async {
        final result = await cli.createProject('Invalid Project Name!');

        expect(result.exitCode, equals(1));
        
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['error']['message'], isNotEmpty);
        expect(output['error']['suggestion'], isNotEmpty);
        expect(output['error']['message'], contains('Invalid project name'));
      });

      test('JSON contains proper success messages', () async {
        const projectName = 'json_success_test';
        
        final result = await cli.createProject(projectName);

        expect(result.exitCode, equals(0));
        
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['message'], isNotEmpty);
        expect(output['message'], contains('created successfully'));
        expect((output['data'] as Map<String, dynamic>)['project_name'], equals(projectName));
      });
    });

    group('JSON Performance Validation', () {
      test('JSON output is generated quickly', () async {
        const projectName = 'json_performance_test';
        
        final stopwatch = Stopwatch()..start();
        
        final result = await cli.createProject(projectName);

        stopwatch.stop();
        
        expect(result.exitCode, equals(0));
        expect(stopwatch.elapsedMilliseconds, lessThan(30000)); // Should complete within 30 seconds
        
        // Verify JSON is valid
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['success'], isTrue);
      });

      test('JSON output size is reasonable', () async {
        const projectName = 'json_size_test';
        
        final result = await cli.createProject(projectName);

        expect(result.exitCode, equals(0));
        
        // Verify JSON output size is reasonable (less than 10KB)
        expect(result.stdout.length, lessThan(10000));
        
        // Verify JSON is valid
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['success'], isTrue);
      });
    });

    group('JSON Edge Cases', () {
      test('empty project name returns valid error JSON', () async {
        final result = await cli.createProject('');

        expect(result.exitCode, equals(1));
        
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['success'], isFalse);
        expect(output['error']['message'], contains('Project name is required'));
      });

      test('missing arguments return valid error JSON', () async {
        final result = await cli.runCommand('create');

        expect(result.exitCode, equals(1));
        
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['success'], isFalse);
        expect(output['error']['message'], contains('Project name is required'));
      });

      test('invalid template returns valid error JSON', () async {
        final result = await cli.createProject('test_project', template: 'invalid_template');

        expect(result.exitCode, equals(1));
        
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['success'], isFalse);
        expect(output['error']['message'], contains('Template "invalid_template" not found'));
      });
    });
  });
}
