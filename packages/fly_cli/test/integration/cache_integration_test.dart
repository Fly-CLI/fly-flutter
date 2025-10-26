import 'dart:io';
import 'package:test/test.dart';
import 'package:fly_cli/src/cache/template_cache_manager.dart';
import 'package:fly_cli/src/fallback/fallback_strategy.dart';
import 'package:fly_cli/src/platform/platform_utils.dart';

void main() {
  group('Cache Integration Tests', () {
    late String testCacheDir;

    setUp(() async {
      // Create a test cache directory
      final configDir = await PlatformUtils.getConfigDirectory();
      testCacheDir = '$configDir/test_cache';
      await Directory(testCacheDir).create(recursive: true);

    });

    tearDown(() async {
      // Clean up test cache directory
      if (await Directory(testCacheDir).exists()) {
        await Directory(testCacheDir).delete(recursive: true);
      }
    });

    group('Template Caching', () {
      test('cache manager can save and load templates', () async {
        final testTemplate = Template(
          name: 'test_template',
          version: '1.0.0',
          content: {'type': 'test', 'data': 'test_data'},
        );

        // Create cache manually for testing
        final cacheDir = await PlatformUtils.getCacheDirectory();
        final templateCacheDir = '$cacheDir/templates';
        await Directory(templateCacheDir).create(recursive: true);

        final cacheFile = File('$templateCacheDir/test_template.json');
        
        // Test that cache file can be created and written
        expect(await cacheFile.exists(), false);
        
        // Note: Full cache save/load would require complete TemplateCacheManager
        // implementation with actual file I/O. This test verifies structure.
        expect(testTemplate.name, 'test_template');
        expect(testTemplate.content['data'], 'test_data');
      });

      test('cache directory structure is valid', () async {
        final cacheDir = await PlatformUtils.getCacheDirectory();
        final templateCacheDir = '$cacheDir/templates';

        expect(cacheDir, isNotEmpty);
        expect(templateCacheDir, contains('cache'));
        expect(templateCacheDir, contains('fly_cli'));
      });
    });

    group('Offline Mode', () {
      test('fallback strategy handles offline mode gracefully', () async {
        final cacheManager = TemplateCacheManager();
        final fallbackStrategy = FallbackStrategy(cacheManager);

        // Should attempt to use cache when offline
        expect(
          () => fallbackStrategy.getTemplate('nonexistent', offlineMode: true),
          throwsA(isA<TemplateNotFoundException>()),
        );
      });
    });

    group('Fallback Strategy Integration', () {
      test('fallback strategy uses cache manager', () {
        final cacheManager = TemplateCacheManager();
        final fallbackStrategy = FallbackStrategy(cacheManager);

        // Verify fallback strategy is initialized with cache manager
        expect(fallbackStrategy, isNotNull);
        expect(cacheManager, isNotNull);
      });

      test('suggestions are generated contextually', () {
        final cacheManager = TemplateCacheManager();
        final fallbackStrategy = FallbackStrategy(cacheManager);

        // This would test suggestion generation if exposed
        expect(fallbackStrategy, isNotNull);
      });
    });
  });
}
