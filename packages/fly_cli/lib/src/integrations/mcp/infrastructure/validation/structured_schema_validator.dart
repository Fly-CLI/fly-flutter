import 'package:fly_mcp/fly_mcp.dart';

/// Structured schema validator with AI-friendly error messages and hints
///
/// Extends [SchemaValidator] with:
/// - Detailed error messages with context
/// - Enum value validation with suggestions
/// - Nested object validation with path information
/// - Type validation with conversion hints
/// - Structured [ValidationError] objects with hints and remediation
///
/// This validator delegates core validation to [SchemaValidator] and enhances
/// error messages via callbacks, eliminating code duplication while providing
/// rich, actionable error feedback for AI assistants.
class StructuredSchemaValidator {
  /// Validates value against a JSON Schema with enhanced error messages
  ///
  /// Returns structured validation errors with hints and suggestions.
  /// Each error includes:
  /// - Field path (e.g., "screenName" or "variables.projectName")
  /// - Error type (missing, type_mismatch, invalid_enum, etc.)
  /// - Expected value description
  /// - Actual value (if available)
  /// - Hint/suggestion for fixing the error
  static List<ValidationError> validateWithDetails(
    Object? value,
    Map<String, Object?> schema, {
    String path = '',
  }) {
    final errors = <ValidationError>[];

    // Use SchemaValidator with callbacks that build ValidationError objects directly
    SchemaValidator.validate(
      value,
      schema,
      path: path,
      onTypeMismatch: (errorPath, expectedType, actualValue) {
        errors.add(ValidationError(
          path: errorPath,
          type: ValidationErrorType.typeMismatch,
          expected: expectedType,
          actual: _getTypeName(actualValue),
          message:
              _buildTypeMismatchMessage(errorPath, expectedType, actualValue),
          hint: _getTypeMismatchHint(expectedType, actualValue),
        ));
        return _buildTypeMismatchMessage(errorPath, expectedType, actualValue);
      },
      onMissingRequired: (field, errorPath) {
        errors.add(ValidationError(
          path: errorPath,
          type: ValidationErrorType.missingRequired,
          expected: 'required field',
          message: _buildMissingFieldMessage(errorPath, field),
          hint: _getMissingFieldHint(field, schema),
        ));
        return _buildMissingFieldMessage(errorPath, field);
      },
      onAdditionalProperty: (field, errorPath) {
        errors.add(ValidationError(
          path: errorPath,
          type: ValidationErrorType.additionalPropertyNotAllowed,
          expected: 'no additional properties',
          message: 'Additional property not allowed: $errorPath',
          hint:
              'Remove this property or check tool schema for allowed properties',
        ));
        return 'Additional property not allowed: $errorPath';
      },
      onNestedError: (errorPath, error) {
        // Nested errors are already captured by recursive calls
        // This callback is just for formatting the path prefix
        return '$errorPath: $error';
      },
    );

    // Handle enum validation (not supported by SchemaValidator)
    errors.addAll(_validateEnum(value, schema, path));

    return errors;
  }

  /// Convert enhanced validation errors to simple string messages
  /// (for backward compatibility)
  static List<String> validate(
    Object? value,
    Map<String, Object?> schema, {
    String path = '',
  }) {
    final detailedErrors = validateWithDetails(value, schema, path: path);
    return detailedErrors.map((e) => e.message).toList();
  }

  /// Validate enum values (not handled by SchemaValidator)
  /// This needs to be called recursively for nested schemas
  static List<ValidationError> _validateEnum(
    Object? value,
    Map<String, Object?> schema,
    String path,
  ) {
    final errors = <ValidationError>[];

    // Only validate enums for string types that pass basic type validation
    final type = schema['type'] as String?;
    if (type != 'string' || value is! String) {
      // For nested objects/arrays, recurse into properties
      if (type == 'object' && value is Map) {
        final props = schema['properties'] as Map<String, Object?>?;
        if (props != null) {
          for (final entry in value.entries) {
            final fieldName = entry.key as String;
            final fieldValue = entry.value;
            final fieldPath = path.isEmpty ? fieldName : '$path.$fieldName';

            if (props.containsKey(fieldName)) {
              final fieldSchema = props[fieldName] as Map<String, Object?>?;
              if (fieldSchema != null) {
                errors
                    .addAll(_validateEnum(fieldValue, fieldSchema, fieldPath));
              }
            }
          }
        }
      } else if (type == 'array' && value is List) {
        final items = schema['items'] as Map<String, Object?>?;
        if (items != null) {
          for (var i = 0; i < value.length; i++) {
            final itemPath = path.isEmpty ? '[$i]' : '$path[$i]';
            errors.addAll(_validateEnum(value[i], items, itemPath));
          }
        }
      }

      return errors;
    }

    // Validate enum for string value
    final enumValues = schema['enum'] as List?;
    if (enumValues != null && !enumValues.contains(value)) {
      final allowedValues = enumValues.map((e) => e.toString()).toList();

      errors.add(ValidationError(
        path: path,
        type: ValidationErrorType.invalidEnum,
        expected: 'one of: ${allowedValues.join(", ")}',
        actual: value,
        message: _buildEnumErrorMessage(path, value, allowedValues),
        hint: _getEnumHint(path, value, allowedValues),
      ));
    }

    return errors;
  }

  // Helper methods for building error messages

