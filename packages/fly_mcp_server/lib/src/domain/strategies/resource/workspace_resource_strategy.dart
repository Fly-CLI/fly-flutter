import 'dart:convert';
import 'dart:io';

import 'package:fly_mcp_server/src/domain/resource_strategy.dart';
import 'package:fly_mcp_server/src/path_sandbox.dart';

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
    if (uri == null || !uri.startsWith('workspace://')) {
      throw StateError('Invalid or missing uri');
    }
    final path = uri.replaceFirst('workspace://', '');
    
    // Resolve and validate path using sandbox
    final resolvedPath = _pathSandbox!.resolvePath(path);
    if (resolvedPath == null) {
      throw StateError('Path is outside workspace or invalid: $path');
    }
    
    // Check if read is allowed
    if (!_pathSandbox!.isAllowedRead(resolvedPath)) {
      throw StateError('File access not allowed: $path');
    }
    
    final file = File(resolvedPath);
    if (!file.existsSync()) {
      throw StateError('File not found: $resolvedPath');
    }
    final start = (params['start'] as int?) ?? 0;
    final length = (params['length'] as int?);

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
  }
}

