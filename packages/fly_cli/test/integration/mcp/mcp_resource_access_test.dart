import 'dart:io';

import 'package:fly_cli/src/integrations/mcp/resources/manifest_resource_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/resources/resource_error.dart';
import 'package:fly_cli/src/integrations/mcp/resources/workspace_resource_strategy.dart';
import 'package:fly_mcp/fly_mcp.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('MCP Resource Access Integration Tests', () {
    late Directory tempDir;
    late PathSandbox pathSandbox;
    late WorkspaceResourceStrategy workspaceStrategy;
    late ManifestResourceStrategy manifestStrategy;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fly_resource_test_');

      pathSandbox = PathSandbox(
        workspaceRoot: tempDir.path,
        securityConfig: null,
      );

      workspaceStrategy = WorkspaceResourceStrategy()
        ..setPathSandbox(pathSandbox);

      manifestStrategy = ManifestResourceStrategy()
        ..setPathSandbox(pathSandbox);

      // Create test files
      final testFile = File(path.join(tempDir.path, 'test.dart'));
      testFile.writeAsStringSync('void main() {}');

      final pubspecFile = File(path.join(tempDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync('name: test_project\nversion: 1.0.0');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('workspace resource strategy', () {
      test('should list workspace files', () {
        final result = workspaceStrategy.list({
          'directory': tempDir.path,
          'pageSize': 10,
          'page': 0,
        });

        expect(result['items'], isA<List>());
        expect(result['total'], greaterThan(0));
        expect(result['page'], 0);
        expect(result['pageSize'], 10);
      });

      test('should read workspace file', () {
        final result = workspaceStrategy.read({
          'uri': 'workspace://test.dart',
        });

        expect(result['content'], contains('void main()'));
        expect(result['encoding'], 'utf-8');
        expect(result['total'], greaterThan(0));
      });

      test('should throw ResourceError for path traversal attempt', () {
        expect(
          () => workspaceStrategy.read({
            'uri': 'workspace://../../etc/passwd',
          }),
          throwsA(isA<ResourceError>()),
        );

        try {
          workspaceStrategy.read({
            'uri': 'workspace://../../etc/passwd',
          });
        } catch (error) {
          expect(error, isA<ResourceError>());
          expect((error as ResourceError).code, 'path_traversal');
          expect(error.hints, isNotEmpty);
        }
      });

      test('should throw ResourceError for missing file', () {
        expect(
          () => workspaceStrategy.read({
            'uri': 'workspace://missing.dart',
          }),
          throwsA(isA<ResourceError>()),
        );

        try {
          workspaceStrategy.read({
            'uri': 'workspace://missing.dart',
          });
        } catch (error) {
          expect(error, isA<ResourceError>());
          expect((error as ResourceError).code, 'not_found');
          expect(error.hints, isNotEmpty);
        }
      });

      test('should throw ResourceError for invalid URI', () {
        expect(
          () => workspaceStrategy.read({
            'uri': 'invalid://path',
          }),
          throwsA(isA<ResourceError>()),
        );

        try {
          workspaceStrategy.read({
            'uri': 'invalid://path',
          });
        } catch (error) {
          expect(error, isA<ResourceError>());
          expect((error as ResourceError).code, 'invalid_uri');
        }
      });
    });

    group('manifest resource strategy', () {
      test('should list manifest files', () {
        final result = manifestStrategy.list({
          'pageSize': 10,
          'page': 0,
        });

        expect(result['items'], isA<List>());
        expect(result['total'], greaterThanOrEqualTo(0));
      });

      test('should read pubspec.yaml', () {
        final result = manifestStrategy.read({
          'uri': 'manifest://pubspec.yaml',
        });

        expect(result['content'], contains('test_project'));
        expect(result['encoding'], 'utf-8');
        expect(result['mimeType'], 'text/yaml');
      });

      test('should throw ResourceError for invalid manifest file', () {
        expect(
          () => manifestStrategy.read({
            'uri': 'manifest://invalid.yaml',
          }),
          throwsA(isA<ResourceError>()),
        );

        try {
          manifestStrategy.read({
            'uri': 'manifest://invalid.yaml',
          });
        } catch (error) {
          expect(error, isA<ResourceError>());
          expect((error as ResourceError).code, 'invalid_manifest_file');
          expect(error.hints, contains('Allowed files'));
        }
      });

      test('should throw ResourceError for missing manifest file', () {
        // Create a temp directory without pubspec.yaml
        final emptyDir = Directory.systemTemp.createTempSync('fly_empty_test_');
        final emptySandbox = PathSandbox(
          workspaceRoot: emptyDir.path,
          securityConfig: null,
        );

        final emptyStrategy = ManifestResourceStrategy()
          ..setPathSandbox(emptySandbox);

        expect(
          () => emptyStrategy.read({
            'uri': 'manifest://pubspec.yaml',
          }),
          throwsA(isA<ResourceError>()),
        );

        emptyDir.deleteSync(recursive: true);
      });
    });

    group('resource error handling', () {
      test('should provide helpful hints in error messages', () {
        try {
          workspaceStrategy.read({
            'uri': 'workspace://../outside.txt',
          });
          fail('Should have thrown error');
        } catch (error) {
          expect(error, isA<ResourceError>());
          final resourceError = error as ResourceError;
          expect(resourceError.hints, isNotEmpty);
          expect(resourceError.remediation, isNotNull);
          expect(resourceError.context, isNotEmpty);
        }
      });

      test('should suggest similar paths when file not found', () {
        // Create similar files
        File(path.join(tempDir.path, 'test_main.dart')).writeAsStringSync('');
        File(path.join(tempDir.path, 'test_file.dart')).writeAsStringSync('');

        try {
          workspaceStrategy.read({
            'uri': 'workspace://test.dart',
          });
          fail('Should have thrown error');
        } catch (error) {
          expect(error, isA<ResourceError>());
          // The error should include context with suggestions
          expect(error.toString(), contains('not found'));
        }
      });
    });
  });
}
