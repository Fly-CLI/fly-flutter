import 'package:fly_logger/fly_logger.dart';

/// In-memory cache service with TTL (Time To Live) support
class CacheService {
  final Map<String, _CacheEntry> _cache = {};
  final FlyLogger _logger;

  CacheService({required FlyLogger logger}) : _logger = logger;

  /// Get cached value
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // Check if expired
    if (entry.isExpired) {
      _cache.remove(key);
      _logger.debug('Cache expired for key: $key');
      return null;
    }

    return entry.value as T?;
  }

  /// Set cached value with TTL
  void set<T>(String key, T value, {Duration? ttl}) {
    _cache[key] = _CacheEntry(
      value: value,
      expiresAt: ttl != null ? DateTime.now().add(ttl) : null,
    );
    _logger.debug('Cached value for key: $key');
  }

  /// Remove cached value
  void remove(String key) {
    _cache.remove(key);
    _logger.debug('Removed cache for key: $key');
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
    _logger.debug('Cleared all cache');
  }

  /// Check if key exists and is valid
  bool containsKey(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  /// Get cache size
  int get size => _cache.length;
}

/// Internal cache entry with expiration
class _CacheEntry {
  final dynamic value;
  final DateTime? expiresAt;

  _CacheEntry({
    required this.value,
    this.expiresAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

