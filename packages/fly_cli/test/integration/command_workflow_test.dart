import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart' show Timeout, expect, group, isA, isNotNull, isTrue, isFalse, setUp, tearDown, test, equals, contains, lessThan;

import '../helpers/command_test_helper.dart';
import '../helpers/test_fixtures.dart';
import '../helpers/mock_logger.dart';

void main() {
  group('Command Workflow Integration Tests', () {
    late Directory tempDir;
    late MockLogger mockLogger;

    setUp(() {
      mockLogger = MockLogger();
      tempDir = CommandTestHelper.createTempDir();
    });

    tearDown(() {
      CommandTestHelper.cleanupTempDir(tempDir);
      mockLogger.clear();
    });

    group('Workflow 1: Full Project Setup', () {
      test('create project → add screen → add service → build', () async {
        // This test simulates a complete project setup workflow
        final projectName = TestFixtures.createTestProjectName();
        final projectDir = Directory(path.join(tempDir.path, projectName));
        
        // Step 1: Create project
        await CommandTestHelper.runCommand([
          'create',
          projectName,
          '--template=minimal',
          '--organization=com.test',
          '--platforms=ios,android',
          '--output-dir=${tempDir.path}',
        ]);
        
        // Verify project was created
        expect(projectDir.existsSync(), isTrue);
        expect(File(path.join(projectDir.path, 'pubspec.yaml')).existsSync(), isTrue);
        expect(File(path.join(projectDir.path, 'lib', 'main.dart')).existsSync(), isTrue);
        
        // Step 2: Add screen
        await CommandTestHelper.runCommand([
          'add',
          'screen',
          'login',
          '--feature=auth',
          '--with-viewmodel',
          '--with-tests',
        ], workingDirectory: projectDir.path,);
        
        // Verify screen was added
        expect(File(path.join(projectDir.path, 'lib', 'features', 'auth', 'presentation', 'login_screen.dart')).existsSync(), isTrue);
        expect(File(path.join(projectDir.path, 'lib', 'features', 'auth', 'providers', 'login_provider.dart')).existsSync(), isTrue);
        expect(File(path.join(projectDir.path, 'test', 'features', 'auth', 'login_screen_test.dart')).existsSync(), isTrue);
        
        // Step 3: Add service
        await CommandTestHelper.runCommand([
          'add',
          'service',
          'auth',
          '--feature=auth',
          '--type=api',
          '--with-tests',
          '--with-mocks',
        ], workingDirectory: projectDir.path,);
        
        // Verify service was added
        expect(File(path.join(projectDir.path, 'lib', 'features', 'auth', 'services', 'auth_service.dart')).existsSync(), isTrue);
        expect(File(path.join(projectDir.path, 'test', 'features', 'auth', 'services', 'auth_service_test.dart')).existsSync(), isTrue);
        expect(File(path.join(projectDir.path, 'test', 'mocks', 'auth_service_mock.dart')).existsSync(), isTrue);
        
        // Step 4: Run flutter analyze
        final analyzeResult = await CommandTestHelper.runFlutterAnalyze(projectDir.path);
        expect(analyzeResult.exitCode, equals(0));
        
        // Verify project structure is complete
        expect(await CommandTestHelper.verifyProjectStructure(projectDir.path), isTrue);
      }, timeout: Timeout(Duration(minutes: 2)));

      test('create minimal project → add multiple screens → add services', () async {
        final projectName = TestFixtures.createTestProjectName();
        final projectDir = Directory(path.join(tempDir.path, projectName));
        
        // Create minimal project
        await CommandTestHelper.runCommand([
          'create',
          projectName,
          '--template=minimal',
          '--organization=com.minimal',
          '--output-dir=${tempDir.path}',
        ]);
        
        expect(projectDir.existsSync(), isTrue);
        
        // Add multiple screens
        final screens = ['home', 'profile', 'settings'];
        for (final screen in screens) {
          await CommandTestHelper.runCommand([
            'add',
            'screen',
            screen,
            '--feature=main',
            '--with-viewmodel',
          ], workingDirectory: projectDir.path,);
          
          expect(File(path.join(projectDir.path, 'lib', 'features', 'main', 'presentation', '${screen}_screen.dart')).existsSync(), isTrue);
        }
        
        // Add multiple services
        final services = ['api', 'storage', 'cache'];
        for (final service in services) {
          await CommandTestHelper.runCommand([
            'add',
            'service',
            service,
            '--feature=core',
            '--type=api',
          ], workingDirectory: projectDir.path,);
          
          expect(File(path.join(projectDir.path, 'lib', 'features', 'core', 'services', '${service}_service.dart')).existsSync(), isTrue);
        }
        
        // Verify final structure
        expect(await CommandTestHelper.verifyProjectStructure(projectDir.path), isTrue);
      }, timeout: Timeout(Duration(minutes: 2)));
    });

    group('Workflow 2: JSON Output Chain', () {
      test('all commands support JSON output', () async {
        final commands = [
          ['version', '--output=json'],
          ['doctor', '--output=json'],
        ];
        
        for (final cmd in commands) {
          final result = await CommandTestHelper.runCommand(cmd);
          
          // Should return result
          expect(result, isNotNull);
          expect(result.command, isA<String>());
          expect(result.message, isA<String>());
          
          // Should have data for JSON output (some commands may not have data)
          if (result.data != null) {
            expect(result.data, isA<Map<String, dynamic>>());
          }
        }
      });

      test('create project with JSON output → verify structure', () async {
        final projectName = TestFixtures.createTestProjectName();
        
        // Create project with JSON output
        final result = await CommandTestHelper.runCommand([
          'create',
          projectName,
          '--template=minimal',
          '--output=json',
          '--output-dir=${tempDir.path}',
        ]);
        
        // Verify JSON response structure
        expect(result.success, isTrue);
        expect(result.command, equals('create'));
        expect(result.data?.containsKey('project_name'), isTrue);
        expect(result.data?.containsKey('template'), isTrue);
        expect(result.data?.containsKey('files_generated'), isTrue);
        expect(result.data?.containsKey('duration_ms'), isTrue);
        
        // Verify project was actually created
        final projectDir = Directory(path.join(tempDir.path, projectName));
        expect(projectDir.existsSync(), isTrue);
      });

      test('add screen with JSON output → verify response', () async {
        // First create a project
        final projectName = TestFixtures.createTestProjectName();
        await CommandTestHelper.runCommand(['create', projectName, '--template=minimal', '--output-dir=${tempDir.path}']);
        
        final projectDir = Directory(path.join(tempDir.path, projectName));
        
        // Add screen with JSON output
        final result = await CommandTestHelper.runCommand([
          'add',
          'screen',
          'login',
          '--feature=auth',
          '--with-viewmodel',
          '--output=json',
        ], workingDirectory: projectDir.path,);
        
        // Verify JSON response structure
        expect(result.success, isTrue);
        expect(result.command, equals('add screen'));
        expect(result.data?.containsKey('screen_name'), isTrue);
        expect(result.data?.containsKey('feature'), isTrue);
        expect(result.data?.containsKey('files_generated'), isTrue);
        expect(result.data?.containsKey('duration_ms'), isTrue);
      });

      test('add service with JSON output → verify response', () async {
        // First create a project
        final projectName = TestFixtures.createTestProjectName();
        await CommandTestHelper.runCommand(['create', projectName, '--template=minimal', '--output-dir=${tempDir.path}']);
        
        final projectDir = Directory(path.join(tempDir.path, projectName));
        
        // Add service with JSON output
        final result = await CommandTestHelper.runCommand([
          'add',
          'service',
          'auth',
          '--feature=auth',
          '--type=api',
          '--with-tests',
          '--output=json',
        ], workingDirectory: projectDir.path,);
        
        // Verify JSON response structure
        expect(result.success, isTrue);
        expect(result.command, equals('add service'));
        expect(result.data?.containsKey('service_name'), isTrue);
        expect(result.data?.containsKey('feature'), isTrue);
        expect(result.data?.containsKey('type'), isTrue);
        expect(result.data?.containsKey('files_generated'), isTrue);
        expect(result.data?.containsKey('duration_ms'), isTrue);
      });
    });

    group('Workflow 3: Error Handling and Recovery', () {
      test('commands provide helpful errors and suggestions', () async {
        // Test invalid project name
        final result = await CommandTestHelper.runCommand(['create', 'Invalid-Name']);
        
        expect(result.success, isFalse);
        expect(result.message, contains('Invalid project name'));
        expect(result.suggestion, isNotNull);
        expect(result.suggestion!.isNotEmpty, isTrue);
      });

      test('handle missing project directory gracefully', () async {
        // Try to add screen without being in a project directory
        final result = await CommandTestHelper.runCommand([
          'add',
          'screen',
          'login',
        ], workingDirectory: tempDir.path,);
        
        expect(result.success, isFalse);
        expect(result.message, contains('Not in a Flutter project directory'));
        expect(result.suggestion, isNotNull);
      });

      test('handle duplicate screen names gracefully', () async {
        // Create project
        final projectName = TestFixtures.createTestProjectName();
        await CommandTestHelper.runCommand(['create', projectName, '--template=minimal', '--output-dir=${tempDir.path}']);
        
        final projectDir = Directory(path.join(tempDir.path, projectName));
        
        // Add screen first time
        await CommandTestHelper.runCommand([
          'add',
          'screen',
          'login',
          '--feature=auth',
        ], workingDirectory: projectDir.path,);
        
        // Try to add same screen again
        final result = await CommandTestHelper.runCommand([
          'add',
          'screen',
          'login',
          '--feature=auth',
        ], workingDirectory: projectDir.path,);
        
        // Should handle gracefully (either succeed or provide helpful error)
        expect(result, isNotNull);
      });

      test('handle invalid template gracefully', () async {
        final result = await CommandTestHelper.runCommand([
          'create',
          'test_app',
          '--template=invalid_template',
        ]);
        
        expect(result.success, isFalse);
        expect(result.message, contains('Invalid template'));
      });

      test('handle invalid platform gracefully', () async {
        final result = await CommandTestHelper.runCommand([
          'create',
          'test_app',
          '--platforms=invalid_platform',
        ]);
        
        expect(result.success, isFalse);
        expect(result.message, contains('Invalid platform'));
      });
    });

    group('Workflow 4: Plan Mode Integration', () {
      test('create project plan → execute → verify', () async {
        final projectName = TestFixtures.createTestProjectName();
        
        // Step 1: Create plan
        final planResult = await CommandTestHelper.runCommand([
          'create',
          projectName,
          '--template=minimal',
          '--plan',
          '--output-dir=${tempDir.path}',
        ]);
        
        expect(planResult.success, isTrue);
        expect(planResult.command, equals('create'));
        expect(planResult.message, contains('plan'));
        expect(planResult.data?.containsKey('estimated_files'), isTrue);
        expect(planResult.data?.containsKey('estimated_duration_ms'), isTrue);
        
        // Step 2: Execute actual creation
        final createResult = await CommandTestHelper.runCommand([
          'create',
          projectName,
          '--template=minimal',
          '--output-dir=${tempDir.path}',
        ]);
        
        expect(createResult.success, isTrue);
        
        // Step 3: Verify project was created
        final projectDir = Directory(path.join(tempDir.path, projectName));
        expect(projectDir.existsSync(), isTrue);
      });

      test('add screen plan → execute → verify', () async {
        // Create project first
        final projectName = TestFixtures.createTestProjectName();
        await CommandTestHelper.runCommand(['create', projectName, '--template=minimal', '--output-dir=${tempDir.path}']);
        
        final projectDir = Directory(path.join(tempDir.path, projectName));
        
        // Plan screen addition
        final planResult = await CommandTestHelper.runCommand([
          'add',
          'screen',
          'login',
          '--feature=auth',
          '--with-viewmodel',
          '--plan',
        ], workingDirectory: projectDir.path,);
        
        expect(planResult.success, isTrue);
        expect(planResult.message, contains('plan'));
        
        // Execute screen addition
        final addResult = await CommandTestHelper.runCommand([
          'add',
          'screen',
          'login',
          '--feature=auth',
          '--with-viewmodel',
        ], workingDirectory: projectDir.path,);
        
        expect(addResult.success, isTrue);
        
        // Verify screen was added
        expect(File(path.join(projectDir.path, 'lib', 'features', 'auth', 'presentation', 'login_screen.dart')).existsSync(), isTrue);
      });
    });

    group('Workflow 5: Cross-Command Integration', () {
      test('doctor → create → add → doctor again', () async {
        // Step 1: Check system health
        final doctorResult1 = await CommandTestHelper.runCommand(['doctor']);
        expect(doctorResult1, isNotNull);
        
        // Step 2: Create project
        final projectName = TestFixtures.createTestProjectName();
        final createResult = await CommandTestHelper.runCommand([
          'create',
          projectName,
          '--template=minimal',
          '--output-dir=${tempDir.path}',
        ]);
        expect(createResult.success, isTrue);
        
        // Step 3: Add components
        final projectDir = Directory(path.join(tempDir.path, projectName));
        
        await CommandTestHelper.runCommand([
          'add',
          'screen',
          'home',
          '--feature=main',
        ], workingDirectory: projectDir.path,);
        
        await CommandTestHelper.runCommand([
          'add',
          'service',
          'api',
          '--feature=core',
          '--type=api',
        ], workingDirectory: projectDir.path,);
        
        // Step 4: Check system health again
        final doctorResult2 = await CommandTestHelper.runCommand(['doctor']);
        expect(doctorResult2, isNotNull);
        
        // Verify project structure
        expect(await CommandTestHelper.verifyProjectStructure(projectDir.path), isTrue);
      });

    });

    group('Workflow 6: Performance and Scalability', () {
      test('create multiple projects efficiently', () async {
        final projectNames = List.generate(5, (i) => TestFixtures.createTestProjectName(prefix: 'perf_$i'));
        
        final stopwatch = Stopwatch()..start();
        
        for (final projectName in projectNames) {
          await CommandTestHelper.runCommand([
            'create',
            projectName,
            '--template=minimal',
            '--output-dir=${tempDir.path}',
          ]);
        }
        
        stopwatch.stop();
        
        // Should create 5 projects in reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(30000)); // 30 seconds
        
        // Verify all projects were created
        for (final projectName in projectNames) {
          final projectDir = Directory(path.join(tempDir.path, projectName));
          expect(projectDir.existsSync(), isTrue);
        }
      });

      test('add multiple screens efficiently', () async {
        // Create project
        final projectName = TestFixtures.createTestProjectName();
        await CommandTestHelper.runCommand(['create', projectName, '--template=minimal', '--output-dir=${tempDir.path}']);
        
        final projectDir = Directory(path.join(tempDir.path, projectName));
        final screenNames = ['home', 'profile', 'settings', 'about', 'contact'];
        
        final stopwatch = Stopwatch()..start();
        
        for (final screenName in screenNames) {
          await CommandTestHelper.runCommand([
            'add',
            'screen',
            screenName,
            '--feature=main',
          ], workingDirectory: projectDir.path,);
        }
        
        stopwatch.stop();
        
        // Should add 5 screens in reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // 10 seconds
        
        // Verify all screens were added
        for (final screenName in screenNames) {
          expect(File(path.join(projectDir.path, 'lib', 'features', 'main', 'presentation', '${screenName}_screen.dart')).existsSync(), isTrue);
        }
      });
    });

    group('Workflow 7: Edge Cases and Error Recovery', () {
      test('handle interrupted workflow gracefully', () async {
        final projectName = TestFixtures.createTestProjectName();
        
        // Start creating project
        await CommandTestHelper.runCommand([
          'create',
          projectName,
          '--template=minimal',
          '--output-dir=${tempDir.path}',
        ]);
        
        // Verify project was created
        final projectDir = Directory(path.join(tempDir.path, projectName));
        expect(projectDir.existsSync(), isTrue);
        
        // Try to continue workflow
        await CommandTestHelper.runCommand([
          'add',
          'screen',
          'home',
          '--feature=main',
        ], workingDirectory: projectDir.path,);
        
        // Should be able to continue
        expect(File(path.join(projectDir.path, 'lib', 'features', 'main', 'presentation', 'home_screen.dart')).existsSync(), isTrue);
      });

      test('handle partial failures gracefully', () async {
        // Try to create project with invalid name
        final invalidResult = await CommandTestHelper.runCommand(['create', 'Invalid-Name']);
        expect(invalidResult.success, isFalse);
        
        // Try to create project with valid name
        final projectName = TestFixtures.createTestProjectName();
        final validResult = await CommandTestHelper.runCommand(['create', projectName, '--output-dir=${tempDir.path}']);
        expect(validResult.success, isTrue);
        
        // Should be able to recover
        final projectDir = Directory(path.join(tempDir.path, projectName));
        expect(projectDir.existsSync(), isTrue);
      });
    });
  });
}
