/// Minimal JSON Schema validator for MCP tool params/results
class SchemaValidator {
  /// Validates value against a JSON Schema
  /// Returns empty list if valid, list of error messages if invalid
  static List<String> validate(
    Object? value,
    Map<String, Object?> schema,
  ) {
    final errors = <String>[];
    final type = schema['type'] as String?;

    if (type == null) {
      return errors; // No type constraint
    }

    switch (type) {
      case 'object':
        if (value is! Map) {
          errors.add('Expected object, got ${value.runtimeType}');
          return errors;
        }
        final props = schema['properties'] as Map<String, Object?>?;
        final required =
            (schema['required'] as List?)?.cast<String>() ?? [];
        final additionalProperties =
            schema['additionalProperties'] as bool? ?? true;

        // Check required fields
        for (final field in required) {
          if (!value.containsKey(field)) {
            errors.add('Missing required field: $field');
          }
        }

        // Validate properties
        if (props != null) {
          for (final entry in value.entries) {
            final fieldName = entry.key;
            final fieldValue = entry.value;

            if (props.containsKey(fieldName)) {
              final fieldSchema =
                  props[fieldName] as Map<String, Object?>?;
              if (fieldSchema != null) {
                errors.addAll(
                  validate(fieldValue, fieldSchema).map(
                    (e) => '\$.$fieldName: $e',
                  ),
                );
              }
            } else if (!additionalProperties) {
              errors.add('Additional property not allowed: $fieldName');
            }
          }
        }
        return errors;

      case 'string':
        if (value is! String) {
          errors.add('Expected string, got ${value.runtimeType}');
        }
        return errors;

      case 'integer':
        if (value is! int) {
          errors.add('Expected integer, got ${value.runtimeType}');
        }
        return errors;

      case 'number':
        if (value is! int && value is! double) {
          errors.add('Expected number, got ${value.runtimeType}');
        }
        return errors;

      case 'boolean':
        if (value is! bool) {
          errors.add('Expected boolean, got ${value.runtimeType}');
        }
        return errors;

      case 'array':
        if (value is! List) {
          errors.add('Expected array, got ${value.runtimeType}');
          return errors;
        }
        final items = schema['items'] as Map<String, Object?>?;
        if (items != null) {
          for (var i = 0; i < value.length; i++) {
            errors.addAll(
              validate(value[i], items).map((e) => '[$i]: $e'),
            );
          }
        }
        return errors;

      default:
        // Unknown type; skip validation
        return errors;
    }
  }
}


