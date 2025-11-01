import 'package:fly_cli/src/integrations/mcp/validation/structured_schema_validator.dart';
import 'package:test/test.dart';

void main() {
  group('StructuredSchemaValidator', () {
    group('validateWithDetails', () {
      test('should validate simple string field', () {
        final schema = {
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
          },
          'required': ['name'],
        };

        final data = {'name': 'test'};
        final errors =
            StructuredSchemaValidator.validateWithDetails(data, schema);

        expect(errors, isEmpty);
      });

      test('should detect missing required field', () {
        final schema = {
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
          },
          'required': ['name'],
        };

        final data = <String, dynamic>{};
        final errors =
            StructuredSchemaValidator.validateWithDetails(data, schema);

        expect(errors, hasLength(1));
        expect(errors.first.path, 'name');
        expect(errors.first.type, ValidationErrorType.missingRequired);
        expect(errors.first.message, contains('Required'));
        expect(errors.first.hint, isNotNull);
      });

      test('should detect type mismatch', () {
        final schema = {
          'type': 'object',
          'properties': {
            'count': {'type': 'integer'},
          },
        };

        final data = {'count': 'not a number'};
        final errors =
            StructuredSchemaValidator.validateWithDetails(data, schema);

        expect(errors, hasLength(1));
        expect(errors.first.path, 'count');
        expect(errors.first.type, ValidationErrorType.typeMismatch);
        expect(errors.first.expected, 'integer');
        expect(errors.first.actual, 'string');
        expect(errors.first.hint, isNotNull);
      });

      test('should detect invalid enum value', () {
        final schema = {
          'type': 'object',
          'properties': {
            'type': {
              'type': 'string',
              'enum': ['list', 'detail', 'form'],
            },
          },
        };

        final data = {'type': 'invalid'};
        final errors =
            StructuredSchemaValidator.validateWithDetails(data, schema);

        expect(errors, hasLength(1));
        expect(errors.first.path, 'type');
        expect(errors.first.type, ValidationErrorType.invalidEnum);
        expect(errors.first.message, contains('enum'));
        expect(errors.first.hint, contains('list'));
        expect(errors.first.hint, contains('detail'));
        expect(errors.first.hint, contains('form'));
      });

      test('should suggest similar enum values', () {
        final schema = {
          'type': 'object',
          'properties': {
            'state': {
              'type': 'string',
              'enum': ['riverpod', 'bloc', 'provider'],
            },
          },
        };

        final data = {'state': 'riverpdo'}; // Typo
        final errors =
            StructuredSchemaValidator.validateWithDetails(data, schema);

        expect(errors, hasLength(1));
        expect(errors.first.path, 'state');
        expect(errors.first.hint, contains('riverpod'));
      });

      test('should validate nested objects', () {
        final schema = {
          'type': 'object',
          'properties': {
            'config': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
                'count': {'type': 'integer'},
              },
              'required': ['name'],
            },
          },
        };

        final data = {'config': <String, dynamic>{}};
        final errors =
            StructuredSchemaValidator.validateWithDetails(data, schema);

        expect(errors, hasLength(1));
        expect(errors.first.path, 'config.name');
        expect(errors.first.type, ValidationErrorType.missingRequired);
      });

      test('should validate array items', () {
        final schema = {
          'type': 'object',
          'properties': {
            'platforms': {
              'type': 'array',
              'items': {
                'type': 'string',
                'enum': ['ios', 'android', 'web'],
              },
            },
          },
        };

        final data = {
          'platforms': ['ios', 'invalid', 'android']
        };
        final errors =
            StructuredSchemaValidator.validateWithDetails(data, schema);

        expect(errors, hasLength(1));
        expect(errors.first.path, 'platforms[1]');
        expect(errors.first.type, ValidationErrorType.invalidEnum);
      });

      test('should validate additionalProperties restriction', () {
        final schema = {
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
          },
          'additionalProperties': false,
        };

        final data = {
          'name': 'test',
          'extra': 'field',
        };
        final errors =
            StructuredSchemaValidator.validateWithDetails(data, schema);

        expect(errors, hasLength(1));
        expect(errors.first.path, 'extra');
        expect(errors.first.type,
            ValidationErrorType.additionalPropertyNotAllowed);
      });

      test('should provide helpful hints for type mismatches', () {
        final schema = {
          'type': 'object',
          'properties': {
            'enabled': {'type': 'boolean'},
          },
        };

        final data = {'enabled': 'true'};
        final errors =
            StructuredSchemaValidator.validateWithDetails(data, schema);

        expect(errors, hasLength(1));
        expect(errors.first.hint, contains('boolean'));
        expect(errors.first.hint, contains('true'));
        expect(errors.first.hint, contains('false'));
      });

      test('should validate multiple errors', () {
        final schema = {
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
            'count': {'type': 'integer'},
            'enabled': {'type': 'boolean'},
          },
          'required': ['name', 'count'],
        };

        final data = {
          'count': 'not a number',
          'enabled': 'not a boolean',
        };
        final errors =
            StructuredSchemaValidator.validateWithDetails(data, schema);

        expect(errors.length, greaterThan(1));

        // Check for missing name
        expect(
            errors.any((e) =>
                e.path == 'name' &&
                e.type == ValidationErrorType.missingRequired),
            isTrue);

        // Check for invalid count
        expect(
            errors.any((e) =>
                e.path == 'count' &&
                e.type == ValidationErrorType.typeMismatch),
            isTrue);

        // Check for invalid enabled
        expect(
            errors.any((e) =>
                e.path == 'enabled' &&
                e.type == ValidationErrorType.typeMismatch),
            isTrue);
      });
    });
  });
}
