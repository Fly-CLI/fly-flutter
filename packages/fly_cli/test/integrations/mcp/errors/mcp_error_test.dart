import 'package:fly_cli/src/integrations/mcp/infrastructure/errors/mcp_error.dart';
import 'package:test/test.dart';

void main() {
  group('McpError', () {
    test('should create invalidParams error', () {
      final error = McpError.invalidParams(
        tool: 'fly.template.apply',
        errors: ['Missing required parameter: templateId'],
        context: {
          'template_id': '',
        },
      );

      expect(error.errorData['tool'], 'fly.template.apply');
      expect(error.errorData['errors'], isA<List>());
      expect((error.errorData['errors'] as List), hasLength(1));
      expect(error.errorData['hint'], isNotNull);
      expect(error.errorData['remediation'], isNotNull);
    });

    test('should create templateError', () {
      final error = McpError.templateError(
        templateId: 'invalid_template',
        error: 'Template not found',
        variables: {'projectName': 'test'},
        context: {
          'available_templates': ['fly_foundation'],
        },
      );

      expect(error.errorData['template_id'], 'invalid_template');
      expect(error.errorData['error'], 'Template not found');
      final hints = error.errorData['remediation'] as List?;
      expect(hints, isNotNull);
    });

    test('should create screenNameValidation error', () {
      final error = McpError.screenNameValidation(
        screenName: 'Home',
        context: {
          'suggestions': ['home'],
        },
      );

      expect(error.errorData['provided_name'], 'Home');
      expect(error.errorData['suggested_name'], 'home');
      expect(error.errorData['hint'], isNotNull);
      expect(error.errorData['remediation'], isNotNull);
    });

    test('should create validationError', () {
      final error = McpError.validationError(
        field: 'screenName',
        value: 'Home Screen!',
        reason: 'Invalid characters in screen name',
        context: {
          'additional_context': 'test',
        },
      );

      expect(error.errorData['field'], 'screenName');
      expect(error.errorData['value'], 'Home Screen!');
      expect(error.errorData['reason'], 'Invalid characters in screen name');
      expect(error.errorData['hint'], isNotNull);
    });

    test('should include field errors in context', () {
      final error = McpError.invalidParams(
        tool: 'fly.generate.screen',
        errors: [
          'Missing required parameter: screenName',
          'Invalid value for screenType',
        ],
        context: {
          'field_errors': {
            'screenName': {
              'type': 'missing_required',
              'message': 'Required parameter is missing',
            },
            'screenType': {
              'type': 'invalid_enum',
              'message': 'Invalid enum value',
              'allowed': ['list', 'detail', 'form'],
            },
          },
        },
      );

      expect(error.errorData['field_errors'], isNotNull);
      final fieldErrors =
          error.errorData['field_errors'] as Map<String, Object?>;
      expect(fieldErrors['screenName'], isNotNull);
      expect(fieldErrors['screenType'], isNotNull);
    });

    test('should format error message correctly', () {
      final error = McpError.invalidParams(
        tool: 'test.tool',
        errors: ['Error 1', 'Error 2'],
      );

      final message = error.toString();
      expect(message, contains('test.tool'));
      expect(error.errorData['errors'], isNotNull);
    });
  });
}
