import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

import 'package:fly_cli/src/core/utils/platform_utils.dart';
import 'package:fly_core/src/file_operations/file_operations.dart';
import 'package:fly_core/src/retry/retry.dart';

/// Cache metadata structure
class CacheInfo {

  CacheInfo({
    required this.downloadedAt,
    required this.version,
    required this.checksum,
  });

  factory CacheInfo.fromJson(Map<String, dynamic> json) => CacheInfo(
        downloadedAt: DateTime.parse(json['downloaded_at'] as String),
        version: json['version'] as String,
        checksum: json['checksum'] as String,
      );
  final DateTime downloadedAt;
  final String version;
  final String checksum;

  Map<String, dynamic> toJson() => {
        'downloaded_at': downloadedAt.toIso8601String(),
        'version': version,
        'checksum': checksum,
      };
}

/// Template structure (placeholder)
class Template {

  Template({
    required this.name,
    required this.version,
    required this.content,
  });

  factory Template.fromJson(Map<String, dynamic> json) => Template(
        name: json['name'] as String,
        version: json['version'] as String,
        content: json['content'] as Map<String, dynamic>,
      );
  final String name;
  final String version;
  final Map<String, dynamic> content;

  Map<String, dynamic> toJson() => {
        'name': name,
        'version': version,
        'content': content,
      };
}

/// Manages template caching for offline mode
class TemplateCacheManager {
  TemplateCacheManager({
    FileReader? fileReader,
    FileWriter? fileWriter,
    ChecksumCalculator? checksumCalculator,
    DirectoryManager? directoryManager,
    FileCache? fileCache,
  })  : _fileReader = fileReader ?? const FileReader(),
        _fileWriter = fileWriter ?? const FileWriter(),
        _checksumCalculator = checksumCalculator ?? const ChecksumCalculator(),
        _directoryManager = directoryManager ?? const DirectoryManager(),
        _fileCache = fileCache ?? FileCache();

  static const cacheDuration = Duration(days: 7);
  
  final FileReader _fileReader;
  final FileWriter _fileWriter;
  final ChecksumCalculator _checksumCalculator;
  final DirectoryManager _directoryManager;
  final FileCache _fileCache;
  
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
      return _loadFromCache(cachedPath);
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
          return _loadFromCache(cachedPath);
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
      return _loadFromCache(cachedPath);
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
    await _directoryManager.ensureExists(cacheFile.parent.path);
    
    final checksum = await _calculateChecksum(template);
    
    final cacheData = {
      'template': template.toJson(),
      'downloaded_at': DateTime.now().toIso8601String(),
      'version': template.version,
      'checksum': checksum,
    };
    
    final success = await _fileWriter.writeFileAtomic(
      cacheFile,
      json.encode(cacheData),
    );
    
    if (!success) {
      throw Exception('Failed to write template cache to $cachePath');
    }
  }
  
  /// Load template from cache
  Future<Template> _loadFromCache(String cachePath) async {
    final cacheFile = File(cachePath);
    
    // Check memory cache first
    final cachedContent = _fileCache.get(cachePath);
    if (cachedContent != null) {
      final data = json.decode(cachedContent) as Map<String, dynamic>;
      return Template.fromJson(data['template'] as Map<String, dynamic>);
    }
    
    // Read from disk
    final content = await _fileReader.readFile(cacheFile);
    if (content == null) {
      throw Exception('Failed to read template cache from $cachePath');
    }
    
    // Cache in memory for future reads
    _fileCache.set(cachePath, content, ttl: cacheDuration);
    
    final data = json.decode(content) as Map<String, dynamic>;
    return Template.fromJson(data['template'] as Map<String, dynamic>);
  }
  
  /// Check if cache file exists
  Future<bool> _cacheExists(String cachePath) async {
    final cacheFile = File(cachePath);
    return await _fileReader.isReadable(cacheFile);
  }
  
  /// Get cache metadata
  Future<CacheInfo> _getCacheInfo(String cachePath) async {
    final cacheFile = File(cachePath);
    final content = await _fileReader.readFile(cacheFile);
    if (content == null) {
      throw Exception('Failed to read cache metadata from $cachePath');
    }
    
    final data = json.decode(content) as Map<String, dynamic>;
    return CacheInfo.fromJson(data);
  }
  
  /// Get cache path for template
  Future<String> _getCachePath(String templateName) async {
    final cacheDir = await PlatformUtils.getCacheDirectory();
    final templateCacheDir = path.join(cacheDir, 'templates');
    await _directoryManager.ensureExists(templateCacheDir);
    
    return path.join(templateCacheDir, '$templateName.json');
  }
  
  /// Calculate checksum for template
  Future<String> _calculateChecksum(Template template) async {
    // Use unified checksum calculator
    return _checksumCalculator.calculateForMap(template.toJson());
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
