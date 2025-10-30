import 'package:fly_cli/src/core/templates/generation_preview.dart';
import 'package:fly_cli/src/core/templates/brick_info.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';

void main() {
  group('GenerationPreview', () {
    test('should create GenerationPreview from JSON', () {
      final json = {
        'brick_name': 'test_brick',
        'brick_type': 'project',
        'target_directory': '/path/to/target',
        'variables': {'project_name': 'test_project'},
        'files_to_generate': ['file1.dart', 'file2.dart'],
        'directories_to_create': ['lib', 'test'],
        'estimated_duration_ms': 1000,
        'warnings': ['Warning 1'],
      };

      final preview = GenerationPreview.fromJson(json);

      expect(preview.brickName, equals('test_brick'));
      expect(preview.brickType, equals(BrickType.project));
      expect(preview.targetDirectory, equals('/path/to/target'));
      expect(preview.variables['project_name'], equals('test_project'));
      expect(preview.filesToGenerate, equals(['file1.dart', 'file2.dart']));
      expect(preview.directoriesToCreate, equals(['lib', 'test']));
      expect(preview.estimatedDuration.inMilliseconds, equals(1000));
      expect(preview.warnings, equals(['Warning 1']));
    });

    test('should convert GenerationPreview to JSON', () {
      final preview = GenerationPreview(
        brickName: 'test_brick',
        brickType: BrickType.project,
        targetDirectory: '/path/to/target',
        variables: {'project_name': 'test_project'},
        filesToGenerate: ['file1.dart', 'file2.dart'],
        directoriesToCreate: ['lib', 'test'],
        estimatedDuration: const Duration(milliseconds: 1000),
        warnings: ['Warning 1'],
      );

      final json = preview.toJson();

      expect(json['brick_name'], equals('test_brick'));
      expect(json['brick_type'], equals('project'));
      expect(json['target_directory'], equals('/path/to/target'));
      expect(json['variables']['project_name'], equals('test_project'));
      expect(json['files_to_generate'], equals(['file1.dart', 'file2.dart']));
      expect(json['directories_to_create'], equals(['lib', 'test']));
      expect(json['estimated_duration_ms'], equals(1000));
      expect(json['warnings'], equals(['Warning 1']));
    });
  });

  group('GenerationPreviewService', () {
    late GenerationPreviewService previewService;

    setUp(() {
      previewService = GenerationPreviewService(logger: Logger());
    });

    test('should get preview statistics', () {
      final preview = GenerationPreview(
        brickName: 'test_brick',
        brickType: BrickType.project,
        targetDirectory: '/path/to/target',
        variables: {'project_name': 'test_project'},
        filesToGenerate: ['file1.dart', 'file2.dart'],
        directoriesToCreate: ['lib'],
        estimatedDuration: const Duration(milliseconds: 1000),
        warnings: ['Warning 1'],
      );

      final stats = previewService.getPreviewStats(preview);

      expect(stats['brick_name'], equals('test_brick'));
      expect(stats['brick_type'], equals('project'));
      expect(stats['files_count'], equals(2));
      expect(stats['directories_count'], equals(1));
      expect(stats['estimated_duration_ms'], equals(1000));
      expect(stats['warnings_count'], equals(1));
      expect(stats['variables_count'], equals(1));
    });
  });
}
