import 'dart:convert';
import 'dart:io';


import 'package:fly_cli/src/core/cache/cache_models.dart';
import 'package:fly_cli/src/core/cache/template_cache.dart';
import 'package:fly_cli/src/core/templates/models/template_info.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('TemplateCacheManager', () {
    late TemplateCacheManager cacheManager;
    late Directory tempDir;
    late Logger logger;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fly_cache_test_');
      logger = Logger();
      cacheManager = TemplateCacheManager(
        cacheDirectory: tempDir.path,
        logger: logger,
        cacheDuration: const Duration(days: 1), // 1 day for testing
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    group('initialization', () {
      test('should create cache directory on initialize', () async {
        await cacheManager.initialize();
        expect(Directory(cacheManager.cacheDirectory).existsSync(), isTrue);
      });

      test('should not fail if cache directory already exists', () async {
        await cacheManager.initialize();
        await cacheManager.initialize(); // Second call should not fail
        expect(Directory(cacheManager.cacheDirectory).existsSync(), isTrue);
      });
    });

    group('template caching', () {
      late TemplateInfo testTemplate;
      late Directory templateDir;

      setUp(() {
        templateDir = Directory(path.join(tempDir.path, 'test_template'));
        templateDir.createSync(recursive: true);
        
        // Create a test template file
        File(path.join(templateDir.path, 'template.yaml')).writeAsStringSync('''
name: test_template
version: 1.0.0
description: Test template
minFlutterSdk: 3.0.0
minDartSdk: 3.0.0
features: [test]
packages: [test_package]
''');
        
        testTemplate = TemplateInfo(
          name: 'test_template',
          version: '1.0.0',
          description: 'Test template',
          path: templateDir.path,
          minFlutterSdk: '3.0.0',
          minDartSdk: '3.0.0',
          variables: const [],
          features: ['test'],
          packages: ['test_package'],
        );
      });

      tearDown(() {
        if (templateDir.existsSync()) {
          templateDir.deleteSync(recursive: true);
        }
      });

      test('should cache template successfully', () async {
        await cacheManager.initialize();
        
        await cacheManager.cacheTemplate(
          'test_template',
          testTemplate.toJson(),
        );
        
        // Verify template was cached by trying to retrieve it
        final result = await cacheManager.getTemplate('test_template');
        expect(result, isA<CacheSuccess>());
        expect(Directory(path.join(cacheManager.cacheDirectory, 'test_template')).existsSync(), isTrue);
      });

      test('should load cached template successfully', () async {
        await cacheManager.initialize();
        
        // Cache the template first
        await cacheManager.cacheTemplate('test_template', testTemplate.toJson());
        
        // Load it back
        final result = await cacheManager.getTemplate('test_template');
        
        expect(result, isA<CacheSuccess>());
        if (result is CacheSuccess) {
          expect(result.template.templateData['name'], equals('test_template'));
          expect(result.template.templateData['version'], equals('1.0.0'));
        }
      });

      test('should return CacheNotFound for non-existent template', () async {
        await cacheManager.initialize();
        
        final result = await cacheManager.getTemplate('non_existent');
        
          expect(result, isA<CacheMiss>());
      });

      test('should return CacheExpired for expired template', () async {
        await cacheManager.initialize();
        
        // Create a cache manager with very short expiration for this test
        final shortCacheManager = TemplateCacheManager(
          cacheDirectory: tempDir.path,
          logger: logger,
          cacheDuration: const Duration(milliseconds: 100), // Very short duration
        );
        await shortCacheManager.initialize();
        
        // Cache the template
        await shortCacheManager.cacheTemplate('test_template', testTemplate.toJson());
        
        // Wait for expiration
        await Future.delayed(const Duration(milliseconds: 200));
        
        final result = await shortCacheManager.getTemplate('test_template');
        
        expect(result, isA<CacheExpired>());
      });

      test('should return CacheCorrupted for invalid cache data', () async {
        await cacheManager.initialize();
        
        // Write invalid JSON file directly in cache directory
        final invalidFile = File(path.join(cacheManager.cacheDirectory, 'test_template.json'));
        invalidFile.writeAsStringSync('invalid json');
        
        final result = await cacheManager.getTemplate('test_template');
        
        expect(result, isA<CacheCorrupted>());
      });

      test('should handle checksum mismatch', () async {
        await cacheManager.initialize();
        
        // Cache the template
        await cacheManager.cacheTemplate('test_template', testTemplate.toJson());
        
        // Modify the cached template data to change checksum
        final entryFile = File(path.join(cacheManager.cacheDirectory, 'test_template.json'));
        final content = await entryFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        
        // Modify the template data (this is what the checksum is calculated from)
        json['template']['templateData']['name'] = 'modified_name';
        
        // Write back the modified data
        await entryFile.writeAsString(jsonEncode(json));
        
        // Create a new cache manager to force fresh load
        final freshCacheManager = TemplateCacheManager(
          cacheDirectory: tempDir.path,
          logger: logger,
          cacheDuration: const Duration(days: 1),
        );
        await freshCacheManager.initialize();
        
        final result = await freshCacheManager.getTemplate('test_template');
        
        expect(result, isA<CacheCorrupted>());
      });
    });

    group('cache management', () {
      test('should clear cache successfully', () async {
        await cacheManager.initialize();
        
        // Add some templates
        await cacheManager.cacheTemplate('template1', {'name': 'template1'});
        await cacheManager.cacheTemplate('template2', {'name': 'template2'});
        
        // Clear cache
        await cacheManager.clearCache();
        
        // Verify cache is empty (only metadata file should remain)
        final cacheDir = Directory(cacheManager.cacheDirectory);
        expect(cacheDir.existsSync(), isTrue);
        
        final files = cacheDir.listSync();
        // Should only have metadata file
        expect(files.length, equals(1));
        expect(path.basename(files.first.path), equals('cache_metadata.json'));
        
        // Verify no templates are cached
        final result1 = await cacheManager.getTemplate('template1');
        final result2 = await cacheManager.getTemplate('template2');
        expect(result1, isA<CacheMiss>());
        expect(result2, isA<CacheMiss>());
      });

      test('should delete specific template', () async {
        await cacheManager.initialize();
        
        // Add templates
        await cacheManager.cacheTemplate('template1', {'name': 'template1'});
        await cacheManager.cacheTemplate('template2', {'name': 'template2'});
        
        // Delete one template
        await cacheManager.invalidate('template1');
        
        // Verify only one template remains
        final remainingTemplates = Directory(cacheManager.cacheDirectory)
            .listSync()
            .where((file) => file.path.endsWith('.json') && 
                           !file.path.endsWith('cache_metadata.json'),)
            .toList();
        expect(remainingTemplates.length, equals(1));
        expect(path.basename(remainingTemplates.first.path), equals('template2.json'));
      });

      test('should handle deletion of non-existent template gracefully', () async {
        await cacheManager.initialize();
        
        // Should not throw
        await cacheManager.invalidate('non_existent');
      });
    });

    group('cache validation', () {
      test('should validate cache entry structure', () async {
        await cacheManager.initialize();
        
        final templateData = {
          'name': 'test_template',
          'version': '1.0.0',
          'description': 'Test template',
          'path': '/test/path',
          'minFlutterSdk': '3.0.0',
          'minDartSdk': '3.0.0',
          'features': ['test'],
          'packages': ['test_package'],
        };
        
        await cacheManager.cacheTemplate('test_template', templateData);
        
        // Verify template was cached by trying to retrieve it
        final result = await cacheManager.getTemplate('test_template');
        expect(result, isA<CacheSuccess>());
        
        // Verify cache entry structure
        final cacheFile = File(path.join(cacheManager.cacheDirectory, 'test_template.json'));
        expect(cacheFile.existsSync(), isTrue);
        
        // Verify cache file contains valid JSON
        final content = await cacheFile.readAsString();
        final json = jsonDecode(content);
        expect(json.containsKey('key'), isTrue);
        expect(json.containsKey('template'), isTrue);
        expect(json.containsKey('lastAccessed'), isTrue);
        expect(json.containsKey('accessCount'), isTrue);
        
        // Verify template structure
        final template = json['template'];
        expect(template, isA<Map<String, dynamic>>());
        expect(template.containsKey('cachedAt'), isTrue);
        expect(template.containsKey('expiresAt'), isTrue);
        expect(template.containsKey('checksum'), isTrue);
        expect(template.containsKey('templateData'), isTrue);
      });
    });

    group('error handling', () {
      test('should handle cache directory creation failure gracefully', () async {
        // Use a path that exists but is not writable
        final invalidCacheManager = TemplateCacheManager(
          cacheDirectory: '/dev/null', // This exists but is not a directory
          logger: logger,
        );
        
        // Should throw during initialization
        expect(
          invalidCacheManager.initialize,
          throwsException,
        );
      });

      test('should handle template caching failure gracefully', () async {
        await cacheManager.initialize();
        
        // Try to cache with invalid data that will cause an error
        // This should not throw since we handle errors gracefully
        await cacheManager.cacheTemplate('test', <String, dynamic>{});
        
        // Verify the template was cached (even if empty)
        final result = await cacheManager.getTemplate('test');
        expect(result, isA<CacheSuccess>());
      });
    });
  });
}
