import 'dart:convert';
import 'dart:io';

import 'package:fly_mcp_server/src/domain/resource_strategy.dart';
import 'package:fly_mcp_server/src/path_sandbox.dart';
import 'package:path/path.dart' as path;

/// Strategy for dependencies:// resources
/// 
/// Provides access to dependency information:
/// - dependencies://all - All dependencies (direct + transitive)
/// - dependencies://direct - Direct dependencies only
/// - dependencies://transitive - Transitive dependencies only
/// - dependencies://{package} - Specific package information
class DependenciesResourceStrategy extends ResourceStrategy {
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
        'PathSandbox must be configured for DependenciesResourceStrategy',
      );
    }
  }

  @override
  String get uriPrefix => 'dependencies://';

  @override
  String get description => 'Project dependencies and dependency graph';

  @override
  bool get readOnly => true;

  @override
  Map<String, Object?> list(Map<String, Object?> params) {
    _ensurePathSandbox();
    final cwd = Directory.current;
    final pageSize = (params['pageSize'] as int?) ?? 100;
    final page = (params['page'] as int?) ?? 0;

    final pubspecFile = File(path.join(cwd.path, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      return {
        'items': <Map<String, Object?>>[],
        'total': 0,
        'page': page,
        'pageSize': pageSize,
      };
    }

    // Read and parse pubspec.yaml
    try {
      final content = pubspecFile.readAsStringSync();
      final dependencies = _extractDependencies(content);
      final devDependencies = _extractDevDependencies(content);

      final allDeps = <String>[...dependencies.keys, ...devDependencies.keys];
      allDeps.sort();

      // Create resource items for all dependency URIs
      final entries = <Map<String, Object?>>[
        {
          'uri': 'dependencies://all',
          'size': null, // Size varies based on content
        },
        {
          'uri': 'dependencies://direct',
          'size': null,
        },
      ];

      // Add individual package URIs
      for (final package in allDeps) {
        entries.add({
          'uri': 'dependencies://$package',
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
    } catch (e) {
      return {
        'items': <Map<String, Object?>>[],
        'total': 0,
        'page': page,
        'pageSize': pageSize,
      };
    }
  }

  @override
  Map<String, Object?> read(Map<String, Object?> params) {
    _ensurePathSandbox();
    final uri = params['uri'] as String?;
    if (uri == null || !uri.startsWith('dependencies://')) {
      throw StateError('Invalid or missing uri');
    }

    final cwd = Directory.current;
    final pubspecFile = File(path.join(cwd.path, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      throw StateError('pubspec.yaml not found');
    }

    // Validate path is within workspace
    final pubspecPath = pubspecFile.path;
    if (_pathSandbox!.resolvePath(pubspecPath) == null) {
      throw StateError('Path is outside workspace or invalid');
    }

    final content = pubspecFile.readAsStringSync();
    final dependencies = _extractDependencies(content);
    final devDependencies = _extractDevDependencies(content);

    // Extract the resource identifier from URI
    final resourceId = uri.replaceFirst('dependencies://', '');

    String jsonContent;
    Map<String, Object?> dependencyData;

    if (resourceId == 'all') {
      // Return all dependencies (direct + dev)
      dependencyData = {
        'direct': dependencies,
        'dev': devDependencies,
        'all': {...dependencies, ...devDependencies},
        'total': dependencies.length + devDependencies.length,
      };
      jsonContent = jsonEncode(dependencyData);
    } else if (resourceId == 'direct') {
      // Return only direct dependencies
      dependencyData = {
        'direct': dependencies,
        'total': dependencies.length,
      };
      jsonContent = jsonEncode(dependencyData);
    } else if (resourceId == 'transitive') {
      // Try to read transitive dependencies from pubspec.lock if available
      final lockFile = File(path.join(cwd.path, 'pubspec.lock'));
      Map<String, Object?> transitiveDeps = {};
      
      if (lockFile.existsSync()) {
        try {
          final lockContent = lockFile.readAsStringSync();
          transitiveDeps = _extractTransitiveFromLock(lockContent, dependencies);
        } catch (_) {
          // If parsing fails, return empty
        }
      }

      dependencyData = {
        'transitive': transitiveDeps,
        'total': transitiveDeps.length,
      };
      jsonContent = jsonEncode(dependencyData);
    } else {
      // Specific package information
      final packageName = resourceId;
      final version = dependencies[packageName] ?? devDependencies[packageName];
      
      if (version == null) {
        throw StateError('Package not found: $packageName');
      }

      dependencyData = {
        'package': packageName,
        'version': version,
        'type': dependencies.containsKey(packageName) ? 'direct' : 'dev',
      };
      jsonContent = jsonEncode(dependencyData);
    }

    return {
      'content': jsonContent,
      'encoding': 'utf-8',
      'mimeType': 'application/json',
      'total': jsonContent.length,
      'start': 0,
      'length': jsonContent.length,
    };
  }

  /// Extract dependencies from pubspec content
  Map<String, String> _extractDependencies(String content) {
    final dependencies = <String, String>{};
    final lines = content.split('\n');
    bool inDependencies = false;

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed == 'dependencies:') {
        inDependencies = true;
        continue;
      }

      if (inDependencies) {
        if (trimmed.isEmpty || trimmed.startsWith('dev_dependencies:')) {
          break;
        }

        if (trimmed.contains(':')) {
          final parts = trimmed.split(':');
          if (parts.length >= 2) {
            final package = parts[0].trim();
            final version = parts[1].trim();
            if (package.isNotEmpty && !package.startsWith('#')) {
              dependencies[package] = version;
            }
          }
        }
      }
    }

    return dependencies;
  }

  /// Extract dev dependencies from pubspec content
  Map<String, String> _extractDevDependencies(String content) {
    final devDependencies = <String, String>{};
    final lines = content.split('\n');
    bool inDevDependencies = false;

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed == 'dev_dependencies:') {
        inDevDependencies = true;
        continue;
      }

      if (inDevDependencies) {
        if (trimmed.isEmpty) {
          break;
        }

        if (trimmed.contains(':')) {
          final parts = trimmed.split(':');
          if (parts.length >= 2) {
            final package = parts[0].trim();
            final version = parts[1].trim();
            if (package.isNotEmpty && !package.startsWith('#')) {
              devDependencies[package] = version;
            }
          }
        }
      }
    }

    return devDependencies;
  }

  /// Extract transitive dependencies from pubspec.lock
  /// 
  /// This is a simplified parser that extracts transitive dependencies
  /// not directly listed in pubspec.yaml
  Map<String, Object?> _extractTransitiveFromLock(
    String lockContent,
    Map<String, String> directDeps,
  ) {
    final transitive = <String, Object?>{};
    
    // Simple pattern matching to find packages in pubspec.lock
    // This is a basic implementation - a full parser would use yaml parsing
    final packagePattern = RegExp(r'^\s+(\w[\w-]*):', multiLine: true);
    final matches = packagePattern.allMatches(lockContent);
    
    for (final match in matches) {
      final packageName = match.group(1);
      if (packageName != null && !directDeps.containsKey(packageName)) {
        // This is likely a transitive dependency
        if (!transitive.containsKey(packageName)) {
          transitive[packageName] = {
            'transitive': true,
          };
        }
      }
    }

    return transitive;
  }
}

