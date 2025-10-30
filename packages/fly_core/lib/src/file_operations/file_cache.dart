/// Cache for file operations with TTL support
/// 
/// Provides in-memory caching of file contents with expiration
/// to reduce redundant file I/O operations.
class FileCache {
  /// Creates a file cache with default TTL
  FileCache({
    Duration? defaultTtl,
  }) : _defaultTtl = defaultTtl ?? const Duration(minutes: 5);

  /// Default time-to-live for cache entries
  final Duration _defaultTtl;

  /// Cache storage: path -> (content, timestamp, ttl)
  final Map<String, _CacheEntry> _cache = {};

  /// Get cached content if available and not expired
  String? get(String path) {
    final entry = _cache[path];
    if (entry == null) {
      return null;
    }

    final age = DateTime.now().difference(entry.timestamp);
    if (age > entry.ttl) {
      _cache.remove(path);
      return null;
    }

    return entry.content;
  }

  /// Store content in cache
  void set(String path, String content, {Duration? ttl}) {
    _cache[path] = _CacheEntry(
      content: content,
      timestamp: DateTime.now(),
      ttl: ttl ?? _defaultTtl,
    );
  }

  /// Check if a path is cached and valid
  bool has(String path) {
    final entry = _cache[path];
    if (entry == null) {
      return false;
    }

    final age = DateTime.now().difference(entry.timestamp);
    if (age > entry.ttl) {
      _cache.remove(path);
      return false;
    }

    return true;
  }

  /// Remove a specific cache entry
  void remove(String path) {
    _cache.remove(path);
  }

  /// Clear all cache entries
  void clear() {
    _cache.clear();
  }

  /// Get cache size (number of entries)
  int get size => _cache.length;

  /// Get cache statistics
  CacheStats getStats() {
    var totalBytes = 0;
    DateTime? oldestEntry;
    
    for (final entry in _cache.values) {
      totalBytes += entry.content.length;
      if (oldestEntry == null || entry.timestamp.isBefore(oldestEntry)) {
        oldestEntry = entry.timestamp;
      }
    }

    return CacheStats(
      entries: _cache.length,
      totalBytes: totalBytes,
      oldestEntry: oldestEntry,
    );
  }

  /// Remove expired entries
  void evictExpired() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) {
      return now.difference(entry.timestamp) > entry.ttl;
    });
  }

  /// Get all cached paths
  List<String> get keys => _cache.keys.toList();
}

/// Cache entry with TTL
class _CacheEntry {
  const _CacheEntry({
    required this.content,
    required this.timestamp,
    required this.ttl,
  });

  final String content;
  final DateTime timestamp;
  final Duration ttl;
}

/// Cache statistics
class CacheStats {
  const CacheStats({
    required this.entries,
    required this.totalBytes,
    this.oldestEntry,
  });

  /// Number of cache entries
  final int entries;

  /// Total size in bytes
  final int totalBytes;

  /// Timestamp of oldest entry
  final DateTime? oldestEntry;

  Map<String, dynamic> toMap() {
    return {
      'entries': entries,
      'total_bytes': totalBytes,
      'oldest_entry': oldestEntry?.toIso8601String(),
    };
  }
}

