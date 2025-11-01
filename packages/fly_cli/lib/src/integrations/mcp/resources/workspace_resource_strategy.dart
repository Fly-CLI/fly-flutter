import 'dart:convert';
import 'dart:io';

import 'package:fly_cli/src/integrations/mcp/resources/resource_error.dart';
import 'package:fly_mcp/fly_mcp.dart';

/// Strategy for workspace:// resources
class WorkspaceResourceStrategy extends ResourceStrategy {
  /// Path sandbox for security (required)
  PathSandbox? _pathSandbox;

  /// Set the path sandbox for this strategy
  void setPathSandbox(PathSandbox sandbox) {
    _pathSandbox = sandbox;
  }

  /// Ensure path sandbox is configured
  void _ensurePathSandbox() {
    if (_pathSandbox == null) {
      throw StateError(
        'PathSandbox must be configured for WorkspaceResourceStrategy',
      );
    }
  }

  @override
  String get uriPrefix => 'workspace://';

  @override
  String get description => 'Workspace files and directories';

  @override
  bool get readOnly => true;

  @override
  Map<String, Object?> list(Map<String, Object?> params) {
    _ensurePathSandbox();
    final cwd = Directory.current;
    final dir = params['directory'] as String? ?? cwd.path;
    final pageSize = (params['pageSize'] as int?) ?? 100;
    final page = (params['page'] as int?) ?? 0;
    final entries = <Map<String, Object?>>[];

    // Resolve and validate directory path using sandbox
    final resolvedDir = _pathSandbox!.resolvePath(dir);
    if (resolvedDir == null) {
      // Directory is outside workspace or invalid
      return {
        'items': <Map<String, Object?>>[],
        'total': 0,
        'page': page,
        'pageSize': pageSize,
      };
    }

    final all = Directory(resolvedDir).listSync(
      recursive: true,
      followLinks: false,
    );
    for (final entity in all) {
      if (entity is File) {
        final filePath = entity.path;

        // Check if file access is allowed using PathSandbox
        if (_pathSandbox!.isAllowedRead(filePath)) {
          entries.add({
            'uri': 'workspace://$filePath',
            'size': entity.lengthSync(),
          });
        }
      }
    }
    entries.sort(
      (a, b) => (a['uri'] as String).compareTo(b['uri'] as String),
    );
    final start = page * pageSize;
    final end = (start + pageSize) > entries.length
        ? entries.length
        : (start + pageSize);
    final slice = (start < entries.length)
        ? entries.sublist(start, end)
        : <Map<String, Object?>>[];
    return {
      'items': slice,
      'total': entries.length,
      'page': page,
      'pageSize': pageSize,
    };
  }

  @override
  Map<String, Object?> read(Map<String, Object?> params) {
    _ensurePathSandbox();
    final uri = params['uri'] as String?;

    // Validate URI format
    if (uri == null || uri.isEmpty) {
      throw ResourceError.invalidUri(
        resourceUri: uri ?? '',
        expectedFormat: 'workspace://<relative-path>',
        hints: [
          'URI cannot be null or empty',
          'Workspace URIs must start with workspace://',
        ],
      );
    }

    if (!uri.startsWith('workspace://')) {
      throw ResourceError.invalidUri(
        resourceUri: uri,
        expectedFormat: 'workspace://<relative-path>',
        hints: [
          'Workspace URIs must start with workspace://',
          'Example: workspace://lib/main.dart',
        ],
      );
    }

    final path = uri.replaceFirst('workspace://', '');

    // Validate path for traversal attempts
    if (_isPathTraversal(path)) {
      throw ResourceError.pathTraversal(
        path: path,
        workspaceRoot: _pathSandbox!.workspaceRoot,
        resourceUri: uri,
      );
    }

    // Resolve and validate path using sandbox
    final resolvedPath = _pathSandbox!.resolvePath(path);
    if (resolvedPath == null) {
      throw ResourceError.pathOutsideWorkspace(
        path: path,
        workspaceRoot: _pathSandbox!.workspaceRoot,
        resourceUri: uri,
      );
    }

    // Check if read is allowed
    if (!_pathSandbox!.isAllowedRead(resolvedPath)) {
      throw ResourceError.permissionDenied(
        path: resolvedPath,
        operation: 'read',
        resourceUri: uri,
        reason: 'File access not allowed by PathSandbox security policy',
      );
    }

    final file = File(resolvedPath);
    if (!file.existsSync()) {
      // Check if it's a directory
      final directory = Directory(resolvedPath);
      if (directory.existsSync()) {
        throw ResourceError.invalidResourceType(
          resourceUri: uri,
          expectedType: 'file',
          actualType: 'directory',
        );
      }

      // Provide suggestions for similar paths
      final suggestions = _suggestSimilarPaths(resolvedPath);
      throw ResourceError.notFound(
        path: resolvedPath,
        resourceUri: uri,
        suggestions: suggestions,
      );
    }

    // Check if it's actually a directory
    if (file.statSync().type == FileSystemEntityType.directory) {
      throw ResourceError.invalidResourceType(
        resourceUri: uri,
        expectedType: 'file',
        actualType: 'directory',
      );
    }

    final start = (params['start'] as int?) ?? 0;
    final length = (params['length'] as int?);

    try {
      final raf = file.openSync(mode: FileMode.read);
      try {
        final fileSize = raf.lengthSync();
        final clampedStart = start.clamp(0, fileSize);
        raf.setPositionSync(clampedStart);
        final bytes = raf.readSync(
          length == null ? fileSize - clampedStart : length,
        );
        final content = utf8.decode(bytes, allowMalformed: true);
        return {
          'content': content,
          'encoding': 'utf-8',
          'total': fileSize,
          'start': clampedStart,
          'length': bytes.length,
        };
      } finally {
        raf.closeSync();
      }
    } catch (e) {
      throw ResourceError.readError(
        path: resolvedPath,
        error: e,
        resourceUri: uri,
      );
    }
  }

  /// Check if path contains traversal sequences
  bool _isPathTraversal(String path) {
    // Check for common path traversal patterns
    if (path.contains('..') ||
        path.contains('~/') ||
        path.startsWith('/') ||
        path.contains('\\')) {
      return true;
    }
    return false;
  }

  /// Suggest similar paths when file not found
  List<String> _suggestSimilarPaths(String notFoundPath) {
    final suggestions = <String>[];
    try {
      final parent = Directory(notFoundPath).parent;
      if (parent.existsSync()) {
        final entries = parent.listSync();
        final fileName = notFoundPath.split(Platform.pathSeparator).last;

        // Find files with similar names
        for (final entry in entries) {
          if (entry is File) {
            final entryName = entry.path.split(Platform.pathSeparator).last;
            if (entryName.toLowerCase().contains(fileName.toLowerCase()) ||
                fileName.toLowerCase().contains(entryName.toLowerCase())) {
              suggestions.add(entry.path);
            }
          }
        }
      }
    } catch (_) {
      // Ignore errors when generating suggestions
    }
    return suggestions.take(5).toList();
  }
}
