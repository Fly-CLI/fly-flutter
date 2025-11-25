/// Interface for cache management operations.
///
/// Provides abstraction over caching, allowing different implementations
/// (in-memory, file-based, distributed, etc.).
abstract class ICacheManager<T> {
  /// Get a value from cache.
  ///
  /// Returns the cached value if found, null otherwise.
  Future<T?> get(String key);

  /// Set a value in cache.
  ///
  /// [key] is the cache key.
  /// [value] is the value to cache.
  /// [ttl] is optional time-to-live in seconds.
  Future<void> set(String key, T value, {int? ttl});

  /// Check if a key exists in cache.
  Future<bool> exists(String key);

  /// Remove a value from cache.
  Future<void> remove(String key);

  /// Clear all cached values.
  Future<void> clear();

  /// Get all cache keys.
  Future<List<String>> getKeys();
}
