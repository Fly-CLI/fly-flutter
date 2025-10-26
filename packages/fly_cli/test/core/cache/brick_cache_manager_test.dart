
import 'package:fly_cli/src/core/cache/brick_cache_manager.dart';
import 'package:fly_cli/src/core/templates/models/brick_info.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';

void main() {
  group('BrickCacheManager', () {
    late BrickCacheManager cacheManager;

    setUp(() {
      cacheManager = BrickCacheManager(logger: Logger());
    });

    test('should initialize with default cache directory', () {
      expect(cacheManager.cacheDirectory, isNotEmpty);
      expect(cacheManager.cacheDirectory, contains('.fly'));
      expect(cacheManager.cacheDirectory, contains('cache'));
      expect(cacheManager.cacheDirectory, contains('bricks'));
    });

    test('should get cache statistics', () async {
      final stats = await cacheManager.getCacheStats();

      expect(stats, isA<Map<String, dynamic>>());
      expect(stats['exists'], isA<bool>());
      expect(stats['total_size_bytes'], isA<int>());
      expect(stats['file_count'], isA<int>());
    });

    test('should clear cache', () async {
      await cacheManager.clearCache();
      // Should not throw any exceptions
    });

    test('should clear specific cache type', () async {
      await cacheManager.clearCacheType('validations');
      // Should not throw any exceptions
    });
  });

  group('GenerationPlan', () {
    test('should create GenerationPlan from JSON', () {
      final json = {
        'brick_name': 'test_brick',
        'brick_type': 'project',
        'target_directory': '/path/to/target',
        'variables': {'project_name': 'test_project'},
        'files_to_generate': ['file1.dart', 'file2.dart'],
        'estimated_duration_ms': 1000,
      };

      final plan = GenerationPlan.fromJson(json);

      expect(plan.brickName, equals('test_brick'));
      expect(plan.brickType, equals(BrickType.project));
      expect(plan.targetDirectory, equals('/path/to/target'));
      expect(plan.variables['project_name'], equals('test_project'));
      expect(plan.filesToGenerate, equals(['file1.dart', 'file2.dart']));
      expect(plan.estimatedDuration.inMilliseconds, equals(1000));
    });

    test('should convert GenerationPlan to JSON', () {
      final plan = GenerationPlan(
        brickName: 'test_brick',
        brickType: BrickType.project,
        targetDirectory: '/path/to/target',
        variables: {'project_name': 'test_project'},
        filesToGenerate: ['file1.dart', 'file2.dart'],
        estimatedDuration: const Duration(milliseconds: 1000),
      );

      final json = plan.toJson();

      expect(json['brick_name'], equals('test_brick'));
      expect(json['brick_type'], equals('project'));
      expect(json['target_directory'], equals('/path/to/target'));
      expect(json['variables']['project_name'], equals('test_project'));
      expect(json['files_to_generate'], equals(['file1.dart', 'file2.dart']));
      expect(json['estimated_duration_ms'], equals(1000));
    });
  });

  group('BrickCacheInfo', () {
    test('should create BrickCacheInfo from JSON', () {
      final json = {
        'cached_at': '2023-01-01T00:00:00.000Z',
        'version': '1.0.0',
        'checksum': 'abc123',
        'brick_count': 5,
      };

      final cacheInfo = BrickCacheInfo.fromJson(json);

      expect(cacheInfo.version, equals('1.0.0'));
      expect(cacheInfo.checksum, equals('abc123'));
      expect(cacheInfo.brickCount, equals(5));
    });

    test('should convert BrickCacheInfo to JSON', () {
      final cacheInfo = BrickCacheInfo(
        cachedAt: DateTime(2023, 1, 1),
        version: '1.0.0',
        checksum: 'abc123',
        brickCount: 5,
      );

      final json = cacheInfo.toJson();

      expect(json['version'], equals('1.0.0'));
      expect(json['checksum'], equals('abc123'));
      expect(json['brick_count'], equals(5));
    });
  });
}
