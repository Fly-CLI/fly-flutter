import 'package:dart_mcp/server.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/prompts/prompt_error.dart';
import 'package:mustache_template/mustache.dart';

/// Validator for prompt variables and template syntax
///
/// Provides validation utilities for prompt generation, including
/// variable validation, type checking, and template syntax validation.
class PromptValidator {
  /// Validate required variables are present
  ///
  /// [variables] - Map of variable names to values
  /// [requiredVariables] - List of PromptArgument that are required
  /// [promptId] - The prompt ID for error context
  ///
  /// Throws [PromptError] if any required variable is missing.
  static void validateRequiredVariables(
    Map<String, Object?> variables,
    List<PromptArgument> requiredVariables,
    String? promptId,
  ) {
    for (final arg in requiredVariables) {
      if (arg.required == true && !variables.containsKey(arg.name)) {
        throw PromptError.missingVariable(
          variableName: arg.name,
          promptId: promptId,
          description: arg.description,
        );
      }

      final value = variables[arg.name];
      if (arg.required == true &&
          (value == null || (value is String && value.isEmpty))) {
        throw PromptError.missingVariable(
          variableName: arg.name,
          promptId: promptId,
          description: arg.description,
        );
      }
    }
  }

  /// Validate variable types match expected types
  ///
  /// [variables] - Map of variable names to values
  /// [variableDefinitions] - List of PromptArgument definitions
  /// [promptId] - The prompt ID for error context
  ///
  /// Throws [PromptError] if any variable has incorrect type.
  static void validateVariableTypes(
    Map<String, Object?> variables,
    List<PromptArgument> variableDefinitions,
    String? promptId,
  ) {
    for (final arg in variableDefinitions) {
      final value = variables[arg.name];
      if (value == null) continue;

      // Infer expected type from description or validate common types
      final expectedType = _inferTypeFromDescription(arg.description);
      if (expectedType != null) {
        final actualType = _getValueType(value);
        if (!_isTypeCompatible(actualType, expectedType)) {
          throw PromptError.invalidVariableType(
            variableName: arg.name,
            expectedType: expectedType,
            actualType: actualType,
            promptId: promptId,
          );
        }
      }

      // Additional validation based on description patterns
      final description = arg.description;
      if (description != null &&
          (description.toLowerCase().contains('array') ||
              description.toLowerCase().contains('list'))) {
        if (value is! List) {
          throw PromptError.invalidVariableType(
            variableName: arg.name,
            expectedType: 'List',
            actualType: _getValueType(value),
            promptId: promptId,
          );
        }
      }
    }
  }

  /// Validate variable values meet constraints
  ///
  /// [variableName] - Name of the variable to validate
  /// [value] - Value to validate
  /// [promptId] - The prompt ID for error context
  ///
  /// Throws [PromptError] if value doesn't meet constraints.
  static void validateVariableValue(
    String variableName,
    Object? value,
    String? promptId, {
    List<String>? allowedValues,
    RegExp? pattern,
    int? minLength,
    int? maxLength,
  }) {
    if (value == null) return;

    if (value is String) {
      if (minLength != null && value.length < minLength) {
        throw PromptError.invalidVariableValue(
          variableName: variableName,
          reason: 'Value length must be at least $minLength characters',
          promptId: promptId,
        );
      }

      if (maxLength != null && value.length > maxLength) {
        throw PromptError.invalidVariableValue(
          variableName: variableName,
          reason: 'Value length must be at most $maxLength characters',
          promptId: promptId,
        );
      }

      if (pattern != null && !pattern.hasMatch(value)) {
        throw PromptError.invalidVariableValue(
          variableName: variableName,
          reason: 'Value does not match required pattern',
          promptId: promptId,
        );
      }

      if (allowedValues != null && !allowedValues.contains(value)) {
        throw PromptError.invalidVariableValue(
          variableName: variableName,
          reason: 'Value not in allowed list',
          promptId: promptId,
          allowedValues: allowedValues,
        );
      }
    }

    // Validate enum-like values (for String variables)
    if (value is String &&
        allowedValues != null &&
        !allowedValues.contains(value)) {
      throw PromptError.invalidVariableValue(
        variableName: variableName,
        reason: 'Value must be one of: ${allowedValues.join(", ")}',
        promptId: promptId,
        allowedValues: allowedValues,
      );
    }
  }

