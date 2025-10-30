import 'package:dart_mcp/server.dart';
import 'package:fly_mcp_core/fly_mcp_core.dart';
import 'package:fly_mcp_server/src/types/tool_parameter.dart';
import 'package:fly_mcp_server/src/types/tool_result.dart';

/// Utilities for converting between typed models and Map representations
/// and for validating typed models against ObjectSchema.
class TypeConverter {
  /// Convert a Map to a typed parameter model using a factory function
  /// 
  /// [json] - The Map representation to convert
  /// [factory] - Factory function that creates an instance of T from a Map
  /// 
  /// Returns an instance of type T created from the Map.
  static T fromJson<T extends ToolParameter>(
    Map<String, Object?> json,
    T Function(Map<String, Object?>) factory,
  ) {
    return factory(json);
  }

  /// Convert a ToolParameter to its Map representation
  /// 
  /// [param] - The typed parameter model to convert
  /// 
  /// Returns the Map representation of the parameter.
  static Map<String, Object?> toJson(ToolParameter param) {
    return param.toJson();
  }

  /// Validate a typed parameter model against an ObjectSchema
  /// 
  /// [param] - The typed parameter model to validate
  /// [schema] - The ObjectSchema representing the expected structure
  /// 
  /// Returns an empty list if valid, or a list of error messages if invalid.
  static List<String> validateTypedModel(
    ToolParameter param,
    ObjectSchema schema,
  ) {
    final json = param.toJson();
    final schemaMap = _objectSchemaToMap(schema);
    return SchemaValidator.validate(json, schemaMap);
  }

  /// Validate a typed result model against an ObjectSchema
  /// 
  /// [result] - The typed result model to validate
  /// [schema] - The ObjectSchema representing the expected structure
  /// 
  /// Returns an empty list if valid, or a list of error messages if invalid.
  static List<String> validateTypedResult(
    ToolResult result,
    ObjectSchema schema,
  ) {
    final json = result.toJson();
    final schemaMap = _objectSchemaToMap(schema);
    return SchemaValidator.validate(json, schemaMap);
  }

  /// Convert an ObjectSchema to a Map representation for validation
  /// 
  /// [schema] - The ObjectSchema to convert
  /// 
  /// Returns a Map representation compatible with SchemaValidator.
  static Map<String, Object?> _objectSchemaToMap(ObjectSchema schema) {
    final map = <String, Object?>{'type': 'object'};

    // Convert properties
    final propertiesMap = schema.properties;
    if (propertiesMap != null && propertiesMap.isNotEmpty) {
      final properties = <String, Object?>{};
      for (final entry in propertiesMap.entries) {
        properties[entry.key] = _schemaToMap(entry.value);
      }
      map['properties'] = properties;
    }

    // Add required fields
    final requiredList = schema.required;
    if (requiredList != null && requiredList.isNotEmpty) {
      map['required'] = requiredList;
    }

    // Add additionalProperties
    map['additionalProperties'] = schema.additionalProperties;

    return map;
  }

  /// Convert a Schema (from dart_mcp) to a Map representation
  /// 
  /// [schema] - The Schema to convert
  /// 
  /// Returns a Map representation compatible with SchemaValidator.
  /// 
  /// Note: This is a simplified conversion that handles ObjectSchema properly
  /// and falls back to a basic type representation for other schemas.
  static Map<String, Object?> _schemaToMap(Schema schema) {
    // If it's an ObjectSchema, handle it recursively
    if (schema is ObjectSchema) {
      return _objectSchemaToMap(schema);
    }

    // For other schema types, create a basic representation
    // Since dart_mcp Schema is opaque, we'll create a minimal map
    // The actual validation will work with the JSON representation
    final map = <String, Object?>{};
    
    // Add description if available
    final description = schema.description;
    if (description != null && description.isNotEmpty) {
      map['description'] = description;
    }

    // For non-ObjectSchema schemas, we can't easily determine the type
    // from the Schema API, so we'll return a minimal map
    // The actual type checking will be done at validation time
    // This is acceptable since we primarily validate ObjectSchema instances
    return map;
  }
}

