import 'dart:convert';
import 'dart:io';

import 'package:fly_core/fly_core_dart.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

/// Cache for Flutter and Dart SDK versions
///
/// Stores SDK versions in a persistent cache file to avoid expensive
/// Process.run() calls on every CLI invocation.
/// Cache expires after 24 hours or when invalidated.
class SdkVersionCache {
  SdkVersionCache({
    required this.logger,
    String? cacheDirectory,
  }) : _cacheDirectory = cacheDirectory ?? _getDefaultCacheDirectory();

  final Logger logger;
  final String _cacheDirectory;

  /// Cache duration (24 hours as specified in performance report)
  static const Duration _cacheDuration = Duration(hours: 24);

  /// Cache file name
  static const String _cacheFileName = 'sdk_versions.json';

  /// Get default cache directory
  static String _getDefaultCacheDirectory() {
    return path.join(
      PlatformUtils.getDefaultCacheDirectory(),
      'sdk',
    );
  }

  /// Get Flutter SDK version (cached)
  ///
  /// Returns cached version if available and not expired.
  /// Otherwise, detects version via Process.run() and caches it.
  Future<Version> getFlutterVersion() async {
    final cached = await _readCache('flutter');
    if (cached != null && !_isExpired(cached)) {
      try {
        return Version.parse(cached);
      } catch (e) {
        logger.warn('Invalid cached Flutter version format: $cached');
        // Fall through to detect fresh version
      }
    }

    // Detect fresh version
    final version = await _detectFlutterVersion();
    await _writeCache('flutter', version.toString());
    return version;
  }

  /// Get Dart SDK version (cached)
  ///
  /// Returns cached version if available and not expired.
  /// Otherwise, detects version via Process.run() and caches it.
  Future<Version> getDartVersion() async {
    final cached = await _readCache('dart');
    if (cached != null && !_isExpired(cached)) {
      try {
        return Version.parse(cached);
      } catch (e) {
        logger.warn('Invalid cached Dart version format: $cached');
        // Fall through to detect fresh version
      }
    }

    // Detect fresh version
    final version = await _detectDartVersion();
    await _writeCache('dart', version.toString());
    return version;
  }

  /// Detect Flutter version via Process.run()
  Future<Version> _detectFlutterVersion() async {
    try {
      final result = await Process.run('flutter', [
        '--version',
      ], runInShell: true);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final match = RegExp(r'Flutter (\d+\.\d+\.\d+)').firstMatch(output);
        if (match != null) {
          final versionStr = match.group(1)!;
          try {
            return Version.parse(versionStr);
          } catch (e) {
            logger.warn('Invalid Flutter version format: $versionStr');
          }
        }
      }
    } catch (e) {
      logger.warn('Failed to detect Flutter version: $e');
    }
    // Safe default fallback
    return Version.parse('3.10.0');
  }

  /// Detect Dart version via Process.run()
  Future<Version> _detectDartVersion() async {
    try {
      final result = await Process.run('dart', ['--version'], runInShell: true);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final match = RegExp(
          r'Dart SDK version: (\d+\.\d+\.\d+)',
        ).firstMatch(output);
        if (match != null) {
          final versionStr = match.group(1)!;
          try {
            return Version.parse(versionStr);
          } catch (e) {
            logger.warn('Invalid Dart version format: $versionStr');
          }
        }
      }
    } catch (e) {
      logger.warn('Failed to detect Dart version: $e');
    }
    // Safe default fallback
    return Version.parse('3.0.0');
  }

  /// Read cached version from file
  Future<String?> _readCache(String sdkName) async {
    try {
      final cacheFile = File(path.join(_cacheDirectory, _cacheFileName));
      if (!await cacheFile.exists()) {
        return null;
      }

      final content = await cacheFile.readAsString();
      final data = json.decode(content) as Map<String, dynamic>;

      final sdkData = data[sdkName] as Map<String, dynamic>?;
      if (sdkData == null) {
        return null;
      }

      return sdkData['version'] as String?;
    } catch (e) {
      logger.warn('Failed to read SDK version cache: $e');
      return null;
    }
  }

  /// Write version to cache file
  Future<void> _writeCache(String sdkName, String version) async {
    try {
      // Ensure cache directory exists
      final cacheDir = Directory(_cacheDirectory);
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final cacheFile = File(path.join(_cacheDirectory, _cacheFileName));

      // Read existing cache or create new map
      Map<String, dynamic> cacheData;
      if (await cacheFile.exists()) {
        try {
          final content = await cacheFile.readAsString();
          cacheData = json.decode(content) as Map<String, dynamic>;
        } catch (e) {
          logger.warn('Failed to read existing cache, creating new: $e');
          cacheData = {};
        }
      } else {
        cacheData = {};
      }

      // Update cache for this SDK
      cacheData[sdkName] = {
        'version': version,
        'cached_at': DateTime.now().toIso8601String(),
      };

      // Write cache file
      await cacheFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(cacheData),
      );

      logger.detail('Cached $sdkName version: $version');
    } catch (e) {
      logger.warn('Failed to write SDK version cache: $e');
      // Don't throw - caching failure shouldn't break the CLI
    }
  }

  /// Check if cached version is expired
  bool _isExpired(String? cachedVersion) {
    if (cachedVersion == null) return true;

    try {
      final cacheFile = File(path.join(_cacheDirectory, _cacheFileName));
      if (!cacheFile.existsSync()) {
        return true;
      }

      final content = cacheFile.readAsStringSync();
      final data = json.decode(content) as Map<String, dynamic>;

      // Check all SDK entries for expiration
      for (final entry in data.values) {
        if (entry is Map<String, dynamic>) {
          final cachedAtStr = entry['cached_at'] as String?;
          if (cachedAtStr != null) {
            final cachedAt = DateTime.parse(cachedAtStr);
            final age = DateTime.now().difference(cachedAt);
            if (age > _cacheDuration) {
              return true;
            }
          }
        }
      }

      return false;
    } catch (e) {
      logger.warn('Failed to check cache expiration: $e');
      return true; // Treat as expired on error
    }
  }

  /// Clear the SDK version cache
  Future<void> clearCache() async {
    try {
      final cacheFile = File(path.join(_cacheDirectory, _cacheFileName));
      if (await cacheFile.exists()) {
        await cacheFile.delete();
        logger.info('Cleared SDK version cache');
      }
    } catch (e) {
      logger.warn('Failed to clear SDK version cache: $e');
    }
  }

  /// Force refresh (clear cache and re-detect)
  Future<Map<String, Version>> refresh() async {
    await clearCache();
    final flutter = await getFlutterVersion();
    final dart = await getDartVersion();
    return {
      'flutter': flutter,
      'dart': dart,
    };
  }
}
