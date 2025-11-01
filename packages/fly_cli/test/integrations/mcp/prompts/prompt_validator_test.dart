import 'package:dart_mcp/server.dart';
import 'package:fly_cli/src/integrations/mcp/prompts/prompt_error.dart';
import 'package:fly_cli/src/integrations/mcp/prompts/prompt_validator.dart';
import 'package:test/test.dart';

void main() {
  group('PromptValidator', () {
    group('validateRequiredVariables', () {
      test('should pass when all required variables are present', () {
        final variables = {'name': 'test', 'count': 5};
        final required = [
          PromptArgument(name: 'name', description: 'Name', required: true),
          PromptArgument(name: 'count', description: 'Count', required: false),
        ];

        expect(
          () => PromptValidator.validateRequiredVariables(
            variables,
            required,
            'test.prompt',
          ),
          returnsNormally,
        );
      });

      test('should throw when required variable is missing', () {
        final variables = {'count': 5};
        final required = [
          PromptArgument(name: 'name', description: 'Name', required: true),
        ];

        expect(
          () => PromptValidator.validateRequiredVariables(
            variables,
            required,
            'test.prompt',
          ),
          throwsA(isA<PromptError>()),
        );
      });

      test('should throw when required variable is null', () {
        final variables = {'name': null};
        final required = [
          PromptArgument(name: 'name', description: 'Name', required: true),
        ];

        expect(
          () => PromptValidator.validateRequiredVariables(
            variables,
            required,
            'test.prompt',
          ),
          throwsA(isA<PromptError>()),
        );
      });

      test('should throw when required variable is empty string', () {
        final variables = {'name': ''};
        final required = [
          PromptArgument(name: 'name', description: 'Name', required: true),
        ];

        expect(
          () => PromptValidator.validateRequiredVariables(
            variables,
            required,
            'test.prompt',
          ),
          throwsA(isA<PromptError>()),
        );
      });
    });

    group('validateVariableTypes', () {
      test('should pass when types match', () {
        final variables = {
          'name': 'test',
          'count': 5,
          'enabled': true,
          'items': ['a', 'b'],
        };
        final definitions = [
          PromptArgument(
              name: 'name', description: 'Name (string)', required: false),
          PromptArgument(
              name: 'count', description: 'Count (number)', required: false),
          PromptArgument(
              name: 'enabled',
              description: 'Enabled (boolean)',
              required: false),
          PromptArgument(
              name: 'items', description: 'Items (array)', required: false),
        ];

        expect(
          () => PromptValidator.validateVariableTypes(
            variables,
            definitions,
            'test.prompt',
          ),
          returnsNormally,
        );
      });

      test('should throw when type mismatch', () {
        final variables = {'count': 'not a number'};
        final definitions = [
          PromptArgument(
              name: 'count', description: 'Count (number)', required: false),
        ];

        expect(
          () => PromptValidator.validateVariableTypes(
            variables,
            definitions,
            'test.prompt',
          ),
          throwsA(isA<PromptError>()),
        );
      });

      test('should validate array types', () {
        final variables = {'items': 'not an array'};
        final definitions = [
          PromptArgument(
              name: 'items', description: 'Items (array)', required: false),
        ];

        expect(
          () => PromptValidator.validateVariableTypes(
            variables,
            definitions,
            'test.prompt',
          ),
          throwsA(isA<PromptError>()),
        );
      });
    });

    group('validateVariableValue', () {
      test('should validate minLength constraint', () {
        expect(
          () => PromptValidator.validateVariableValue(
            'name',
            'ab', // Too short
            'test.prompt',
            minLength: 3,
          ),
          throwsA(isA<PromptError>()),
        );
      });

      test('should validate maxLength constraint', () {
        expect(
          () => PromptValidator.validateVariableValue(
            'name',
            'very long name that exceeds limit',
            'test.prompt',
            maxLength: 10,
          ),
          throwsA(isA<PromptError>()),
        );
      });

      test('should validate pattern constraint', () {
        expect(
          () => PromptValidator.validateVariableValue(
            'name',
            'Invalid-Name', // Contains hyphen
            'test.prompt',
            pattern: RegExp(r'^[a-z][a-z0-9_]*$'),
          ),
          throwsA(isA<PromptError>()),
        );
      });

      test('should validate allowed values', () {
        expect(
          () => PromptValidator.validateVariableValue(
            'state',
            'invalid',
            'test.prompt',
            allowedValues: ['riverpod', 'bloc', 'provider'],
          ),
          throwsA(isA<PromptError>()),
        );
      });

      test('should pass when all constraints are met', () {
        expect(
          () => PromptValidator.validateVariableValue(
            'name',
            'valid_name',
            'test.prompt',
            pattern: RegExp(r'^[a-z][a-z0-9_]*$'),
            minLength: 5,
            maxLength: 50,
          ),
          returnsNormally,
        );
      });
    });

    group('validateArgumentsFormat', () {
      test('should return empty map when arguments is null', () {
        final result =
            PromptValidator.validateArgumentsFormat(null, 'test.prompt');
        expect(result, isEmpty);
      });

      test('should return map when arguments is valid map', () {
        final arguments = {'name': 'test', 'count': 5};
        final result =
            PromptValidator.validateArgumentsFormat(arguments, 'test.prompt');
        expect(result, equals(arguments));
      });

      test('should throw when arguments is not a map', () {
        expect(
          () => PromptValidator.validateArgumentsFormat(
              'not a map', 'test.prompt'),
          throwsA(isA<PromptError>()),
        );
      });
    });
  });
}
