import 'validation_result.dart';

/// Cache for async validation results with TTL support
/// 
/// Provides efficient caching of expensive validation operations
/// to reduce redundant checks.
class AsyncValidationCache {
  AsyncValidationCache({
    Duration? defaultTtl,
  }) : _defaultTtl = defaultTtl ?? const Duration(minutes: 5);

  final Duration _defaultTtl;

  /// Cache storage: key -> (result, timestamp, ttl)
  final Map<String, _CachedValidation> _cache = {};

  /// Get cached result if available and not expired
  ValidationResult? get(String key) {
    final entry = _cache[key];
    if (entry == null) {
      return null;
    }

    final age = DateTime.now().difference(entry.timestamp);
    if (age > entry.ttl) {
      _cache.remove(key);
      return null;
    }

    return entry.result;
  }

  /// Store result in cache
  void set(String key, ValidationResult result, {Duration? ttl}) {
    _cache[key] = _CachedValidation(
      result: result,
      timestamp: DateTime.now(),
      ttl: ttl ?? _defaultTtl,
    );
  }

  /// Check if a key is cached and valid
  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) {
      return false;
    }

    final age = DateTime.now().difference(entry.timestamp);
    if (age > entry.ttl) {
      _cache.remove(key);
      return false;
    }

    return true;
  }

  /// Remove a specific cache entry
  void remove(String key) {
    _cache.remove(key);
  }

  /// Clear all cache entries
  void clear() {
    _cache.clear();
  }

  /// Get cache size
  int get size => _cache.length;

  /// Remove expired entries
  void evictExpired() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) {
      return now.difference(entry.timestamp) > entry.ttl;
    });
  }

  /// Get all cache keys
  List<String> get keys => _cache.keys.toList();

  /// Generate a cache key from components
  static String generateKey(String type, String value, {String? fieldName}) {
    if (fieldName != null) {
      return '$type:$fieldName:$value';
    }
    return '$type:$value';
  }
}

/// Cached validation entry with TTL
class _CachedValidation {
  const _CachedValidation({
    required this.result,
    required this.timestamp,
    required this.ttl,
  });

  final ValidationResult result;
  final DateTime timestamp;
  final Duration ttl;
}

