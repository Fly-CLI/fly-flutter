import 'dart:io';

import 'package:test/test.dart';
import 'package:fly_cli/src/cache/cache_models.dart';
import 'package:fly_cli/src/cache/template_cache.dart';
import 'package:fly_cli/src/templates/template_manager.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

void main() {
  group('Cache Integration Tests', () {
    late TemplateCacheManager cacheManager;
    late TemplateManager templateManager;
    late Directory tempDir;
    late Logger logger;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('fly_integration_test_');
      logger = Logger();

      cacheManager = TemplateCacheManager(
        cacheDirectory: path.join(tempDir.path, 'cache'),
        logger: logger,
        cacheDuration:
            const Duration(minutes: 5), // Longer duration for integration tests
      );

      templateManager = TemplateManager(
        templatesDirectory: path.join(tempDir.path, 'templates'),
        logger: logger,
        cacheManager: cacheManager,
      );

      // Create templates directory
      await Directory(templateManager.templatesDirectory)
          .create(recursive: true);
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('Template Caching Integration', () {
      test('should cache template on first load and use cache on second load',
          () async {
        // Create a test template
        final templateDir = Directory(
            path.join(templateManager.templatesDirectory, 'test_template'));
        await templateDir.create(recursive: true);

        // Create template.yaml
        File(path.join(templateDir.path, 'template.yaml')).writeAsStringSync('''
name: test_template
version: 1.0.0
description: Test template for integration
minFlutterSdk: 3.0.0
minDartSdk: 3.0.0
features: [test]
packages: [test_package]
''');

        // First load - should cache the template
        final firstLoad = await templateManager.getTemplate('test_template');
        expect(firstLoad, isNotNull);
        expect(firstLoad!.name, equals('test_template'));

        // Verify template was cached
        final cacheResult = await cacheManager.getTemplate('test_template');
        expect(cacheResult, isA<CacheSuccess>());

        // Second load - should use cache
        final secondLoad = await templateManager.getTemplate('test_template');
        expect(secondLoad, isNotNull);
        expect(secondLoad!.name, equals('test_template'));

        // Both loads should return the same template
        expect(firstLoad.name, equals(secondLoad.name));
        expect(firstLoad.version, equals(secondLoad.version));
      });

      test('should handle cache miss gracefully', () async {
        final result =
            await templateManager.getTemplate('non_existent_template');
        expect(result, isNull);
      });

      test('should reload template when cache expires', () async {
        // Create a test template
        final templateDir = Directory(
            path.join(templateManager.templatesDirectory, 'expiring_template'));
        await templateDir.create(recursive: true);

        File(path.join(templateDir.path, 'template.yaml')).writeAsStringSync('''
name: expiring_template
version: 1.0.0
description: Template that will expire
minFlutterSdk: 3.0.0
minDartSdk: 3.0.0
features: [test]
packages: [test_package]
''');

        // Create cache manager with short expiration
        final shortCacheManager = TemplateCacheManager(
          cacheDirectory: path.join(tempDir.path, 'short_cache'),
          logger: logger,
          cacheDuration: const Duration(milliseconds: 100),
        );

        final shortTemplateManager = TemplateManager(
          templatesDirectory: templateManager.templatesDirectory,
          logger: logger,
          cacheManager: shortCacheManager,
        );

        // First load - should cache
        final firstLoad =
            await shortTemplateManager.getTemplate('expiring_template');
        expect(firstLoad, isNotNull);

        // Wait for expiration
        await Future.delayed(const Duration(milliseconds: 200));

        // Second load - should reload from source
        final secondLoad =
            await shortTemplateManager.getTemplate('expiring_template');
        expect(secondLoad, isNotNull);
        expect(firstLoad!.name, equals(secondLoad!.name));
      });
    });

    group('Offline Mode Simulation', () {
      test('should use cached template when source is unavailable', () async {
        // Create a test template
        final templateDir = Directory(
            path.join(templateManager.templatesDirectory, 'offline_template'));
        await templateDir.create(recursive: true);

        File(path.join(templateDir.path, 'template.yaml')).writeAsStringSync('''
name: offline_template
version: 1.0.0
description: Template for offline testing
minFlutterSdk: 3.0.0
minDartSdk: 3.0.0
features: [test]
packages: [test_package]
''');

        // First load - cache the template
        final firstLoad = await templateManager.getTemplate('offline_template');
        expect(firstLoad, isNotNull);

        // Simulate offline mode by removing the source template
        await templateDir.delete(recursive: true);

        // Second load - should still work from cache
        final secondLoad =
            await templateManager.getTemplate('offline_template');
        expect(secondLoad, isNotNull);
        expect(secondLoad!.name, equals('offline_template'));
      });

      test('should handle cache corruption gracefully', () async {
        // Create a test template
        final templateDir = Directory(
            path.join(templateManager.templatesDirectory, 'corrupt_template'));
        await templateDir.create(recursive: true);

        File(path.join(templateDir.path, 'template.yaml')).writeAsStringSync('''
name: corrupt_template
version: 1.0.0
description: Template for corruption testing
minFlutterSdk: 3.0.0
minDartSdk: 3.0.0
features: [test]
packages: [test_package]
''');

        // First load - cache the template
        await templateManager.getTemplate('corrupt_template');

        // Corrupt the cache
        final cacheDir = Directory(
            path.join(cacheManager.cacheDirectory, 'corrupt_template'));
        if (cacheDir.existsSync()) {
          File(path.join(cacheDir.path, 'cache_entry.json'))
              .writeAsStringSync('invalid json');
        }

        // Second load - should reload from source despite corruption
        final result = await templateManager.getTemplate('corrupt_template');
        expect(result, isNotNull);
        expect(result!.name, equals('corrupt_template'));
      });
    });

    group('Cache Management Integration', () {
      test('should clear cache and reload templates', () async {
        // Create a test template
        final templateDir = Directory(path.join(
            templateManager.templatesDirectory, 'clearable_template'));
        await templateDir.create(recursive: true);

        File(path.join(templateDir.path, 'template.yaml')).writeAsStringSync('''
name: clearable_template
version: 1.0.0
description: Template for cache clearing test
minFlutterSdk: 3.0.0
minDartSdk: 3.0.0
features: [test]
packages: [test_package]
''');

        // Load template to cache it
        await templateManager.getTemplate('clearable_template');

        // Verify cache exists
        final cacheResult =
            await cacheManager.getTemplate('clearable_template');
        expect(cacheResult, isA<CacheSuccess>());

        // Clear cache
        await cacheManager.clearCache();

        // Verify cache is cleared
        final clearedResult =
            await cacheManager.getTemplate('clearable_template');
            expect(clearedResult, isA<CacheMiss>());

        // Template should still be loadable from source
        final reloaded =
            await templateManager.getTemplate('clearable_template');
        expect(reloaded, isNotNull);
        expect(reloaded!.name, equals('clearable_template'));
      });

      test('should handle multiple templates in cache', () async {
        // Create multiple test templates
        final templates = ['template1', 'template2', 'template3'];

        for (final templateName in templates) {
          final templateDir = Directory(
              path.join(templateManager.templatesDirectory, templateName));
          await templateDir.create(recursive: true);

          File(path.join(templateDir.path, 'template.yaml'))
              .writeAsStringSync('''
name: $templateName
version: 1.0.0
description: Test template $templateName
minFlutterSdk: 3.0.0
minDartSdk: 3.0.0
features: [test]
packages: [test_package]
''');
        }

        // Load all templates to cache them
        for (final templateName in templates) {
          final template = await templateManager.getTemplate(templateName);
          expect(template, isNotNull);
          expect(template!.name, equals(templateName));
        }

        // Verify all templates are cached
        for (final templateName in templates) {
          final cacheResult = await cacheManager.getTemplate(templateName);
          expect(cacheResult, isA<CacheSuccess>());
        }

        // Delete one template from source
        await Directory(
                path.join(templateManager.templatesDirectory, 'template2'))
            .delete(recursive: true);

        // template2 should still be available from cache
        final cachedTemplate = await templateManager.getTemplate('template2');
        expect(cachedTemplate, isNotNull);
        expect(cachedTemplate!.name, equals('template2'));
      });
    });
  });
}
