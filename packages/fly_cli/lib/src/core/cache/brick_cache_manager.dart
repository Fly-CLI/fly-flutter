import 'dart:convert';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

import 'package:fly_cli/src/core/templates/brick_registry.dart';
import 'package:fly_cli/src/core/templates/models/brick_info.dart';

/// Cache metadata for brick information
class BrickCacheInfo {
  const BrickCacheInfo({
    required this.cachedAt,
    required this.version,
    required this.checksum,
    required this.brickCount,
  });

  factory BrickCacheInfo.fromJson(Map<String, dynamic> json) => BrickCacheInfo(
        cachedAt: DateTime.parse(json['cached_at'] as String),
        version: json['version'] as String,
        checksum: json['checksum'] as String,
        brickCount: json['brick_count'] as int,
      );

  final DateTime cachedAt;
  final String version;
  final String checksum;
  final int brickCount;

  Map<String, dynamic> toJson() => {
        'cached_at': cachedAt.toIso8601String(),
        'version': version,
        'checksum': checksum,
        'brick_count': brickCount,
      };
}

/// Generation plan for dry-run functionality
class GenerationPlan {
  const GenerationPlan({
    required this.brickName,
    required this.brickType,
    required this.targetDirectory,
    required this.variables,
    required this.filesToGenerate,
    required this.estimatedDuration,
  });

  factory GenerationPlan.fromJson(Map<String, dynamic> json) => GenerationPlan(
        brickName: json['brick_name'] as String,
        brickType: BrickType.values.firstWhere(
          (e) => e.name == json['brick_type'],
          orElse: () => BrickType.custom,
        ),
        targetDirectory: json['target_directory'] as String,
        variables: Map<String, dynamic>.from(json['variables'] as Map),
        filesToGenerate:
            (json['files_to_generate'] as List<dynamic>).cast<String>(),
        estimatedDuration:
            Duration(milliseconds: json['estimated_duration_ms'] as int),
      );

  final String brickName;
  final BrickType brickType;
  final String targetDirectory;
  final Map<String, dynamic> variables;
  final List<String> filesToGenerate;
  final Duration estimatedDuration;

  Map<String, dynamic> toJson() => {
        'brick_name': brickName,
        'brick_type': brickType.name,
        'target_directory': targetDirectory,
        'variables': variables,
        'files_to_generate': filesToGenerate,
        'estimated_duration_ms': estimatedDuration.inMilliseconds,
      };
}

/// Specialized cache manager for Mason bricks
class BrickCacheManager {
  BrickCacheManager({
    required this.logger,
    String? cacheDirectory,
  }) : _cacheDirectory = cacheDirectory ?? _getDefaultCacheDirectory();

  final Logger logger;
  final String _cacheDirectory;

  /// Cache duration for brick metadata
  static const Duration cacheDuration = Duration(days: 7);

  /// Get default cache directory
  static String _getDefaultCacheDirectory() {
    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    return path.join(homeDir, '.fly', 'cache', 'bricks');
  }

  /// Cache brick registry snapshot
  Future<void> cacheBrickRegistry(List<BrickInfo> bricks) async {
    try {
      final cacheFile = File(path.join(_cacheDirectory, 'registry.json'));
      await cacheFile.parent.create(recursive: true);

      final cacheData = {
        'bricks': bricks.map((brick) => brick.toJson()).toList(),
        'cached_at': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'checksum': await _calculateChecksum(bricks),
        'brick_count': bricks.length,
      };

      await cacheFile.writeAsString(json.encode(cacheData));
      logger.detail('Cached brick registry with ${bricks.length} bricks');
    } catch (e) {
      logger.warn('Failed to cache brick registry: $e');
    }
  }

  /// Load brick registry from cache
  Future<List<BrickInfo>?> loadBrickRegistry() async {
    try {
      final cacheFile = File(path.join(_cacheDirectory, 'registry.json'));
      if (!await cacheFile.exists()) {
        return null;
      }

      final content = await cacheFile.readAsString();
      final data = json.decode(content) as Map<String, dynamic>;

      // Check cache validity
      final cachedAt = DateTime.parse(data['cached_at'] as String);
      final age = DateTime.now().difference(cachedAt);

      if (age > cacheDuration) {
        logger.detail('Brick registry cache expired');
        return null;
      }

      final bricksJson = data['bricks'] as List<dynamic>;
      final bricks = bricksJson
          .map((json) => BrickInfo.fromJson(json as Map<String, dynamic>))
          .toList();

      logger.detail(
          'Loaded brick registry from cache with ${bricks.length} bricks');
      return bricks;
    } catch (e) {
      logger.warn('Failed to load brick registry from cache: $e');
      return null;
    }
  }

