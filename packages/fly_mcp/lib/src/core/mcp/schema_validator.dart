/// Minimal JSON Schema validator for MCP tool params/results
///
/// Provides extensible validation with optional callbacks for custom error formatting.
/// Can be extended via callbacks without requiring inheritance.
class SchemaValidator {
  /// Validates value against a JSON Schema
  ///
  /// Returns empty list if valid, list of error messages if invalid.
  ///
  /// [value] - The value to validate
  /// [schema] - The JSON Schema to validate against
  /// [path] - Current path in nested objects (for error reporting)
  /// [onTypeMismatch] - Optional callback for custom type mismatch error formatting
  /// [onMissingRequired] - Optional callback for custom missing required field error formatting
  /// [onAdditionalProperty] - Optional callback for custom additional property error formatting
  /// [onNestedError] - Optional callback for custom nested error path formatting
  ///
  /// Example:
  /// ```dart
  /// final errors = SchemaValidator.validate(
  ///   value,
  ///   schema,
  ///   path: 'root',
  ///   onTypeMismatch: (path, type, value) => 'Custom error at $path',
  /// );
  /// ```
  static List<String> validate(
    Object? value,
    Map<String, Object?> schema, {
    String path = '',
    String Function(String path, String expectedType, Object? actualValue)?
        onTypeMismatch,
    String Function(String field, String path)? onMissingRequired,
    String Function(String field, String path)? onAdditionalProperty,
    String Function(String path, String error)? onNestedError,
  }) {
    final errors = <String>[];
    final type = schema['type'] as String?;

    if (type == null) {
      return errors; // No type constraint
    }

    switch (type) {
      case 'object':
        if (value is! Map) {
          final errorMessage = onTypeMismatch != null
              ? onTypeMismatch(path.isEmpty ? 'root' : path, 'object', value)
              : 'Expected object, got ${value.runtimeType}';
          errors.add(errorMessage);
          return errors;
        }
        final props = schema['properties'] as Map<String, Object?>?;
        final required = (schema['required'] as List?)?.cast<String>() ?? [];
        final additionalProperties =
            schema['additionalProperties'] as bool? ?? true;

        // Check required fields
        for (final field in required) {
          if (!value.containsKey(field)) {
            final fieldPath = path.isEmpty ? field : '$path.$field';
            final errorMessage = onMissingRequired != null
                ? onMissingRequired(field, fieldPath)
                : 'Missing required field: $field';
            errors.add(errorMessage);
          }
        }

        // Validate properties
        if (props != null) {
          for (final entry in value.entries) {
            final fieldName = entry.key as String;
            final fieldValue = entry.value;
            final fieldPath = path.isEmpty ? fieldName : '$path.$fieldName';

            if (props.containsKey(fieldName)) {
              final fieldSchema = props[fieldName] as Map<String, Object?>?;
              if (fieldSchema != null) {
                final nestedErrors = validate(
                  fieldValue,
                  fieldSchema,
                  path: fieldPath,
                  onTypeMismatch: onTypeMismatch,
                  onMissingRequired: onMissingRequired,
                  onAdditionalProperty: onAdditionalProperty,
                  onNestedError: onNestedError,
                );

                if (onNestedError != null) {
                  errors.addAll(
                      nestedErrors.map((e) => onNestedError(fieldPath, e)));
                } else {
                  errors.addAll(nestedErrors.map((e) => '$fieldPath: $e'));
                }
              }
            } else if (!additionalProperties) {
              final errorMessage = onAdditionalProperty != null
                  ? onAdditionalProperty(fieldName, fieldPath)
                  : 'Additional property not allowed: $fieldName';
              errors.add(errorMessage);
            }
          }
        }
        return errors;

      case 'string':
        if (value is! String) {
          final errorMessage = onTypeMismatch != null
              ? onTypeMismatch(path.isEmpty ? 'root' : path, 'string', value)
              : 'Expected string, got ${value.runtimeType}';
          errors.add(errorMessage);
        }
        return errors;

      case 'integer':
        if (value is! int) {
          final errorMessage = onTypeMismatch != null
              ? onTypeMismatch(path.isEmpty ? 'root' : path, 'integer', value)
              : 'Expected integer, got ${value.runtimeType}';
          errors.add(errorMessage);
        }
        return errors;

      case 'number':
        if (value is! int && value is! double) {
          final errorMessage = onTypeMismatch != null
              ? onTypeMismatch(path.isEmpty ? 'root' : path, 'number', value)
              : 'Expected number, got ${value.runtimeType}';
          errors.add(errorMessage);
        }
        return errors;

      case 'boolean':
        if (value is! bool) {
          final errorMessage = onTypeMismatch != null
              ? onTypeMismatch(path.isEmpty ? 'root' : path, 'boolean', value)
              : 'Expected boolean, got ${value.runtimeType}';
          errors.add(errorMessage);
        }
        return errors;

      case 'array':
        if (value is! List) {
          final errorMessage = onTypeMismatch != null
              ? onTypeMismatch(path.isEmpty ? 'root' : path, 'array', value)
              : 'Expected array, got ${value.runtimeType}';
          errors.add(errorMessage);
          return errors;
        }
        final items = schema['items'] as Map<String, Object?>?;
        if (items != null) {
          for (var i = 0; i < value.length; i++) {
            final itemPath = path.isEmpty ? '[$i]' : '$path[$i]';
            final itemErrors = validate(
              value[i],
              items,
              path: itemPath,
              onTypeMismatch: onTypeMismatch,
              onMissingRequired: onMissingRequired,
              onAdditionalProperty: onAdditionalProperty,
              onNestedError: onNestedError,
            );

            if (onNestedError != null) {
              errors.addAll(itemErrors.map((e) => onNestedError(itemPath, e)));
            } else {
              errors.addAll(itemErrors.map((e) => '$itemPath: $e'));
            }
          }
        }
        return errors;

      default:
        // Unknown type; skip validation
        return errors;
    }
  }
}
