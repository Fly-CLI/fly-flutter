import 'dart:convert';
import 'dart:io';

import 'package:fly_cli/src/generation/application/ports/icache_manager.dart';
import 'package:fly_cli/src/generation/template/template_info.dart';
import 'package:fly_core/fly_core_dart.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

/// Implementation of ICacheManager for templates using file-based caching.
///
/// Stores TemplateInfo objects as JSON files in a cache directory.
class TemplateCacheImpl implements ICacheManager<TemplateInfo> {
  TemplateCacheImpl({
    Logger? logger,
    String? cacheDirectory,
  })  : _logger = logger ?? Logger(),
        _cacheDirectory = cacheDirectory ?? _getDefaultCacheDirectory();

  final Logger _logger;
  final String _cacheDirectory;

  /// Default cache duration (7 days)
  static const Duration _defaultCacheDuration = Duration(days: 7);

  /// Get default cache directory
  static String _getDefaultCacheDirectory() {
    return path.join(
      PlatformUtils.getDefaultCacheDirectory(),
      'template_info',
    );
  }

  /// Get cache file path for a key
  String _getCacheFilePath(String key) {
    // Sanitize key to be filesystem-safe
    final safeKey = key.replaceAll(RegExp(r'[^\w\-_.]'), '_');
    return path.join(_cacheDirectory, '$safeKey.json');
  }

  /// Ensure cache directory exists
  Future<void> _ensureCacheDirectory() async {
    final dir = Directory(_cacheDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  @override
  Future<TemplateInfo?> get(String key) async {
    try {
      await _ensureCacheDirectory();
      final cacheFile = File(_getCacheFilePath(key));

      if (!await cacheFile.exists()) {
        return null;
      }

      // Read and parse JSON
      final content = await cacheFile.readAsString();
      final data = json.decode(content) as Map<String, dynamic>;

      // Check expiration if TTL was set
      if (data.containsKey('expires_at')) {
        final expiresAt = DateTime.parse(data['expires_at'] as String);
        if (DateTime.now().isAfter(expiresAt)) {
          // Cache expired, remove file
          await cacheFile.delete();
          return null;
        }
      }

      // Deserialize TemplateInfo
      final templateData = data['template'] as Map<String, dynamic>;
      return TemplateInfo.fromJson(templateData);
    } catch (e) {
      _logger.warn('Failed to get template from cache: $e');
      return null;
    }
  }

  @override
  Future<void> set(String key, TemplateInfo value, {int? ttl}) async {
    try {
      await _ensureCacheDirectory();
      final cacheFile = File(_getCacheFilePath(key));

      // Calculate expiration time
      final expiresAt = ttl != null
          ? DateTime.now().add(Duration(seconds: ttl))
          : DateTime.now().add(_defaultCacheDuration);

      // Create cache data structure
      final cacheData = {
        'template': value.toJson(),
        'cached_at': DateTime.now().toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'key': key,
      };

      // Write to file atomically
      final tempFile = File('${cacheFile.path}.tmp');
      await tempFile.writeAsString(
        json.encode(cacheData),
        encoding: utf8,
      );
      await tempFile.rename(cacheFile.path);
    } catch (e) {
      _logger.warn('Failed to cache template: $e');
      rethrow;
    }
  }

  @override
  Future<bool> exists(String key) async {
    try {
      final cacheFile = File(_getCacheFilePath(key));
      if (!await cacheFile.exists()) {
        return false;
      }

      // Check if expired
      final template = await get(key);
      return template != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      final cacheFile = File(_getCacheFilePath(key));
      if (await cacheFile.exists()) {
        await cacheFile.delete();
      }
    } catch (e) {
      _logger.warn('Failed to remove template from cache: $e');
      rethrow;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _ensureCacheDirectory();
      final dir = Directory(_cacheDirectory);

      if (!await dir.exists()) {
        return;
      }

      // Delete all JSON files in cache directory
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          await entity.delete();
        }
      }
    } catch (e) {
      _logger.warn('Failed to clear template cache: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getKeys() async {
    try {
      await _ensureCacheDirectory();
      final dir = Directory(_cacheDirectory);

      if (!await dir.exists()) {
        return [];
      }

      final keys = <String>[];
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            // Read file to extract key
            final content = await entity.readAsString();
            final data = json.decode(content) as Map<String, dynamic>;
            if (data.containsKey('key')) {
              keys.add(data['key'] as String);
            } else {
              // Fallback: use filename without extension
              final filename = path.basenameWithoutExtension(entity.path);
              keys.add(filename);
            }
          } catch (_) {
            // Skip invalid cache files
          }
        }
      }

      return keys;
    } catch (e) {
      _logger.warn('Failed to get cache keys: $e');
      return [];
    }
  }
}

