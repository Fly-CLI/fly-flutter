import 'package:dart_mcp/server.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/prompts/prompt_validator.dart';
import 'package:test/test.dart';

void main() {
  group('MCP Prompt Generation Integration Tests', () {
    group('prompt validator', () {
      test('should validate required variables', () {
        final variables = {'name': 'test'};
        final required = [
          PromptArgument(name: 'name', description: 'Name', required: true),
          PromptArgument(
              name: 'optional', description: 'Optional', required: false),
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

      test('should validate variable types', () {
        final variables = {
          'name': 'test',
          'count': 5,
          'items': ['a', 'b'],
        };
        final definitions = [
          PromptArgument(
              name: 'name', description: 'Name (string)', required: false),
          PromptArgument(
              name: 'count', description: 'Count (number)', required: false),
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

      test('should validate variable values', () {
        expect(
          () => PromptValidator.validateVariableValue(
            'name',
            'valid_name',
            'test.prompt',
            pattern: RegExp(r'^[a-z][a-z0-9_]*$'),
            minLength: 3,
            maxLength: 50,
          ),
          returnsNormally,
        );
      });
    });
  });
}
