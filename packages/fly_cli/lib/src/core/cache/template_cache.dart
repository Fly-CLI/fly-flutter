import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

import '../utils/platform_utils.dart';
import 'cache_models.dart';

/// Manages template caching with expiration, validation, and size management
class TemplateCacheManager {
  TemplateCacheManager({
    Logger? logger,
    String? cacheDirectory,
    int? expirationDays,
    Duration? cacheDuration,
    int? maxSizeBytes,
  })  : _logger = logger ?? Logger(),
        _cacheDirectory = cacheDirectory ?? PlatformUtils.getDefaultCacheDirectory(),
        _expirationDays = expirationDays ?? (cacheDuration?.inDays ?? 7),
        _maxSizeBytes = maxSizeBytes ?? 100 * 1024 * 1024; // 100MB

  final Logger _logger;
  final String _cacheDirectory;
  final int _expirationDays;
  final int _maxSizeBytes;

  /// Get the cache directory path
  String get cacheDirectory => _cacheDirectory;

  static const String _cacheVersion = '1.0.0';
  static const String _metadataFileName = 'cache_metadata.json';
  static const String _entriesFileName = 'cache_entries.json';

  bool _initialized = false;
  CacheMetadata? _metadata;
  final Map<String, CacheEntry> _entries = {};

