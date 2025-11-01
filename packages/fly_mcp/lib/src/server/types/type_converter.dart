import 'package:dart_mcp/server.dart';

import '../validation/protocol_validator.dart';
import 'tool_parameter.dart';
import 'tool_result.dart';

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
  ///
  /// Note: This method is deprecated. Use ProtocolValidator.validateParameters
  /// at the protocol boundary before type conversion instead.
  @Deprecated('Use ProtocolValidator.validateParameters at protocol boundary')
  static List<String> validateTypedModel(
    ToolParameter param,
    ObjectSchema schema,
  ) {
    final json = param.toJson();
    final validationErrors = ProtocolValidator.validateParameters(
      rawJson: json,
      schema: schema,
    );
    return validationErrors.map((e) => e.message).toList();
  }

  /// Validate a typed result model against an ObjectSchema
  ///
  /// [result] - The typed result model to validate
  /// [schema] - The ObjectSchema representing the expected structure
  ///
  /// Returns an empty list if valid, or a list of error messages if invalid.
  ///
  /// Note: This method is deprecated. Use ProtocolValidator.validateResult
  /// for result validation instead.
  @Deprecated('Use ProtocolValidator.validateResult for result validation')
  static List<String> validateTypedResult(
    ToolResult result,
    ObjectSchema schema,
  ) {
    final json = result.toJson();
    final validationErrors = ProtocolValidator.validateResult(
      result: json,
      schema: schema,
    );
    return validationErrors.map((e) => e.message).toList();
  }
}
