import 'package:fly_cli/src/core/templates/versioning/models/compatibility_result.dart';
import 'package:test/test.dart';

void main() {
  group('CompatibilityResult', () {
    group('Compatible', () {
      test('should create compatible result without warnings', () {
        const result = CompatibilityResult.compatible();
        expect(result.isCompatible, isTrue);
        expect(result.isIncompatible, isFalse);
        expect(result.errors, isEmpty);
        expect(result.warnings, isEmpty);
      });

      test('should create compatible result with warnings', () {
        const result = CompatibilityResult.compatible(
          warnings: ['Warning 1', 'Warning 2'],
        );
        expect(result.isCompatible, isTrue);
        expect(result.isIncompatible, isFalse);
        expect(result.errors, isEmpty);
        expect(result.warnings, equals(['Warning 1', 'Warning 2']));
      });
    });

    group('Incompatible', () {
      test('should create incompatible result with errors', () {
        const result = CompatibilityResult.incompatible(
          errors: ['Error 1', 'Error 2'],
        );
        expect(result.isCompatible, isFalse);
        expect(result.isIncompatible, isTrue);
        expect(result.errors, equals(['Error 1', 'Error 2']));
        expect(result.warnings, isEmpty);
      });

      test('should create incompatible result with errors and warnings', () {
        const result = CompatibilityResult.incompatible(
          errors: ['Error 1'],
          warnings: ['Warning 1'],
        );
        expect(result.isCompatible, isFalse);
        expect(result.isIncompatible, isTrue);
        expect(result.errors, equals(['Error 1']));
        expect(result.warnings, equals(['Warning 1']));
      });
    });

    group('equality', () {
      test('Compatible results should be equal', () {
        const result1 = CompatibilityResult.compatible();
        const result2 = CompatibilityResult.compatible();
        expect(result1 == result2, isTrue);
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('Compatible results with same warnings should be equal', () {
        const result1 = CompatibilityResult.compatible(warnings: ['Warning']);
        const result2 = CompatibilityResult.compatible(warnings: ['Warning']);
        expect(result1 == result2, isTrue);
      });

      test('Compatible results with different warnings should not be equal', () {
        const result1 = CompatibilityResult.compatible(warnings: ['Warning 1']);
        const result2 = CompatibilityResult.compatible(warnings: ['Warning 2']);
        expect(result1 == result2, isFalse);
      });

      test('Incompatible results should be equal', () {
        const result1 = CompatibilityResult.incompatible(errors: ['Error']);
        const result2 = CompatibilityResult.incompatible(errors: ['Error']);
        expect(result1 == result2, isTrue);
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('Compatible and Incompatible should not be equal', () {
        const compatible = CompatibilityResult.compatible();
        const incompatible = CompatibilityResult.incompatible(errors: ['Error']);
        expect(compatible == incompatible, isFalse);
      });
    });

    group('toString', () {
      test('should return correct string for Compatible', () {
        const result = CompatibilityResult.compatible(warnings: ['Warning']);
        expect(result.toString(), contains('Compatible'));
        expect(result.toString(), contains('warnings: 1'));
      });

      test('should return correct string for Incompatible', () {
        const result = CompatibilityResult.incompatible(
          errors: ['Error 1', 'Error 2'],
          warnings: ['Warning'],
        );
        expect(result.toString(), contains('Incompatible'));
        expect(result.toString(), contains('errors: 2'));
        expect(result.toString(), contains('warnings: 1'));
      });
    });
  });
}

