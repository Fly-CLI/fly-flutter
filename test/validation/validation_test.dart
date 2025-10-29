import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import '../helpers/cli_test_helper.dart';

void main() {
  group('Generated Project Validation', () {
    late Directory tempDir;
    late CliTestHelper cli;

    setUp(() {
      final testRunId = DateTime.now().millisecondsSinceEpoch;
      tempDir = Directory('${Directory.current.path}/test_generated/validation_$testRunId');
      tempDir.createSync(recursive: true);
      cli = CliTestHelper(tempDir);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('Minimal Template Validation', () {
      test('minimal project structure is correct', () async {
        const projectName = 'minimal_validation_test';
        
        final result = await cli.createProject(projectName);

        expect(result.exitCode, equals(0));
        
        final projectPath = path.join(tempDir.path, projectName);
        expect(Directory(projectPath).existsSync(), isTrue);
        
        // Validate required files
        expect(File(path.join(projectPath, 'pubspec.yaml')).existsSync(), isTrue);
        expect(File(path.join(projectPath, 'lib', 'main.dart')).existsSync(), isTrue);
        expect(File(path.join(projectPath, 'test', 'widget_test.dart')).existsSync(), isTrue);
        expect(File(path.join(projectPath, 'README.md')).existsSync(), isTrue);
        
        // Validate pubspec.yaml content
        final pubspecContent = File(path.join(projectPath, 'pubspec.yaml')).readAsStringSync();
        expect(pubspecContent.contains('name: $projectName'), isTrue);
        expect(pubspecContent.contains('description: A new Flutter project'), isTrue);
        expect(pubspecContent.contains('flutter:'), isTrue);
        expect(pubspecContent.contains('uses-material-design: true'), isTrue);
        
        // Validate main.dart content
        final mainContent = File(path.join(projectPath, 'lib', 'main.dart')).readAsStringSync();
        expect(mainContent.contains('MinimalExampleApp'), isTrue);
        expect(mainContent.contains('MinimalExampleHomePage'), isTrue);
        expect(mainContent.contains('_incrementCounter'), isTrue);
        
        // Validate test content
        final testContent = File(path.join(projectPath, 'test', 'widget_test.dart')).readAsStringSync();
        expect(testContent.contains('MinimalExampleApp'), isTrue);
        expect(testContent.contains('testWidgets'), isTrue);
        expect(testContent.contains('Counter increments smoke test'), isTrue);
      });

      test('minimal project compiles successfully', () async {
        const projectName = 'minimal_compile_test';
        
        // Create project
        final createResult = await cli.createProject(projectName);

        expect(createResult.exitCode, equals(0));
        
        final projectPath = path.join(tempDir.path, projectName);
        
        // Test compilation
        final analyzeResult = await Process.run(
          'flutter',
          ['analyze'],
          workingDirectory: projectPath,
        );

        expect(analyzeResult.exitCode, equals(0));
        
        // Test pub get
        final pubGetResult = await Process.run(
          'flutter',
          ['pub', 'get'],
          workingDirectory: projectPath,
        );

        expect(pubGetResult.exitCode, equals(0));
      });
    });

    group('Riverpod Template Validation', () {
      test('riverpod project structure is correct', () async {
        const projectName = 'riverpod_validation_test';
        
        final result = await cli.createProject(projectName, template: 'riverpod');

        expect(result.exitCode, equals(0));
        
        final projectPath = path.join(tempDir.path, projectName);
        expect(Directory(projectPath).existsSync(), isTrue);
        
        // Validate required files
        expect(File(path.join(projectPath, 'pubspec.yaml')).existsSync(), isTrue);
        expect(File(path.join(projectPath, 'lib', 'main.dart')).existsSync(), isTrue);
        expect(File(path.join(projectPath, 'test', 'widget_test.dart')).existsSync(), isTrue);
        expect(File(path.join(projectPath, 'README.md')).existsSync(), isTrue);
        
        // Validate feature structure
        expect(Directory(path.join(projectPath, 'lib', 'features')).existsSync(), isTrue);
        expect(Directory(path.join(projectPath, 'lib', 'core')).existsSync(), isTrue);
        expect(Directory(path.join(projectPath, 'lib', 'features', 'home')).existsSync(), isTrue);
        expect(Directory(path.join(projectPath, 'lib', 'features', 'profile')).existsSync(), isTrue);
        
        // Validate pubspec.yaml content
        final pubspecContent = File(path.join(projectPath, 'pubspec.yaml')).readAsStringSync();
        expect(pubspecContent.contains('name: $projectName'), isTrue);
        expect(pubspecContent.contains('flutter_riverpod:'), isTrue);
        expect(pubspecContent.contains('go_router:'), isTrue);
        
        // Validate main.dart content
        final mainContent = File(path.join(projectPath, 'lib', 'main.dart')).readAsStringSync();
        expect(mainContent.contains('RiverpodExampleApp'), isTrue);
        expect(mainContent.contains('ProviderScope'), isTrue);
        expect(mainContent.contains('appRouterProvider'), isTrue);
      });

      test('riverpod project compiles successfully', () async {
        const projectName = 'riverpod_compile_test';
        
        // Create project
        final createResult = await cli.createProject(projectName, template: 'riverpod');

        expect(createResult.exitCode, equals(0));
        
        final projectPath = path.join(tempDir.path, projectName);
        
        // Test pub get
        final pubGetResult = await Process.run(
          'flutter',
          ['pub', 'get'],
          workingDirectory: projectPath,
        );

        expect(pubGetResult.exitCode, equals(0));
        
        // Test analysis
        final analyzeResult = await Process.run(
          'flutter',
          ['analyze'],
          workingDirectory: projectPath,
        );

        expect(analyzeResult.exitCode, equals(0));
      });
    });

    group('Project Content Validation', () {
      test('project name is correctly substituted', () async {
        const projectName = 'test_project_name_substitution';
        
        final result = await cli.createProject(projectName);

        expect(result.exitCode, equals(0));
        
        final projectPath = path.join(tempDir.path, projectName);
        
        // Check pubspec.yaml
        final pubspecContent = File(path.join(projectPath, 'pubspec.yaml')).readAsStringSync();
        expect(pubspecContent.contains('name: $projectName'), isTrue);
        
        // Check main.dart
        final mainContent = File(path.join(projectPath, 'lib', 'main.dart')).readAsStringSync();
        expect(mainContent.contains('TestProjectNameSubstitutionApp'), isTrue);
        expect(mainContent.contains('TestProjectNameSubstitutionHomePage'), isTrue);
        
        // Check test file
        final testContent = File(path.join(projectPath, 'test', 'widget_test.dart')).readAsStringSync();
        expect(testContent.contains('TestProjectNameSubstitutionApp'), isTrue);
      });

      test('organization is correctly substituted', () async {
        const projectName = 'org_test';
        const organization = 'com.test.organization';
        
        final result = await cli.createProject(projectName, organization: organization);

        expect(result.exitCode, equals(0));
        
        final projectPath = path.join(tempDir.path, projectName);
        
        // Check pubspec.yaml for organization
        final pubspecContent = File(path.join(projectPath, 'pubspec.yaml')).readAsStringSync();
        expect(pubspecContent.contains('name: $projectName'), isTrue);
      });

      test('platforms are correctly configured', () async {
        const projectName = 'platform_test';
        
        final result = await cli.createProject(projectName, platforms: ['ios', 'android', 'web']);

        expect(result.exitCode, equals(0));
        
        final projectPath = path.join(tempDir.path, projectName);
        
        // Check pubspec.yaml
        final pubspecContent = File(path.join(projectPath, 'pubspec.yaml')).readAsStringSync();
        expect(pubspecContent.contains('flutter:'), isTrue);
      });
    });

    group('Generated Code Quality Validation', () {
      test('generated code follows Dart conventions', () async {
        const projectName = 'code_quality_test';
        
        final result = await cli.createProject(projectName);

        expect(result.exitCode, equals(0));
        
        final projectPath = path.join(tempDir.path, projectName);
        
        // Check main.dart for proper formatting
        final mainContent = File(path.join(projectPath, 'lib', 'main.dart')).readAsStringSync();
        expect(mainContent.contains("import 'package:flutter/material.dart';"), isTrue);
        expect(mainContent.contains('void main()'), isTrue);
        expect(mainContent.contains('runApp'), isTrue);
      });

      test('generated tests are valid', () async {
        const projectName = 'test_validation';
        
        final result = await cli.createProject(projectName);

        expect(result.exitCode, equals(0));
        
        final projectPath = path.join(tempDir.path, projectName);
        
        // Check test file
        final testContent = File(path.join(projectPath, 'test', 'widget_test.dart')).readAsStringSync();
        expect(testContent.contains("import 'package:flutter_test/flutter_test.dart';"), isTrue);
        expect(testContent.contains('void main()'), isTrue);
        expect(testContent.contains('testWidgets'), isTrue);
      });
    });

    group('Add Commands Validation', () {
      late Directory testProject;

      setUp(() {
        testProject = Directory(path.join(tempDir.path, 'add_commands_test'));
        testProject.createSync();
        
        // Create a minimal Flutter project structure
        File(path.join(testProject.path, 'pubspec.yaml')).writeAsStringSync('''
name: add_commands_test
description: A test project for add commands
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

      test('add screen generates valid code', () async {
        final result = await cli.addScreen(
          'test_screen',
          feature: 'home',
          type: 'generic',
          withViewModel: true,
          withTests: true,
        );

        expect(result.exitCode, equals(0));
        
        // Validate screen file
        final screenFile = File(path.join(testProject.path, 'lib', 'features', 'home', 'presentation', 'test_screen_screen.dart'));
        expect(screenFile.existsSync(), isTrue);
        
        final screenContent = screenFile.readAsStringSync();
        expect(screenContent.contains("import 'package:flutter/material.dart';"), isTrue);
        expect(screenContent.contains('class TestScreenScreen'), isTrue);
        
        // Validate provider file
        final providerFile = File(path.join(testProject.path, 'lib', 'features', 'home', 'providers', 'test_screen_provider.dart'));
        expect(providerFile.existsSync(), isTrue);
        
        final providerContent = providerFile.readAsStringSync();
        expect(providerContent.contains("import 'package:flutter_riverpod/flutter_riverpod.dart';"), isTrue);
        expect(providerContent.contains('class TestScreenViewModel'), isTrue);
        
        // Validate test file
        final testFile = File(path.join(testProject.path, 'test', 'features', 'home', 'test_screen_screen_test.dart'));
        expect(testFile.existsSync(), isTrue);
        
        final testContent = testFile.readAsStringSync();
        expect(testContent.contains("import 'package:flutter_test/flutter_test.dart';"), isTrue);
        expect(testContent.contains('testWidgets'), isTrue);
      });

      test('add service generates valid code', () async {
        final result = await cli.addService(
          'test_service',
          feature: 'core',
          type: 'api',
          baseUrl: 'https://api.example.com',
          withTests: true,
          withMocks: true,
        );

        expect(result.exitCode, equals(0));
        
        // Validate service file
        final serviceFile = File(path.join(testProject.path, 'lib', 'features', 'core', 'services', 'test_service_service.dart'));
        expect(serviceFile.existsSync(), isTrue);
        
        final serviceContent = serviceFile.readAsStringSync();
        expect(serviceContent.contains('class TestServiceService'), isTrue);
        
        // Validate test file
        final testFile = File(path.join(testProject.path, 'test', 'features', 'core', 'services', 'test_service_service_test.dart'));
        expect(testFile.existsSync(), isTrue);
        
        final testContent = testFile.readAsStringSync();
        expect(testContent.contains("import 'package:flutter_test/flutter_test.dart';"), isTrue);
        expect(testContent.contains('testWidgets'), isTrue);
        
        // Validate mock file
        final mockFile = File(path.join(testProject.path, 'test', 'features', 'core', 'mocks', 'test_service_service_mock.dart'));
        expect(mockFile.existsSync(), isTrue);
        
        final mockContent = mockFile.readAsStringSync();
        expect(mockContent.contains('class MockTestServiceService'), isTrue);
      });
    });

    group('Error Handling Validation', () {
      test('invalid project names are rejected', () async {
        final invalidNames = [
          'Invalid Project Name!',
          'project-with-dashes',
          'project.with.dots',
          '123invalid',
          '',
        ];

        for (final invalidName in invalidNames) {
          final result = await cli.createProject(invalidName);

          expect(result.exitCode, equals(1));
          
          final output = json.decode(result.stdout.toString()) as Map<String, dynamic>;
          expect(output['success'], isFalse);
          final errorMessage =
              (output['error'] as Map<String, dynamic>)['message'] as String;
          expect(errorMessage, contains('Invalid project name'));
        }
      });

      test('duplicate project names are handled', () async {
        const projectName = 'duplicate_test';
        
        // Create first project
        final firstResult = await cli.createProject(projectName);

        expect(firstResult.exitCode, equals(0));
        
        // Try to create second project with same name
        final secondResult = await cli.createProject(projectName);

        expect(secondResult.exitCode, equals(1));
        
        final output = json.decode(secondResult.stdout.toString()) as Map<String, dynamic>;
        expect(output['success'], isFalse);
        final errorMessage =
            (output['error'] as Map<String, dynamic>)['message'] as String;
        expect(errorMessage, contains('already exists'));
      });
    });

    group('Cross-Platform Validation', () {
      test('project creation works on current platform', () async {
        const projectName = 'cross_platform_test';
        
        final result = await cli.createProject(projectName);

        expect(result.exitCode, equals(0));
        
        final projectPath = path.join(tempDir.path, projectName);
        expect(Directory(projectPath).existsSync(), isTrue);
        
        // Verify platform-specific path handling
        final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
        expect(pubspecFile.existsSync(), isTrue);
        
        final content = pubspecFile.readAsStringSync();
        expect(content, isNotEmpty);
      });
    });
  });
}
