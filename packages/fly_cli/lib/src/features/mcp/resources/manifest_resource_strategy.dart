import 'dart:convert';
import 'dart:io';

import 'package:fly_mcp_server/src/domain/resource_strategy.dart';
import 'package:fly_mcp_server/src/path_sandbox.dart';

/// Strategy for manifest:// resources
/// 
/// Provides access to project manifest and configuration files:
/// - manifest://fly_project.yaml - Project manifest
/// - manifest://pubspec.yaml - Pubspec file
/// - manifest://analysis_options.yaml - Analysis options
class ManifestResourceStrategy extends ResourceStrategy {
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
        'PathSandbox must be configured for ManifestResourceStrategy',
      );
    }
  }

  @override
  String get uriPrefix => 'manifest://';

  @override
  String get description => 'Project manifest and configuration files';

  @override
  bool get readOnly => true;

  /// Allowed manifest file names
  static const List<String> _allowedFiles = [
    'fly_project.yaml',
    'pubspec.yaml',
    'analysis_options.yaml',
  ];

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

    final directory = Directory(resolvedDir);
    if (!directory.existsSync()) {
      return {
        'items': <Map<String, Object?>>[],
        'total': 0,
        'page': page,
        'pageSize': pageSize,
      };
    }

    // Check for allowed manifest files in the directory
    for (final fileName in _allowedFiles) {
      final file = File('${directory.path}/$fileName');
      if (file.existsSync()) {
        final filePath = file.path;
        
        // Check if file access is allowed using PathSandbox
        if (_pathSandbox!.isAllowedRead(filePath)) {
          entries.add({
            'uri': 'manifest://$fileName',
            'size': file.lengthSync(),
          });
        }
      }
    }

    // Sort entries by URI
    entries.sort(
      (a, b) => (a['uri'] as String).compareTo(b['uri'] as String),
    );

    // Apply pagination
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
    if (uri == null || !uri.startsWith('manifest://')) {
      throw StateError('Invalid or missing uri');
    }

    // Extract file name from URI (e.g., manifest://fly_project.yaml -> fly_project.yaml)
    final fileName = uri.replaceFirst('manifest://', '');
    
    // Validate that the file is in the allowed list
    if (!_allowedFiles.contains(fileName)) {
      throw StateError('Invalid manifest file: $fileName');
    }

    final cwd = Directory.current;
    final filePath = '${cwd.path}/$fileName';
    
    // Resolve and validate path using sandbox
    final resolvedPath = _pathSandbox!.resolvePath(filePath);
    if (resolvedPath == null) {
      throw StateError('Path is outside workspace or invalid: $filePath');
    }
    
    // Check if read is allowed
    if (!_pathSandbox!.isAllowedRead(resolvedPath)) {
      throw StateError('File access not allowed: $filePath');
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
      
      // Determine MIME type based on file extension
      String mimeType = 'text/plain';
      if (fileName.endsWith('.yaml') || fileName.endsWith('.yml')) {
        mimeType = 'text/yaml';
      }

      return {
        'content': content,
        'encoding': 'utf-8',
        'mimeType': mimeType,
        'total': fileSize,
        'start': clampedStart,
        'length': bytes.length,
      };
    } finally {
      raf.closeSync();
    }
  }
}

