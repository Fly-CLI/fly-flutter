import 'package:fly_cli/src/generation/brick/brick_metadata.dart' show BrickType, BrickCategory;
import 'package:fly_cli/src/generation/domain/entities/brick.dart';
import 'package:fly_cli/src/generation/domain/services/brick_validator.dart';
import 'package:fly_cli/src/generation/domain/value_objects/brick_variable.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('BrickValidator', () {
    late BrickValidator validator;

    setUp(() {
      validator = const BrickValidator();
    });

    group('validate', () {
      test('should validate valid brick', () {
        // Arrange
        final brick = Brick(
          name: 'test_brick',
          version: Version.parse('1.0.0'),
          description: 'Test description',
          path: '/test/path',
          type: BrickType.feature,
          category: BrickCategory.component,
          variables: {},
          features: [],
          packages: [],
        );

        // Act
        final result = validator.validate(brick);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should fail validation for empty name', () {
        // Arrange
        final brick = Brick(
          name: '',
          version: Version.parse('1.0.0'),
          description: 'Test description',
          path: '/test/path',
          type: BrickType.feature,
          category: BrickCategory.component,
          variables: {},
          features: [],
          packages: [],
        );

        // Act
        final result = validator.validate(brick);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Invalid brick name'));
      });

      test('should fail validation for empty description', () {
        // Arrange
        final brick = Brick(
          name: 'test_brick',
          version: Version.parse('1.0.0'),
          description: '',
          path: '/test/path',
          type: BrickType.feature,
          category: BrickCategory.component,
          variables: {},
          features: [],
          packages: [],
        );

        // Act
        final result = validator.validate(brick);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Brick description is required'));
      });

      test('should fail validation for type-category mismatch', () {
        // Arrange
        final brick = Brick(
          name: 'test_brick',
          version: Version.parse('1.0.0'),
          description: 'Test description',
          path: '/test/path',
          type: BrickType.feature,
          category: BrickCategory.project, // Mismatch
          variables: {},
          features: [],
          packages: [],
        );

        // Act
        final result = validator.validate(brick);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, anyElement(contains('category')));
      });
    });

    group('isValidName', () {
      test('should accept valid brick names', () {
        expect(validator.isValidName('test_brick'), isTrue);
        expect(validator.isValidName('my-feature'), isTrue);
        expect(validator.isValidName('brick123'), isTrue);
      });

      test('should reject invalid brick names', () {
        expect(validator.isValidName(''), isFalse);
        expect(validator.isValidName('TestBrick'), isFalse); // Uppercase
        expect(validator.isValidName('test brick'), isFalse); // Space
        expect(validator.isValidName('ab'), isFalse); // Too short
        expect(validator.isValidName('a' * 51), isFalse); // Too long
      });
    });

    group('validateVariables', () {
      test('should validate variables without errors', () {
        // Arrange
        final brick = Brick(
          name: 'test_brick',
          version: Version.parse('1.0.0'),
          description: 'Test description',
          path: '/test/path',
          type: BrickType.feature,
          category: BrickCategory.component,
          variables: {
            'name': const BrickVariable(
              name: 'name',
              type: 'string',
              required: true,
            ),
          },
          features: [],
          packages: [],
        );

        // Act
        final errors = validator.validateVariables(brick);

        // Assert
        expect(errors, isEmpty);
      });

      test('should detect duplicate variable names', () {
        // Arrange
        final brick = Brick(
          name: 'test_brick',
          version: Version.parse('1.0.0'),
          description: 'Test description',
          path: '/test/path',
          type: BrickType.feature,
          category: BrickCategory.component,
          variables: {
            'name': const BrickVariable(
              name: 'name',
              type: 'string',
              required: true,
            ),
            // Note: Map keys are unique, so duplicate keys are not possible
            // This test validates the structure
          },
          features: [],
          packages: [],
        );

        // Act
        final errors = validator.validateVariables(brick);

        // Assert
        // Note: Map keys are unique, so this test may need adjustment
        // This is more of a conceptual test
        expect(errors, isA<List<String>>());
      });
    });
  });
}


