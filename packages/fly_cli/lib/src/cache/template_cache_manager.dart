import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../platform/platform_utils.dart';

/// Cache metadata structure
class CacheInfo {
  final DateTime downloadedAt;
  final String version;
  final String checksum;

  CacheInfo({
    required this.downloadedAt,
    required this.version,
    required this.checksum,
  });

  Map<String, dynamic> toJson() => {
        'downloaded_at': downloadedAt.toIso8601String(),
        'version': version,
        'checksum': checksum,
      };

  factory CacheInfo.fromJson(Map<String, dynamic> json) => CacheInfo(
        downloadedAt: DateTime.parse(json['downloaded_at']),
        version: json['version'] as String,
        checksum: json['checksum'] as String,
      );
}

/// Template structure (placeholder)
class Template {
  final String name;
  final String version;
  final Map<String, dynamic> content;

  Template({
    required this.name,
    required this.version,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'version': version,
        'content': content,
      };

  factory Template.fromJson(Map<String, dynamic> json) => Template(
        name: json['name'] as String,
        version: json['version'] as String,
        content: json['content'] as Map<String, dynamic>,
      );
}

/// Manages template caching for offline mode
class TemplateCacheManager {
  static const cacheDuration = Duration(days: 7);
  
  /// Get template, checking cache first, then downloading
  Future<Template> getTemplate(
    String name, {
    bool forceRefresh = false,
    bool offlineMode = false,
  }) async {
    final cachedPath = await _getCachePath(name);
    
    // Check cache validity if not forcing refresh
    if (!forceRefresh && await _isCacheValid(cachedPath)) {
      print('Using cached template: $name');
      return await _loadFromCache(cachedPath);
    }
    
    // Try to download if not offline
    if (!offlineMode) {
      try {
        print('Downloading template: $name');
        final template = await _downloadTemplate(name);
        await _saveToCache(cachedPath, template);
        return template;
      } catch (e) {
        if (await _cacheExists(cachedPath)) {
          print('Download failed, using cached version');
          return await _loadFromCache(cachedPath);
        }
        throw Exception(
          'Failed to download template "$name" and no cache available\n'
          'Suggestion: Check your internet connection or use --offline flag with cached templates',
        );
      }
    }
    
    // Offline mode - must use cache
    if (await _cacheExists(cachedPath)) {
      print('Offline mode: using cached template');
      return await _loadFromCache(cachedPath);
    }
    
    throw Exception(
      'Template "$name" not found in cache (offline mode)\n'
      'Suggestion: Download template first with: fly template fetch $name',
    );
  }
  
  /// Check if cache is valid (exists and not expired)
  Future<bool> _isCacheValid(String cachePath) async {
    if (!await _cacheExists(cachePath)) return false;
    
    final cacheInfo = await _getCacheInfo(cachePath);
    final age = DateTime.now().difference(cacheInfo.downloadedAt);
    
    return age < cacheDuration;
  }
  
  /// Save template to cache
  Future<void> _saveToCache(String cachePath, Template template) async {
    final cacheFile = File(cachePath);
    await cacheFile.parent.create(recursive: true);
    
    final checksum = await _calculateChecksum(template);
    
    final cacheData = {
      'template': template.toJson(),
      'downloaded_at': DateTime.now().toIso8601String(),
      'version': template.version,
      'checksum': checksum,
    };
    
    await cacheFile.writeAsString(json.encode(cacheData));
  }
  
  /// Load template from cache
  Future<Template> _loadFromCache(String cachePath) async {
    final cacheFile = File(cachePath);
    final content = await cacheFile.readAsString();
    final data = json.decode(content) as Map<String, dynamic>;
    
    return Template.fromJson(data['template'] as Map<String, dynamic>);
  }
  
  /// Check if cache file exists
  Future<bool> _cacheExists(String cachePath) async {
    return await File(cachePath).exists();
  }
  
  /// Get cache metadata
  Future<CacheInfo> _getCacheInfo(String cachePath) async {
    final cacheFile = File(cachePath);
    final content = await cacheFile.readAsString();
    final data = json.decode(content) as Map<String, dynamic>;
    
    return CacheInfo.fromJson(data);
  }
  
  /// Get cache path for template
  Future<String> _getCachePath(String templateName) async {
    final cacheDir = await PlatformUtils.getCacheDirectory();
    final templateCacheDir = path.join(cacheDir, 'templates');
    await Directory(templateCacheDir).create(recursive: true);
    
    return path.join(templateCacheDir, '$templateName.json');
  }
  
  /// Calculate checksum for template
  Future<String> _calculateChecksum(Template template) async {
    // Simple checksum based on template name and version
    // In production, use a proper hashing algorithm
    return '${template.name}-${template.version}';
  }
  
  /// Download template (placeholder implementation)
  Future<Template> _downloadTemplate(String name) async {
    // Simulate download delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Return mock template
    return Template(
      name: name,
      version: '1.0.0',
      content: {'type': 'template', 'name': name},
    );
  }
}
