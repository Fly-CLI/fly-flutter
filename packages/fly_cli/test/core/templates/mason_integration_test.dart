import 'package:fly_cli/src/core/cache/brick_cache_manager.dart';
import 'package:fly_cli/src/core/templates/brick_registry.dart';
import 'package:fly_cli/src/core/templates/models/brick_info.dart';
import 'package:fly_cli/src/core/templates/template_manager.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';

void main() {
  group('Mason Integration Tests', () {
    late TemplateManager templateManager;
    late BrickRegistry brickRegistry;
    late BrickCacheManager cacheManager;

    setUp(() {
      final logger = Logger();
      cacheManager = BrickCacheManager(logger: logger);
      brickRegistry = BrickRegistry(logger: logger);
      templateManager = TemplateManager(
        templatesDirectory: 'templates',
        logger: logger,
        brickCacheManager: cacheManager,
      );
    });

    test('should discover bricks from registry', () async {
      final bricks = await templateManager.getAvailableBricks();

      // Should discover at least the minimal and riverpod project bricks
      expect(bricks, isNotEmpty);

      final projectBricks =
          bricks.where((brick) => brick.type == BrickType.project).toList();
      expect(projectBricks.length, greaterThanOrEqualTo(2));

      final brickNames = projectBricks.map((brick) => brick.name).toList();
      expect(brickNames, contains('minimal'));
      expect(brickNames, contains('riverpod'));
    });

    test('should get bricks by type', () async {
      final projectBricks = await templateManager.getProjectBricks();
      expect(projectBricks, isNotEmpty);
      expect(projectBricks.every((brick) => brick.type == BrickType.project),
          isTrue);

      final screenBricks = await templateManager.getScreenBricks();
      expect(screenBricks, isNotEmpty);
      expect(screenBricks.every((brick) => brick.type == BrickType.screen),
          isTrue);

      final serviceBricks = await templateManager.getServiceBricks();
      expect(serviceBricks, isNotEmpty);
      expect(serviceBricks.every((brick) => brick.type == BrickType.service),
          isTrue);
    });

    test('should validate bricks', () async {
      final validationResult = await templateManager.validateBrick('minimal');
      expect(validationResult, isNotNull);

      // The minimal brick should be valid
      expect(validationResult.isValid, isTrue);
    });

    test('should generate preview for project', () async {
      final preview = await templateManager.generatePreview(
        brickName: 'minimal',
        brickType: BrickType.project,
        outputDirectory: '/tmp/test',
        variables: {
          'project_name': 'test_project',
          'organization': 'com.example',
          'platforms': ['ios', 'android'],
          'description': 'Test project',
        },
        projectName: 'test_project',
      );

      expect(preview.brickName, equals('minimal'));
      expect(preview.brickType, equals(BrickType.project));
      expect(preview.targetDirectory, contains('test_project'));
      expect(preview.variables['project_name'], equals('test_project'));
      expect(preview.filesToGenerate, isNotEmpty);
    });

    test('should generate preview for screen component', () async {
      final preview = await templateManager.generatePreview(
        brickName: 'screen',
        brickType: BrickType.screen,
        outputDirectory: '/tmp/test',
        variables: {
          'screen_name': 'test_screen',
          'feature': 'home',
          'screen_type': 'list',
          'with_viewmodel': true,
          'with_tests': true,
          'with_validation': false,
          'with_navigation': true,
        },
      );

      expect(preview.brickName, equals('screen'));
      expect(preview.brickType, equals(BrickType.screen));
      expect(preview.variables['screen_name'], equals('test_screen'));
    });

    test('should generate preview for service component', () async {
      final preview = await templateManager.generatePreview(
        brickName: 'service',
        brickType: BrickType.service,
        outputDirectory: '/tmp/test',
        variables: {
          'service_name': 'test_service',
          'feature': 'core',
          'service_type': 'api',
          'with_tests': true,
          'with_mocks': false,
          'with_interceptors': true,
          'base_url': 'https://api.example.com',
        },
      );

      expect(preview.brickName, equals('service'));
      expect(preview.brickType, equals(BrickType.service));
      expect(preview.variables['service_name'], equals('test_service'));
    });

    test('should handle dry run generation', () async {
      final result = await templateManager.generateFromBrick(
        brickName: 'minimal',
        brickType: BrickType.project,
        outputDirectory: '/tmp/test',
        variables: {
          'project_name': 'test_project',
          'organization': 'com.example',
          'platforms': ['ios', 'android'],
          'description': 'Test project',
        },
        dryRun: true,
      );

      expect(result, isNotNull);
      // Dry run should not fail
      expect(result, isNot(isA<TemplateGenerationFailure>()));
    });

    test('should handle component generation', () async {
      final result = await templateManager.generateComponent(
        componentName: 'test_screen',
        componentType: BrickType.screen,
        config: {
          'screen_name': 'test_screen',
          'feature': 'home',
          'screen_type': 'list',
          'with_viewmodel': true,
          'with_tests': true,
          'with_validation': false,
          'with_navigation': true,
        },
        targetPath: '/tmp/test',
      );

      expect(result, isNotNull);
      // Component generation should not fail
      expect(result, isNot(isA<TemplateGenerationFailure>()));
    });

    test('should maintain backward compatibility with legacy methods',
        () async {
      // Test that the legacy getAvailableTemplates method still works
      final templates = await templateManager.getAvailableTemplates();
      expect(templates, isNotEmpty);

      // Should include the project templates
      final templateNames = templates.map((template) => template.name).toList();
      expect(templateNames, contains('minimal'));
      expect(templateNames, contains('riverpod'));
    });

    test('should handle cache operations', () async {
      // Test cache statistics
      final stats = await cacheManager.getCacheStats();
      expect(stats, isA<Map<String, dynamic>>());

      // Test cache clearing
      await cacheManager.clearCache();
      // Should not throw any exceptions
    });

    test('should handle error scenarios gracefully', () async {
      // Test with non-existent brick
      final result = await templateManager.generateFromBrick(
        brickName: 'non_existent_brick',
        brickType: BrickType.project,
        outputDirectory: '/tmp/test',
        variables: {},
      );

      expect(result, isA<TemplateGenerationFailure>());
      expect(
          (result as TemplateGenerationFailure).error, contains('not found'));
    });
  });
}
