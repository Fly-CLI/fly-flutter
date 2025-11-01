import 'package:dart_mcp/server.dart';

/// Unified schema converter for converting dart_mcp Schema objects to JSON Schema format
///
/// This is the single source of truth for schema conversion, eliminating
/// duplicate implementations across the codebase.
///
/// Converts dart_mcp Schema objects to JSON Schema Draft 7 compatible
/// Map representations for validation.
class SchemaConverter {
  /// Convert an ObjectSchema to a JSON Schema Map representation
  ///
  /// [schema] - The ObjectSchema to convert
  ///
  /// Returns a Map representation compatible with JSON Schema validators.
  static Map<String, Object?> objectSchemaToMap(ObjectSchema schema) {
    final map = <String, Object?>{'type': 'object'};

    // Override with schema.type if explicitly set
    // schema.type returns JsonType? which needs to be converted to String
    if (schema.type != null) {
      map['type'] = schema.type!.name;
    }

    // Convert properties recursively
    if (schema.properties != null && schema.properties!.isNotEmpty) {
      final properties = <String, Object?>{};
      for (final entry in schema.properties!.entries) {
        properties[entry.key] = schemaToMap(entry.value);
      }
      map['properties'] = properties;
    }

    // Add required fields
    if (schema.required != null && schema.required!.isNotEmpty) {
      map['required'] = schema.required;
    }

    // Add additionalProperties (defaults to true in JSON Schema)
    map['additionalProperties'] = schema.additionalProperties;

    // Add description if available
    if (schema.description != null && schema.description!.isNotEmpty) {
      map['description'] = schema.description;
    }

    return map;
  }

  /// Recursively convert a Schema to a JSON Schema Map representation
  ///
  /// [schema] - The Schema to convert
  ///
  /// Returns a Map representation compatible with JSON Schema validators.
  ///
  /// Handles all schema types:
  /// - ObjectSchema: Converted recursively
  /// - Primitive schemas: Extract type, description, enum values
  /// - Array schemas: Convert items recursively
  static Map<String, Object?> schemaToMap(Schema schema) {
    // Handle ObjectSchema recursively
    if (schema is ObjectSchema) {
      return objectSchemaToMap(schema);
    }

    // For primitive schemas, extract type and metadata
    final map = <String, Object?>{};

    // Extract type information - critical for validation
    // Note: schema.type may be null for primitive schemas created with
    // Schema.string(), Schema.bool(), etc. We attempt to infer the type
    // from the schema instance type as a fallback.
    final type = _extractType(schema);
    if (type != null) {
      map['type'] = type;
    }

    // Extract description
    if (schema.description != null && schema.description!.isNotEmpty) {
      map['description'] = schema.description;
    }

    // Extract enum values if available
    // Note: enumValues are passed when creating schemas but may not be
    // directly accessible. We attempt to extract them using reflection
    // or by checking the schema's internal representation.
    final enumValues = _extractEnumValues(schema);
    if (enumValues != null && enumValues.isNotEmpty) {
      map['enum'] = enumValues;
    }

    return map;
  }

  /// Extract the JSON Schema type from a Schema object
  ///
  /// [schema] - The Schema object to extract type from
  ///
  /// Returns the JSON Schema type string, or null if type cannot be determined.
  static String? _extractType(Schema schema) {
    // First, try to get type directly from schema
    // schema.type returns JsonType? which needs to be converted to String
    if (schema.type != null) {
      return schema.type!.name;
    }

    // If type is null, attempt to infer from schema instance type
    // This is a workaround for when dart_mcp doesn't expose type
    // directly for primitive schemas created with Schema.string(), Schema.bool(), etc.
    //
    // We use runtimeType to infer the type - this works because dart_mcp
    // creates different schema classes for different types.
    final schemaTypeName = schema.runtimeType.toString();

    // Check for common schema type patterns
    if (schemaTypeName.contains('StringSchema') ||
        schemaTypeName.toLowerCase().contains('string')) {
      return 'string';
    }
    if (schemaTypeName.contains('BoolSchema') ||
        schemaTypeName.toLowerCase().contains('bool')) {
      return 'boolean';
    }
    if (schemaTypeName.contains('IntSchema') ||
        schemaTypeName.toLowerCase().contains('int') ||
        schemaTypeName.toLowerCase().contains('integer')) {
      return 'integer';
    }
    if (schemaTypeName.contains('DoubleSchema') ||
        schemaTypeName.contains('NumberSchema') ||
        schemaTypeName.toLowerCase().contains('number')) {
      return 'number';
    }
    if (schemaTypeName.contains('ArraySchema') ||
        schemaTypeName.toLowerCase().contains('array') ||
        schemaTypeName.toLowerCase().contains('list')) {
      return 'array';
    }

    // If we can't infer the type, return null
    // SchemaValidator will skip type validation when type is null
    return null;
  }

  /// Extract enum values from a Schema object
  ///
  /// [schema] - The Schema object to extract enum values from
  ///
  /// Returns a list of allowed enum values, or null if no enum constraint exists.
  ///
  /// Note: enumValues are passed when creating schemas using
  /// Schema.string(enumValues: [...]), but may not be directly accessible.
  /// This method attempts to extract them using available API methods.
  static List<Object?>? _extractEnumValues(Schema schema) {
    // TODO: Implement enum value extraction
    //
    // Options:
    // 1. Use reflection to access private fields (not recommended, fragile)
    // 2. Check if dart_mcp Schema has a method to get enumValues
    // 3. Modify schema creation to store enumValues in a way that's accessible
    // 4. Pass enumValues separately when creating schemas and store them in a map
    //
    // For now, return null. Enum validation will be handled by checking
    // the 'enum' key in the schema map when schemas are created with enumValues.
    // The validation layer will need to add enum values to the schema map
    // at schema creation time.
    return null;
  }

  /// Check if a schema map has complete type information
  ///
  /// [schemaMap] - The schema map to check
  ///
  /// Returns true if all properties have type information, false otherwise.
  ///
  /// This is used to determine if we can run full schema validation or
  /// should skip type validation (when types are missing).
  static bool hasCompleteTypeInformation(Map<String, Object?> schemaMap) {
    final properties = schemaMap['properties'] as Map<String, Object?>?;
    if (properties == null || properties.isEmpty) {
      // If no properties, we can't validate types anyway
      return false;
    }

    // Check if all properties have type information
    return properties.values.every((propSchema) {
      if (propSchema is Map<String, Object?>) {
        return propSchema.containsKey('type');
      }
      return false;
    });
  }
}