  /// Cache generation plan
  Future<void> cacheGenerationPlan(GenerationPlan plan) async {
    try {
      final cacheFile = File(path.join(_cacheDirectory, 'plans',
          '${plan.brickName}_${plan.brickType.name}.json'));
      await cacheFile.parent.create(recursive: true);

      await cacheFile.writeAsString(json.encode(plan.toJson()));
      logger.detail('Cached generation plan for ${plan.brickName}');
    } catch (e) {
      logger.warn('Failed to cache generation plan: $e');
    }
  }

  /// Load generation plan from cache
  Future<GenerationPlan?> loadGenerationPlan(
      String brickName, BrickType brickType) async {
    try {
      final cacheFile = File(path.join(
          _cacheDirectory, 'plans', '${brickName}_${brickType.name}.json'));
      if (!await cacheFile.exists()) {
        return null;
      }

      final content = await cacheFile.readAsString();
      final data = json.decode(content) as Map<String, dynamic>;

      return GenerationPlan.fromJson(data);
    } catch (e) {
      logger.warn('Failed to load generation plan from cache: $e');
      return null;
    }
  }

  /// Cache brick validation result
  Future<void> cacheValidationResult(
      String brickName, BrickValidationResult result) async {
    try {
      final cacheFile =
          File(path.join(_cacheDirectory, 'validations', '$brickName.json'));
      await cacheFile.parent.create(recursive: true);

      final cacheData = {
        'is_valid': result.isValid,
        'errors': result.errors,
        'warnings': result.warnings,
        'cached_at': DateTime.now().toIso8601String(),
      };

      await cacheFile.writeAsString(json.encode(cacheData));
      logger.detail('Cached validation result for $brickName');
    } catch (e) {
      logger.warn('Failed to cache validation result: $e');
    }
  }

  /// Load brick validation result from cache
  Future<BrickValidationResult?> loadValidationResult(String brickName) async {
    try {
      final cacheFile =
          File(path.join(_cacheDirectory, 'validations', '$brickName.json'));
      if (!await cacheFile.exists()) {
        return null;
      }

      final content = await cacheFile.readAsString();
      final data = json.decode(content) as Map<String, dynamic>;

      // Check cache validity (validation results expire after 1 day)
      final cachedAt = DateTime.parse(data['cached_at'] as String);
      final age = DateTime.now().difference(cachedAt);

      if (age > const Duration(days: 1)) {
        return null;
      }

      return BrickValidationResult(
        isValid: data['is_valid'] as bool,
        errors: (data['errors'] as List<dynamic>).cast<String>(),
        warnings: (data['warnings'] as List<dynamic>).cast<String>(),
      );
    } catch (e) {
      logger.warn('Failed to load validation result from cache: $e');
      return null;
    }
  }

  /// Check if cache is valid
  Future<bool> isCacheValid() async {
    try {
      final cacheFile = File(path.join(_cacheDirectory, 'registry.json'));
      if (!await cacheFile.exists()) {
        return false;
      }

      final content = await cacheFile.readAsString();
      final data = json.decode(content) as Map<String, dynamic>;

      final cachedAt = DateTime.parse(data['cached_at'] as String);
      final age = DateTime.now().difference(cachedAt);

      return age <= cacheDuration;
    } catch (e) {
      return false;
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      final cacheDir = Directory(_cacheDirectory);
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        logger.info('Cleared brick cache');
      }
    } catch (e) {
      logger.warn('Failed to clear cache: $e');
    }
  }

  /// Clear specific cache type
  Future<void> clearCacheType(String type) async {
    try {
      final typeDir = Directory(path.join(_cacheDirectory, type));
      if (await typeDir.exists()) {
        await typeDir.delete(recursive: true);
        logger.info('Cleared $type cache');
      }
    } catch (e) {
      logger.warn('Failed to clear $type cache: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final cacheDir = Directory(_cacheDirectory);
      if (!await cacheDir.exists()) {
        return {
          'exists': false,
          'total_size_bytes': 0,
          'file_count': 0,
          'directories': <String, int>{},
        };
      }

      var totalSize = 0;
      var fileCount = 0;
      final directories = <String, int>{};

      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
          fileCount++;

          final relativePath =
              path.relative(entity.path, from: _cacheDirectory);
          final dir = path.dirname(relativePath);
          directories[dir] = (directories[dir] ?? 0) + 1;
        }
      }

      return {
        'exists': true,
        'total_size_bytes': totalSize,
        'file_count': fileCount,
        'directories': directories,
        'cache_directory': _cacheDirectory,
      };
    } catch (e) {
      logger.warn('Failed to get cache stats: $e');
      return {
        'exists': false,
        'error': e.toString(),
      };
    }
  }

  /// Calculate checksum for brick list
  Future<String> _calculateChecksum(List<BrickInfo> bricks) async {
    final names = bricks.map((b) => b.name).toList()..sort();
    final versions = bricks.map((b) => b.version).toList()..sort();
    return '${names.join(',')}-${versions.join(',')}';
  }

  /// Get cache directory path
  String get cacheDirectory => _cacheDirectory;
}
