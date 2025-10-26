import 'package:json_annotation/json_annotation.dart';

part 'cache_models.g.dart';

/// Represents a cached template with metadata
@JsonSerializable()
class CachedTemplate {

  const CachedTemplate({
    required this.name,
    required this.version,
    required this.cachedAt,
    required this.expiresAt,
    required this.checksum,
    required this.templateData,
    this.cacheVersion = '1.0.0',
  });

  factory CachedTemplate.fromJson(Map<String, dynamic> json) =>
      _$CachedTemplateFromJson(json);
  final String name;
  final String version;
  final DateTime cachedAt;
  final DateTime expiresAt;
  final String checksum;
  final Map<String, dynamic> templateData;
  final String cacheVersion;
  Map<String, dynamic> toJson() => _$CachedTemplateToJson(this);

  /// Check if the cached template is still valid
  bool get isValid => DateTime.now().isBefore(expiresAt);

  /// Check if the cached template is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Get the age of the cached template in days
  int get ageInDays => DateTime.now().difference(cachedAt).inDays;

  /// Get the remaining validity period in days
  int get remainingDays {
    if (isExpired) return 0;
    return expiresAt.difference(DateTime.now()).inDays;
  }

  /// Create a new CachedTemplate with updated expiration
  CachedTemplate withNewExpiration(int daysFromNow) => CachedTemplate(
      name: name,
      version: version,
      cachedAt: cachedAt,
      expiresAt: DateTime.now().add(Duration(days: daysFromNow)),
      checksum: checksum,
      templateData: templateData,
      cacheVersion: cacheVersion,
    );
}

/// Metadata about the cache system
@JsonSerializable()
class CacheMetadata {

  const CacheMetadata({
    required this.cacheVersion,
    required this.totalEntries,
    required this.totalSizeBytes,
    required this.lastCleanup,
    this.defaultExpirationDays = 7,
    this.maxSizeBytes = 100 * 1024 * 1024, // 100MB
  });

  factory CacheMetadata.fromJson(Map<String, dynamic> json) =>
      _$CacheMetadataFromJson(json);
  final String cacheVersion;
  final int totalEntries;
  final int totalSizeBytes;
  final DateTime lastCleanup;
  final int defaultExpirationDays;
  final int maxSizeBytes;
  Map<String, dynamic> toJson() => _$CacheMetadataToJson(this);

  /// Check if cache cleanup is needed
  bool get needsCleanup => DateTime.now().difference(lastCleanup).inDays >= 1;

  /// Check if cache size limit is exceeded
  bool get isOverSizeLimit => totalSizeBytes > maxSizeBytes;

  /// Get cache size as human-readable string
  String get sizeFormatted {
    if (totalSizeBytes < 1024) return '${totalSizeBytes}B';
    if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)}KB';
    }
    return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Create a copy with updated fields
  CacheMetadata copyWith({
    String? cacheVersion,
    int? totalEntries,
    int? totalSizeBytes,
    DateTime? lastCleanup,
    int? defaultExpirationDays,
    int? maxSizeBytes,
  }) => CacheMetadata(
      cacheVersion: cacheVersion ?? this.cacheVersion,
      totalEntries: totalEntries ?? this.totalEntries,
      totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
      lastCleanup: lastCleanup ?? this.lastCleanup,
      defaultExpirationDays: defaultExpirationDays ?? this.defaultExpirationDays,
      maxSizeBytes: maxSizeBytes ?? this.maxSizeBytes,
    );
}

/// Individual cache entry with expiration tracking
@JsonSerializable()
class CacheEntry {

  const CacheEntry({
    required this.key,
    required this.template,
    required this.lastAccessed,
    required this.accessCount,
  });

  factory CacheEntry.fromJson(Map<String, dynamic> json) =>
      _$CacheEntryFromJson(json);
  final String key;
  final CachedTemplate template;
  final DateTime lastAccessed;
  final int accessCount;
  Map<String, dynamic> toJson() => _$CacheEntryToJson(this);

  /// Update access tracking
  CacheEntry markAccessed() => CacheEntry(
      key: key,
      template: template,
      lastAccessed: DateTime.now(),
      accessCount: accessCount + 1,
    );

  /// Check if entry is stale (not accessed recently)
  bool get isStale => DateTime.now().difference(lastAccessed).inDays > 30;
}

/// Cache operation result
sealed class CacheResult {
  const CacheResult();
}

class CacheSuccess extends CacheResult {
  const CacheSuccess({required this.template});
  final CachedTemplate template;
}

class CacheMiss extends CacheResult {
  const CacheMiss();
}

class CacheExpired extends CacheResult {
  const CacheExpired({required this.template});
  final CachedTemplate template;
}

class CacheCorrupted extends CacheResult {
  const CacheCorrupted({required this.error});
  final String error;
}

class CacheError extends CacheResult {
  const CacheError({required this.message});
  final String message;
}

/// Cache statistics for monitoring
@JsonSerializable()
class CacheStats {

  const CacheStats({
    required this.totalEntries,
    required this.validEntries,
    required this.expiredEntries,
    required this.corruptedEntries,
    required this.totalSizeBytes,
    required this.hitCount,
    required this.missCount,
    required this.hitRate,
  });

  factory CacheStats.fromJson(Map<String, dynamic> json) =>
      _$CacheStatsFromJson(json);
  final int totalEntries;
  final int validEntries;
  final int expiredEntries;
  final int corruptedEntries;
  final int totalSizeBytes;
  final int hitCount;
  final int missCount;
  final double hitRate;
  Map<String, dynamic> toJson() => _$CacheStatsToJson(this);
}