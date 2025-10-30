import 'dart:convert';
import 'dart:io';

import 'package:fly_mcp_server/src/domain/resource_strategy.dart';
import 'package:fly_mcp_server/src/path_sandbox.dart';
import 'package:path/path.dart' as path;

/// Strategy for tests:// resources
/// 
/// Provides access to test results and coverage data:
/// - tests://results - Latest test results (JSON)
/// - tests://coverage - Coverage report (LCOV format)
/// - tests://history - Test execution history
class TestsResourceStrategy extends ResourceStrategy {
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
        'PathSandbox must be configured for TestsResourceStrategy',
      );
    }
  }

  @override
  String get uriPrefix => 'tests://';

  @override
  String get description => 'Test results and coverage data';

  @override
  bool get readOnly => true;

  /// In-memory cache for test history (optional)
  final Map<String, Map<String, Object?>> _testHistory = {};

  @override
  Map<String, Object?> list(Map<String, Object?> params) {
    _ensurePathSandbox();
    final cwd = Directory.current;
    final pageSize = (params['pageSize'] as int?) ?? 100;
    final page = (params['page'] as int?) ?? 0;

    final entries = <Map<String, Object?>>[];

    // Check for available test resources
    final coverageFile = File(path.join(cwd.path, 'coverage', 'lcov.info'));
    if (coverageFile.existsSync() &&
        _pathSandbox!.isAllowedRead(coverageFile.path)) {
      entries.add({
        'uri': 'tests://coverage',
        'size': coverageFile.lengthSync(),
      });
    }

    // Add test results if available
    entries.add({
      'uri': 'tests://results',
      'size': null, // Size varies based on content
    });

    // Add test history if available
    if (_testHistory.isNotEmpty) {
      entries.add({
        'uri': 'tests://history',
        'size': null,
      });
    }

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
    if (uri == null || !uri.startsWith('tests://')) {
      throw StateError('Invalid or missing uri');
    }

    final cwd = Directory.current;
    final resourceId = uri.replaceFirst('tests://', '');

    String content;
    String mimeType;
    int contentLength;

    if (resourceId == 'coverage') {
      // Read coverage file
      final coverageFile = File(path.join(cwd.path, 'coverage', 'lcov.info'));
      
      // Validate path is within workspace
      if (_pathSandbox!.resolvePath(coverageFile.path) == null) {
        throw StateError('Path is outside workspace or invalid');
      }

      if (!coverageFile.existsSync()) {
        throw StateError('Coverage file not found. Run tests with --coverage first.');
      }

      // Check if read is allowed
      if (!_pathSandbox!.isAllowedRead(coverageFile.path)) {
        throw StateError('File access not allowed');
      }

      content = coverageFile.readAsStringSync();
      mimeType = 'text/plain'; // LCOV format
      contentLength = content.length;
    } else if (resourceId == 'results') {
      // Return test results summary
      // This would ideally parse actual test output, but for now
      // we'll return a summary structure
      final resultsData = {
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'unknown', // Would be determined from actual test runs
        'summary': {
          'total': 0,
          'passed': 0,
          'failed': 0,
          'skipped': 0,
        },
        'note': 'Test results require running tests first',
      };

      content = jsonEncode(resultsData);
      mimeType = 'application/json';
      contentLength = content.length;
    } else if (resourceId == 'history') {
      // Return test history
      final historyData = {
        'runs': _testHistory.values.toList(),
        'total': _testHistory.length,
      };

      content = jsonEncode(historyData);
      mimeType = 'application/json';
      contentLength = content.length;
    } else {
      throw StateError('Invalid test resource: $resourceId');
    }

    final start = (params['start'] as int?) ?? 0;
    final length = (params['length'] as int?);

    // Apply byte-range reading if requested
    if (length != null && length > 0) {
      final clampedStart = start.clamp(0, contentLength);
      final clampedEnd = (clampedStart + length).clamp(0, contentLength);
      content = content.substring(clampedStart, clampedEnd);
      
      return {
        'content': content,
        'encoding': 'utf-8',
        'mimeType': mimeType,
        'total': contentLength,
        'start': clampedStart,
        'length': content.length,
      };
    } else if (start > 0) {
      // Only start offset specified
      final clampedStart = start.clamp(0, contentLength);
      content = content.substring(clampedStart);
      
      return {
        'content': content,
        'encoding': 'utf-8',
        'mimeType': mimeType,
        'total': contentLength,
        'start': clampedStart,
        'length': content.length,
      };
    }

    return {
      'content': content,
      'encoding': 'utf-8',
      'mimeType': mimeType,
      'total': contentLength,
      'start': 0,
      'length': contentLength,
    };
  }

  /// Store test run in history (for future enhancement)
  /// 
  /// This method can be called by test execution tools to store
  /// test results for historical access.
  void storeTestRun(String runId, Map<String, Object?> results) {
    _testHistory[runId] = {
      'id': runId,
      'timestamp': DateTime.now().toIso8601String(),
      ...results,
    };
  }
}