  /// Initialize the cache manager
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Create cache directory if it doesn't exist
      final cacheDir = Directory(_cacheDirectory);
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
        _logger.info('Created cache directory: $_cacheDirectory');
      }

      // Load existing metadata and entries
      await _loadMetadata();
      await _loadEntries();

      // Clean up expired entries (but don't call _ensureInitialized since we're initializing)
      await _cleanupExpiredEntries();

      _initialized = true;
      _logger.info('Template cache initialized: ${_entries.length} entries');
    } catch (e) {
      _logger.err('Failed to initialize template cache: $e');
      rethrow;
    }
  }

  /// Cache a template with metadata
  Future<void> cacheTemplate(String name, Map<String, dynamic> templateData) async {
    await _ensureInitialized();

    try {
      // Use template data directly
      final data = templateData;
      
      // Generate checksum for validation
      final jsonString = json.encode(data);
      final checksum = sha256.convert(utf8.encode(jsonString)).toString();

      // Create cached template
      final cachedTemplate = CachedTemplate(
        name: name,
        version: data['version'] as String? ?? '1.0.0',
        cachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: _expirationDays)),
        checksum: checksum,
        templateData: data,
      );

      // Create cache entry
      final entry = CacheEntry(
        key: name,
        template: cachedTemplate,
        lastAccessed: DateTime.now(),
        accessCount: 0,
      );

      // Store in memory
      _entries[name] = entry;

      // Persist to disk
      await _saveEntry(entry);
      await _updateMetadata();

      _logger.info('Cached template: $name (expires in $_expirationDays days)');
    } catch (e) {
      _logger.err('Failed to cache template $name: $e');
      rethrow;
    }
  }

  /// Retrieve a cached template
  Future<CacheResult> getTemplate(String name) async {
    await _ensureInitialized();

    try {
      final entry = _entries[name];
      if (entry == null) {
        // Check if there's a corrupted file on disk
        final entryFile = File(path.join(_cacheDirectory, '$name.json'));
        if (await entryFile.exists()) {
          try {
            final content = await entryFile.readAsString();
            jsonDecode(content); // Try to parse
            // If we get here, the file is valid JSON but not in _entries
            // This shouldn't happen, but return CacheMiss
            return const CacheMiss();
          } catch (e) {
            // File exists but contains invalid JSON
            _logger.warn('Found corrupted cache file for $name: $e');
            return CacheCorrupted(error: 'Invalid JSON in cache file: $e');
          }
        }
        return const CacheMiss();
      }

      // Check if expired
      if (entry.template.isExpired) {
        _logger.info('Template $name is expired, removing from cache');
        await invalidate(name);
        return CacheExpired(template: entry.template);
      }

      // Validate checksum
      if (!await _validateChecksum(entry.template)) {
        _logger.warn('Template $name checksum validation failed, removing from cache');
        await invalidate(name);
        return const CacheCorrupted(error: 'Checksum validation failed');
      }

      // Update access tracking
      final updatedEntry = entry.markAccessed();
      _entries[name] = updatedEntry;
      await _saveEntry(updatedEntry);

      return CacheSuccess(template: entry.template);
    } catch (e) {
      _logger.err('Failed to retrieve template $name: $e');
      return CacheError(message: e.toString());
    }
  }

  /// Check if a template is valid in cache
  Future<bool> isValid(String name) async {
    final result = await getTemplate(name);
    return result is CacheSuccess;
  }

  /// Invalidate a cached template
  Future<void> invalidate(String name) async {
    await _ensureInitialized();

    try {
      // Remove from memory
      _entries.remove(name);

      // Remove from disk
      final entryFile = File(path.join(_cacheDirectory, '$name.json'));
      if (await entryFile.exists()) {
        await entryFile.delete();
      }

      await _updateMetadata();
      _logger.info('Invalidated cached template: $name');
    } catch (e) {
      _logger.err('Failed to invalidate template $name: $e');
      rethrow;
    }
  }

  /// Clear all cached templates
  Future<void> clear() async {
    await _ensureInitialized();

    try {
      // Clear memory
      _entries.clear();

      // Clear disk
      final cacheDir = Directory(_cacheDirectory);
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list()) {
          if (entity is File && entity.path.endsWith('.json')) {
            await entity.delete();
          }
        }
      }

      // Reset metadata
      _metadata = CacheMetadata(
        cacheVersion: _cacheVersion,
        totalEntries: 0,
        totalSizeBytes: 0,
        lastCleanup: DateTime.now(),
      );

      await _saveMetadata();
      _logger.info('Cleared all cached templates');
    } catch (e) {
      _logger.err('Failed to clear cache: $e');
      rethrow;
    }
  }

  /// Get cache metadata
  Future<CacheMetadata> getMetadata() async {
    await _ensureInitialized();
    return _metadata!;
  }

  /// Clean up expired entries without requiring initialization
  Future<void> _cleanupExpiredEntries() async {
    try {
      final now = DateTime.now();
      final expiredKeys = <String>[];

      // Find expired entries
      for (final entry in _entries.values) {
        if (entry.template.isExpired) {
          expiredKeys.add(entry.key);
        }
      }

      // Remove expired entries
      for (final key in expiredKeys) {
        _entries.remove(key);
        // Remove from disk
        final entryFile = File(path.join(_cacheDirectory, '$key.json'));
        if (await entryFile.exists()) {
          await entryFile.delete();
        }
      }

      // Update cleanup timestamp
      if (_metadata != null) {
        _metadata = _metadata!.copyWith(lastCleanup: now);
      }

      if (expiredKeys.isNotEmpty) {
        _logger.info('Cleaned up ${expiredKeys.length} expired templates during initialization');
      }
    } catch (e) {
      _logger.warn('Failed to cleanup expired entries during initialization: $e');
      // Don't rethrow during initialization
    }
  }

  /// Clean up expired entries
  Future<void> cleanup() async {
    await _ensureInitialized();

    try {
      final now = DateTime.now();
      final expiredKeys = <String>[];

      // Find expired entries
      for (final entry in _entries.values) {
        if (entry.template.isExpired) {
          expiredKeys.add(entry.key);
        }
      }

      // Remove expired entries
      for (final key in expiredKeys) {
        await invalidate(key);
      }

      // Update cleanup timestamp
      _metadata = _metadata!.copyWith(lastCleanup: now);

      if (expiredKeys.isNotEmpty) {
        _logger.info('Cleaned up ${expiredKeys.length} expired templates');
      }
    } catch (e) {
      _logger.err('Failed to cleanup cache: $e');
      rethrow;
    }
  }

  /// Clear all cached templates
  Future<void> clearCache() async {
    await _ensureInitialized();

    try {
      // Clear in-memory entries
      _entries.clear();

      // Clear disk storage
      final cacheDir = Directory(_cacheDirectory);
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create(recursive: true);
      }

      // Reset metadata
      _metadata = CacheMetadata(
        cacheVersion: _cacheVersion,
        totalEntries: 0,
        totalSizeBytes: 0,
        lastCleanup: DateTime.now(),
      );

      await _saveMetadata();

      _logger.info('Cleared all cached templates');
    } catch (e) {
      _logger.err('Failed to clear cache: $e');
      rethrow;
    }
  }

  /// Get cache statistics
  Future<CacheStats> getStats() async {
    await _ensureInitialized();

    var validEntries = 0;
    var expiredEntries = 0;
    const corruptedEntries = 0;
    var totalSizeBytes = 0;
    var hitCount = 0;
    const missCount = 0;

    for (final entry in _entries.values) {
      if (entry.template.isExpired) {
        expiredEntries++;
      } else {
        validEntries++;
      }

      totalSizeBytes += _calculateEntrySize(entry);
      hitCount += entry.accessCount;
    }

    final totalEntries = _entries.length;
    final hitRate = totalEntries > 0 ? hitCount / (hitCount + missCount) : 0.0;

    return CacheStats(
      totalEntries: totalEntries,
      validEntries: validEntries,
      expiredEntries: expiredEntries,
      corruptedEntries: corruptedEntries,
      totalSizeBytes: totalSizeBytes,
      hitCount: hitCount,
      missCount: missCount,
      hitRate: hitRate,
    );
  }

  /// Check if cache size limit is exceeded
  Future<bool> isOverSizeLimit() async {
    final stats = await getStats();
    return stats.totalSizeBytes > _maxSizeBytes;
  }

  /// Force cleanup to reduce cache size
  Future<void> enforceSizeLimit() async {
    await _ensureInitialized();

    if (!await isOverSizeLimit()) return;

    _logger.info('Cache size limit exceeded, enforcing cleanup...');

    // Sort entries by last accessed (oldest first)
    final sortedEntries = _entries.values.toList()
      ..sort((a, b) => a.lastAccessed.compareTo(b.lastAccessed));

    // Remove oldest entries until under limit
    final targetSize = (_maxSizeBytes * 0.8).round(); // Target 80% of limit
    var currentSize = 0;

    for (final entry in sortedEntries) {
      currentSize += _calculateEntrySize(entry);
      if (currentSize > targetSize) {
        await invalidate(entry.key);
      }
    }

    _logger.info('Cache size limit enforced');
  }

  // Private methods

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }


  Future<void> _loadMetadata() async {
    final metadataFile = File(path.join(_cacheDirectory, _metadataFileName));
    
    if (await metadataFile.exists()) {
      try {
        final content = await metadataFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        _metadata = CacheMetadata.fromJson(json);
      } catch (e) {
        _logger.warn('Failed to load cache metadata, using defaults: $e');
        _metadata = _createDefaultMetadata();
      }
    } else {
      _metadata = _createDefaultMetadata();
    }
  }

  Future<void> _saveMetadata() async {
    final metadataFile = File(path.join(_cacheDirectory, _metadataFileName));
    final content = jsonEncode(_metadata!.toJson());
    await metadataFile.writeAsString(content);
  }

  Future<void> _loadEntries() async {
    _entries.clear();
    
    final cacheDir = Directory(_cacheDirectory);
    if (!await cacheDir.exists()) {
      _logger.info('Cache directory does not exist, skipping entry loading');
      return;
    }

    try {
      await for (final entity in cacheDir.list()) {
        if (entity is File && 
            entity.path.endsWith('.json') && 
            !entity.path.endsWith(_metadataFileName)) {
          try {
            final content = await entity.readAsString();
            final json = jsonDecode(content) as Map<String, dynamic>;
            final entry = CacheEntry.fromJson(json);
            _entries[entry.key] = entry;
          } catch (e) {
            _logger.warn('Failed to load cache entry ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      _logger.warn('Failed to list cache directory: $e');
    }
  }

  Future<void> _saveEntry(CacheEntry entry) async {
    final entryFile = File(path.join(_cacheDirectory, '${entry.key}.json'));
    final content = jsonEncode(entry.toJson());
    await entryFile.writeAsString(content);
  }

  Future<void> _updateMetadata() async {
    final stats = await getStats();
    _metadata = _metadata!.copyWith(
      totalEntries: stats.totalEntries,
      totalSizeBytes: stats.totalSizeBytes,
    );
    await _saveMetadata();
  }

  Future<bool> _validateChecksum(CachedTemplate template) async {
    try {
      final jsonString = json.encode(template.templateData);
      final currentChecksum = sha256.convert(utf8.encode(jsonString)).toString();
      return currentChecksum == template.checksum;
    } catch (e) {
      _logger.warn('Checksum validation failed for ${template.name}: $e');
      return false;
    }
  }

  int _calculateEntrySize(CacheEntry entry) {
    try {
      final jsonString = json.encode(entry.toJson());
      return utf8.encode(jsonString).length;
    } catch (e) {
      return 0;
    }
  }

  CacheMetadata _createDefaultMetadata() =>
      CacheMetadata(
      cacheVersion: _cacheVersion,
      totalEntries: 0,
      totalSizeBytes: 0,
      lastCleanup: DateTime.now(),
      defaultExpirationDays: _expirationDays,
      maxSizeBytes: _maxSizeBytes,
    );
}