  static String _getTypeName(Object? value) {
    if (value == null) return 'null';
    // Normalize type names to lowercase for consistency
    final typeName = value.runtimeType.toString().toLowerCase();
    // Handle common Dart type names
    if (typeName == 'int') return 'integer';
    if (typeName == 'double') return 'number';
    if (typeName == 'bool') return 'boolean';
    if (typeName == 'string') return 'string';
    return typeName;
  }

  static String _buildTypeMismatchMessage(
    String path,
    String expectedType,
    Object? actualValue,
  ) {
    final fieldName = path.split('.').last;
    if (path.isEmpty || path == fieldName) {
      return 'Expected $expectedType for "$fieldName", got ${_getTypeName(actualValue)}';
    }
    return 'Expected $expectedType at path "$path", got ${_getTypeName(actualValue)}';
  }

  static String? _getTypeMismatchHint(String expectedType, Object? value) {
    if (value == null) {
      return 'Provide a value (cannot be null)';
    }

    final valueType = _getTypeName(value);

    // Special handling for boolean type mismatches
    if (expectedType == 'boolean' && value is String) {
      final lowerValue = value.toLowerCase();
      if (lowerValue == 'true' || lowerValue == 'false') {
        return 'Convert string to boolean: Use $lowerValue (without quotes) or ${lowerValue == 'true' ? 'false' : 'true'}';
      }
      return 'Expected boolean (true or false), got string "$value"';
    }

    // Provide type conversion hints
    if (expectedType == 'string' && value is num) {
      return 'Convert number to string: "${value.toString()}"';
    }
    if (expectedType == 'string' && value is bool) {
      return 'Convert boolean to string: "${value.toString()}"';
    }
    if (expectedType == 'number' && value is String) {
      return 'Convert string to number if it represents a numeric value';
    }
    if (expectedType == 'integer' && value is double) {
      return 'Convert double to integer (truncate if needed)';
    }

    return 'Check parameter type - expected $expectedType but got $valueType';
  }

  static String _buildMissingFieldMessage(String path, String field) {
    if (path == field) {
      return 'Missing Required parameter: $field';
    }
    return 'Missing Required field "$field" at path "$path"';
  }

  static String? _getMissingFieldHint(
      String field, Map<String, Object?> schema) {
    final properties = schema['properties'] as Map<String, Object?>?;
    final fieldSchema = properties?[field] as Map<String, Object?>?;
    final description = fieldSchema?['description'] as String?;
    if (description != null) {
      return 'Provide $field: $description';
    }

    // Field-specific hints
    if (field.toLowerCase().contains('confirm')) {
      return 'Provide confirm: true for destructive operations';
    }
    if (field.toLowerCase().contains('name')) {
      return 'Provide $field (must be lowercase)';
    }

    return 'This parameter is required';
  }

  static String _buildEnumErrorMessage(
    String path,
    String value,
    List<String> allowedValues,
  ) {
    final fieldName = path.split('.').last;
    final suggestions = _findSimilarValues(value, allowedValues);

    if (suggestions.isNotEmpty) {
      return 'Invalid enum value "$value" for "$fieldName". Did you mean: ${suggestions.join(", ")}?';
    }

    return 'Invalid enum value "$value" for "$fieldName". Allowed values: ${allowedValues.join(", ")}';
  }

  static String? _getEnumHint(
    String path,
    String value,
    List<String> allowedValues,
  ) {
    final suggestions = _findSimilarValues(value, allowedValues);

    if (suggestions.isNotEmpty) {
      return 'Use one of: ${suggestions.join(", ")}';
    }

    // Check for case sensitivity issues
    final lowerValue = value.toLowerCase();
    final caseInsensitiveMatches = allowedValues
        .where((allowed) => allowed.toLowerCase() == lowerValue)
        .toList();

    if (caseInsensitiveMatches.isNotEmpty) {
      return 'Value is case-sensitive. Use exactly: ${caseInsensitiveMatches.first}';
    }

    return 'Allowed values: ${allowedValues.join(", ")}';
  }

  /// Find similar values using simple string matching
  static List<String> _findSimilarValues(
    String value,
    List<String> allowedValues,
  ) {
    final lowerValue = value.toLowerCase();
    final matches = <String>[];

    // Exact case-insensitive match
    for (final allowed in allowedValues) {
      if (allowed.toLowerCase() == lowerValue) {
        matches.add(allowed);
      }
    }

    // Prefix matches
    if (matches.isEmpty) {
      for (final allowed in allowedValues) {
        if (allowed.toLowerCase().startsWith(lowerValue) ||
            lowerValue.startsWith(allowed.toLowerCase())) {
          matches.add(allowed);
        }
      }
    }

    return matches.take(3).toList(); // Return up to 3 suggestions
  }
}

/// Structured validation error with context and hints
class ValidationError {
  const ValidationError({
    required this.path,
    required this.type,
    required this.expected,
    this.actual,
    required this.message,
    this.hint,
  });

  /// The path to the field with the error (e.g., "screenName" or "variables.projectName")
  final String path;

  /// The type of validation error
  final ValidationErrorType type;

  /// Description of what was expected
  final String expected;

  /// The actual value (if available)
  final Object? actual;

  /// Human-readable error message
  final String message;

  /// Hint or suggestion for fixing the error
  final String? hint;

  /// Convert to simple string (for backward compatibility)
  @override
  String toString() => message;
}

/// Types of validation errors
enum ValidationErrorType {
  /// Missing required field
  missingRequired,

  /// Type mismatch (e.g., expected string, got number)
  typeMismatch,

  /// Invalid enum value
  invalidEnum,

  /// Additional property not allowed
  additionalPropertyNotAllowed,

  /// Other validation errors
  other,
}
