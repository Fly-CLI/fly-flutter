import 'package:fly_cli/src/core/templates/brick_registry.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';

void main() {
  group('BrickRegistry', () {
    late BrickRegistry registry;

    setUp(() {
      registry = BrickRegistry(logger: Logger());
    });

    test('should initialize with empty cache', () {
      expect(registry.getCacheStats()['bricks'], equals(0));
      expect(registry.getCacheStats()['validations'], equals(0));
    });

    test('should add custom brick path', () {
      const customPath = '/custom/brick/path';
      registry.addCustomBrickPath(customPath);

      expect(registry.customBrickPaths, contains(customPath));
    });

    test('should remove custom brick path', () {
      const customPath = '/custom/brick/path';
      registry.addCustomBrickPath(customPath);
      registry.removeCustomBrickPath(customPath);

      expect(registry.customBrickPaths, isNot(contains(customPath)));
    });

    test('should clear cache', () {
      registry.clearCache();
      expect(registry.getCacheStats()['bricks'], equals(0));
      expect(registry.getCacheStats()['validations'], equals(0));
    });
  });

  group('BrickValidationResult', () {
    test('should create successful validation result', () {
      final result = BrickValidationResult.success();

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);
    });

    test('should create failed validation result', () {
      final errors = ['Error 1', 'Error 2'];
      final warnings = ['Warning 1'];
      final result = BrickValidationResult.failure(errors, warnings);

      expect(result.isValid, isFalse);
      expect(result.errors, equals(errors));
      expect(result.warnings, equals(warnings));
    });

    test('should create failed validation result without warnings', () {
      final errors = ['Error 1'];
      final result = BrickValidationResult.failure(errors);

      expect(result.isValid, isFalse);
      expect(result.errors, equals(errors));
      expect(result.warnings, isEmpty);
    });
  });
}
