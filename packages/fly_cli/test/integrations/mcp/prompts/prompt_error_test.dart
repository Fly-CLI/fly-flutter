import 'package:fly_cli/src/integrations/mcp/prompts/prompt_error.dart';
import 'package:test/test.dart';

void main() {
  group('PromptError', () {
    test('should create missingVariable error', () {
      final error = PromptError.missingVariable(
        variableName: 'name',
        promptId: 'fly.scaffold.page',
        description: 'The name of the page to scaffold',
      );

      expect(error.code, 'missing_variable');
      expect(error.category, 'validation');
      expect(error.severity, 'error');
      expect(error.variableName, 'name');
      expect(error.promptId, 'fly.scaffold.page');
      expect(error.hints, isNotEmpty);
      expect(error.remediation, isNotNull);
    });

    test('should create invalidVariableType error', () {
      final error = PromptError.invalidVariableType(
        variableName: 'count',
        expectedType: 'integer',
        actualType: 'string',
        promptId: 'test.prompt',
      );

      expect(error.code, 'invalid_variable_type');
      expect(error.category, 'validation');
      expect(error.variableName, 'count');
      expect(error.context['expected_type'], 'integer');
      expect(error.context['actual_type'], 'string');
    });

    test('should create invalidVariableValue error', () {
      final error = PromptError.invalidVariableValue(
        variableName: 'stateManagement',
        reason: 'Value not in allowed list',
        promptId: 'fly.scaffold.page',
        allowedValues: ['riverpod', 'bloc', 'provider'],
      );

      expect(error.code, 'invalid_variable_value');
      expect(error.category, 'validation');
      expect(error.variableName, 'stateManagement');
      expect(error.context['allowed_values'], isNotNull);
    });

    test('should create templateSyntaxError', () {
      final error = PromptError.templateSyntaxError(
        templateName: 'test_template',
        error: 'Unclosed tag',
        line: 5,
        column: 10,
      );

      expect(error.code, 'template_syntax_error');
      expect(error.category, 'template');
      expect(error.context['line'], 5);
      expect(error.context['column'], 10);
    });

    test('should create templateRenderingError', () {
      final error = PromptError.templateRenderingError(
        templateName: 'test_template',
        error: 'Variable undefined',
        missingVariable: 'name',
        line: 3,
        column: 15,
      );

      expect(error.code, 'template_rendering_error');
      expect(error.category, 'template');
      expect(error.context['missing_variable'], 'name');
    });

    test('should create unknownPromptId error', () {
      final error = PromptError.unknownPromptId(
        promptId: 'invalid.prompt',
        availablePrompts: ['fly.scaffold.page', 'fly.scaffold.feature'],
      );

      expect(error.code, 'unknown_prompt_id');
      expect(error.category, 'not_found');
      expect(error.promptId, 'invalid.prompt');
      expect(error.context['available_prompts'], isNotNull);
    });

    test('should create invalidArgumentsFormat error', () {
      final error = PromptError.invalidArgumentsFormat(
        reason: 'Arguments must be a Map',
        promptId: 'test.prompt',
      );

      expect(error.code, 'invalid_arguments_format');
      expect(error.category, 'validation');
      expect(error.hints, contains('Arguments must be a Map'));
    });

    test('should format error message with hints and remediation', () {
      final error = PromptError.missingVariable(
        variableName: 'name',
        promptId: 'test.prompt',
      );

      final message = error.toString();
      expect(message, contains('Missing required variable'));
      expect(message, contains('Hints:'));
      expect(message, contains('Remediation:'));
    });
  });
}
