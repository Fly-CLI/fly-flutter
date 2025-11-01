import 'package:dart_mcp/server.dart' hide ValidationError, ValidationErrorType;
import 'package:fly_mcp/src/core/mcp/schema_validator.dart';
import 'package:fly_mcp/src/core/validation/validation_error.dart';

import 'schema_converter.dart';

/// Protocol-level validator for MCP tool parameters and results
///
/// Validates raw JSON at the protocol boundary (before type conversion)
/// to ensure data conforms to the expected JSON Schema.
///
/// This validator:
/// - Validates JSON schema structure
/// - Checks required fields
/// - Validates types
/// - Checks enum values
/// - Provides structured error reporting
///
/// **Usage Pattern:**
/// ```dart
/// // Validate raw JSON before converting to typed parameters
/// final errors = ProtocolValidator.validateParameters(
///   rawJson: mapParams,
///   schema: tool.paramsSchema,
/// );
///
/// if (errors.isNotEmpty) {
///   throw McpError.invalidParams(errors: errors);
/// }
///
/// // Now safe to convert to typed parameters
/// final params = paramsFromJson(mapParams);
/// ```
class ProtocolValidator {
  /// Validate raw JSON parameters against a schema
  ///
  /// [rawJson] - The raw JSON Map to validate (before type conversion)
  /// [schema] - The ObjectSchema representing the expected structure
  ///
  /// Returns a list of validation errors (empty if valid).
  ///
  /// This should be called at the protocol boundary before converting
  /// JSON to typed parameters.
  static List<ValidationError> validateParameters({
    required Map<String, Object?> rawJson,
    required ObjectSchema schema,
  }) {
    // Convert schema to JSON Schema format
    final schemaMap = SchemaConverter.objectSchemaToMap(schema);

    // Check if we have complete type information
    // If types are missing (schema.type is null for primitives), skip type validation
    // and only validate required fields
    final hasAllTypes = SchemaConverter.hasCompleteTypeInformation(schemaMap);

    if (!hasAllTypes) {
      // If types are missing, only validate required fields
      // This prevents false "Expected object" errors when schema.type is not accessible
      return _validateRequiredFieldsOnly(rawJson, schemaMap);
    }

    // Validate using schema validator with structured error callbacks
    return _validateWithDetails(rawJson, schemaMap);
  }

  /// Validate a result against a schema (advisory validation)
  ///
  /// [result] - The result Map to validate
  /// [schema] - The ObjectSchema representing the expected structure
  ///
  /// Returns a list of validation errors (empty if valid).
  ///
  /// Note: Result validation is typically advisory (warnings only)
  /// and should not fail the operation.
  static List<ValidationError> validateResult({
    required Map<String, Object?> result,
    required ObjectSchema schema,
  }) {
    // Convert schema to JSON Schema format
    final schemaMap = SchemaConverter.objectSchemaToMap(schema);

    // Validate using schema validator with structured error callbacks
    return _validateWithDetails(result, schemaMap);
  }

  /// Internal method to validate with structured error details
  static List<ValidationError> _validateWithDetails(
    Object? value,
    Map<String, Object?> schema, {
    String path = '',
  }) {
    final errors = <ValidationError>[];

    // Use SchemaValidator with callbacks that build ValidationError objects
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
        return '$errorPath: $error';
      },
    );

    // Handle enum validation (not supported by SchemaValidator)
    errors.addAll(_validateEnum(value, schema, path));

    return errors;
  }

  /// Validate enum values (not handled by SchemaValidator)
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
          for (final entry in (value as Map).entries) {
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
        message: _buildEnumErrorMessage(path, value as String, allowedValues),
        hint: _getEnumHint(path, value as String, allowedValues),
      ));
    }

    return errors;
  }

  // Helper methods for building error messages

  static String _getTypeName(Object? value) {
    if (value == null) return 'null';
    final typeName = value.runtimeType.toString().toLowerCase();
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

  /// Validates only required fields when schema types are missing
  ///
  /// [params] - The parameters Map to validate
  /// [schemaMap] - The schema Map representation
  ///
  /// Returns a list of validation errors (empty if valid).
  ///
  /// This is a workaround for when schema.type is null for primitive schemas.
  /// When types are missing, we skip type validation and only check required fields.
  static List<ValidationError> _validateRequiredFieldsOnly(
    Map<String, Object?> params,
    Map<String, Object?> schemaMap,
  ) {
    final errors = <ValidationError>[];
    final required = schemaMap['required'] as List<dynamic>?;

    if (required != null) {
      for (final field in required) {
        final fieldName = field.toString();
        if (!params.containsKey(fieldName)) {
          errors.add(ValidationError(
            path: fieldName,
            type: ValidationErrorType.missingRequired,
            expected: 'required field',
            message: 'Missing Required parameter: $fieldName',
            hint: 'Provide $fieldName parameter',
          ));
        }
      }
    }

    return errors;
  }
}