  /// Validate template syntax
  ///
  /// [template] - Template string to validate
  /// [templateName] - Name of the template for error context
  ///
  /// Throws [PromptError] if template has syntax errors.
  static void validateTemplateSyntax(String template, String templateName) {
    try {
      // Try to parse the template - this will catch syntax errors
      Template(template, lenient: false);
    } on TemplateException catch (e) {
      throw PromptError.templateSyntaxError(
        templateName: templateName,
        error: e.message,
        line: e.line,
        column: e.column,
      );
    } catch (e) {
      throw PromptError.templateSyntaxError(
        templateName: templateName,
        error: e.toString(),
      );
    }
  }

  /// Validate template can be rendered with provided variables
  ///
  /// [template] - Template string to validate
  /// [templateName] - Name of the template for error context
  /// [variables] - Map of variable names to values
  ///
  /// Throws [PromptError] if template cannot be rendered.
  static void validateTemplateRendering(
    String template,
    String templateName,
    Map<String, dynamic> variables,
  ) {
    try {
      final t = Template(template, lenient: true);
      t.renderString(variables);
    } on TemplateException catch (e) {
      // Extract missing variable from error message if possible
      String? missingVariable;
      if (e.message.toLowerCase().contains('undefined')) {
        // Try to extract variable name from error
        final match = RegExp(r'\{\{([^}]+)\}\}').firstMatch(e.message);
        if (match != null) {
          missingVariable = match.group(1)?.trim();
        }
      }

      throw PromptError.templateRenderingError(
        templateName: templateName,
        error: e.message,
        missingVariable: missingVariable,
        line: e.line,
        column: e.column,
      );
    } catch (e) {
      throw PromptError.templateRenderingError(
        templateName: templateName,
        error: e.toString(),
      );
    }
  }

  /// Validate prompt arguments format
  ///
  /// [argumentsValue] - The arguments value from params
  /// [promptId] - The prompt ID for error context
  ///
  /// Returns a Map of validated arguments.
  ///
  /// Throws [PromptError] if arguments format is invalid.
  static Map<String, Object?> validateArgumentsFormat(
    Object? argumentsValue,
    String? promptId,
  ) {
    if (argumentsValue == null) {
      return {};
    }

    if (argumentsValue is! Map) {
      throw PromptError.invalidArgumentsFormat(
        reason: 'Arguments must be a Map, got ${argumentsValue.runtimeType}',
        promptId: promptId,
      );
    }

    return Map<String, Object?>.from(argumentsValue);
  }

  /// Infer expected type from description
  static String? _inferTypeFromDescription(String? description) {
    if (description == null) return null;

    final desc = description.toLowerCase();
    if (desc.contains('array') || desc.contains('list')) {
      return 'List';
    }
    if (desc.contains('url') ||
        desc.contains('string') ||
        desc.contains('text')) {
      return 'String';
    }
    if (desc.contains('number') ||
        desc.contains('int') ||
        desc.contains('integer')) {
      return 'int';
    }
    if (desc.contains('bool') || desc.contains('boolean')) {
      return 'bool';
    }
    return null;
  }

  /// Get the type name of a value
  static String _getValueType(Object? value) {
    if (value == null) return 'null';
    if (value is String) return 'String';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    if (value is List) return 'List';
    if (value is Map) return 'Map';
    return value.runtimeType.toString();
  }

  /// Check if actual type is compatible with expected type
  static bool _isTypeCompatible(String actualType, String expectedType) {
    if (actualType == expectedType) return true;

    // Allow some type flexibility
    if (expectedType == 'int' &&
        (actualType == 'int' || actualType == 'double')) {
      return true;
    }
    if (expectedType == 'double' &&
        (actualType == 'int' || actualType == 'double')) {
      return true;
    }

    return false;
  }
}
