import 'package:fly_cli/src/integrations/mcp/infrastructure/resources/resource_error.dart';
import 'package:test/test.dart';

void main() {
  group('ResourceError', () {
    test('should create invalidUri error', () {
      final error = ResourceError.invalidUri(
        resourceUri: 'invalid://path',
        expectedFormat: 'workspace://<relative-path>',
        hints: ['URI must start with workspace://'],
      );

      expect(error.code, 'invalid_uri');
      expect(error.category, 'validation');
      expect(error.severity, 'error');
      expect(error.resourceUri, 'invalid://path');
      expect(error.hints, isNotEmpty);
      expect(error.remediation, isNotNull);
    });

    test('should create pathTraversal error', () {
      final error = ResourceError.pathTraversal(
        path: '../../etc/passwd',
        workspaceRoot: '/workspace',
        resourceUri: 'workspace://../../etc/passwd',
      );

      expect(error.code, 'path_traversal');
      expect(error.category, 'security');
      expect(error.path, '../../etc/passwd');
      expect(error.hints, contains('Path contains invalid characters'));
    });

    test('should create notFound error with suggestions', () {
      final error = ResourceError.notFound(
        path: '/workspace/missing.dart',
        resourceUri: 'workspace://missing.dart',
        suggestions: ['/workspace/main.dart', '/workspace/lib.dart'],
      );

      expect(error.code, 'not_found');
      expect(error.category, 'not_found');
      expect(error.path, '/workspace/missing.dart');
      expect(error.context['suggestions'], isNotNull);
    });

    test('should create permissionDenied error', () {
      final error = ResourceError.permissionDenied(
        path: '/workspace/restricted.dart',
        operation: 'read',
        resourceUri: 'workspace://restricted.dart',
        reason: 'File access not allowed',
      );

      expect(error.code, 'permission_denied');
      expect(error.category, 'permission');
      expect(error.path, '/workspace/restricted.dart');
      expect(error.hints, contains('File access permissions'));
    });

    test('should create pathOutsideWorkspace error', () {
      final error = ResourceError.pathOutsideWorkspace(
        path: '/etc/passwd',
        workspaceRoot: '/workspace',
        resourceUri: 'workspace://etc/passwd',
      );

      expect(error.code, 'path_outside_workspace');
      expect(error.category, 'security');
      expect(error.path, '/etc/passwd');
      expect(error.hints, contains('All resource paths must be within'));
    });

    test('should create invalidManifestFile error', () {
      final error = ResourceError.invalidManifestFile(
        fileName: 'invalid.yaml',
        allowedFiles: ['fly_project.yaml', 'pubspec.yaml'],
      );

      expect(error.code, 'invalid_manifest_file');
      expect(error.category, 'validation');
      expect(error.resourceUri, 'manifest://invalid.yaml');
      expect(error.context['allowed_files'], isNotNull);
    });

    test('should create readError', () {
      final error = ResourceError.readError(
        path: '/workspace/file.dart',
        error: 'Permission denied',
        resourceUri: 'workspace://file.dart',
      );

      expect(error.code, 'read_error');
      expect(error.category, 'io');
      expect(error.path, '/workspace/file.dart');
      expect(error.hints, contains('File may be locked'));
    });

    test('should create invalidResourceType error', () {
      final error = ResourceError.invalidResourceType(
        resourceUri: 'workspace://directory',
        expectedType: 'file',
        actualType: 'directory',
      );

      expect(error.code, 'invalid_resource_type');
      expect(error.category, 'validation');
      expect(error.context['expected_type'], 'file');
      expect(error.context['actual_type'], 'directory');
    });

    test('should format error message with hints', () {
      final error = ResourceError.invalidUri(
        resourceUri: 'invalid://path',
        expectedFormat: 'workspace://<relative-path>',
      );

      final message = error.toString();
      expect(message, contains('Invalid resource URI'));
      expect(message, contains('Hints:'));
      expect(message, contains('Remediation:'));
    });
  });
}
