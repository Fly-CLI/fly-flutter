import 'dart:async';
import 'dart:convert';

import 'package:dart_mcp/server.dart';
import 'package:fly_mcp_core/fly_mcp_core.dart';
import 'package:fly_mcp_server/src/tool_call/tool_call_context.dart';
import 'package:fly_mcp_server/src/tool_call/tool_call_middleware.dart';
import 'package:fly_mcp_server/src/types/type_converter.dart';

/// Middleware that converts raw result to CallToolResult with structured content.
///
/// Priority: 70 (runs after execution)
class ResultConversionMiddleware implements ToolCallMiddleware {
  @override
  int get priority => 70;

  @override
  Future<CallToolResult> handle(
    ToolCallContext context,
    Future<CallToolResult> Function(ToolCallContext) next,
  ) async {
    // Ensure raw result is set
    if (context.rawResult == null) {
      throw StateError('Raw result must be set before ResultConversionMiddleware');
    }

    if (context.tool == null) {
      throw StateError('Tool must be set before ResultConversionMiddleware');
    }

    final rawResult = context.rawResult!;
    final tool = context.tool!;

    // Validate result against output schema if present
    if (tool.outputSchema != null) {
      // Convert rawResult to Map for validation
      final resultMap = rawResult is Map<String, Object?>
          ? rawResult
          : {'result': rawResult};

      // Convert ObjectSchema to Map format for validation
      final schemaMap = _objectSchemaToMap(tool.outputSchema!);

      // Validate using SchemaValidator
      final validationErrors = SchemaValidator.validate(resultMap, schemaMap);
      if (validationErrors.isNotEmpty) {
        throw StateError(
          'Result schema validation failed: ${validationErrors.join('; ')}',
        );
      }
    }

    // Check if tool has an output schema - if so, return structured content
    final hasOutputSchema = tool.outputSchema != null;

    // Convert result to appropriate format
    CallToolResult result;
    if (hasOutputSchema) {
      // Tool has output schema - must return structured content
      if (rawResult is Map<String, Object?>) {
        // Result is already a Map, use it as structured content
        result = CallToolResult(
          content: [
            TextContent(text: jsonEncode(rawResult))
          ], // Keep text for compatibility
          structuredContent: rawResult,
        );
      } else {
        // Result is not a Map but tool has outputSchema
        // Convert to Map format
        final resultJson = jsonEncode(rawResult);
        result = CallToolResult(
          content: [TextContent(text: resultJson)],
          structuredContent: {'result': rawResult},
        );
      }
    } else {
      // No output schema, return as text content only
      final resultJson = jsonEncode(rawResult);
      result = CallToolResult(
        content: [TextContent(text: resultJson)],
      );
    }

    // Return converted result directly (this is the final step in normal flow)
    // Logging middleware will wrap this if needed
    return result;
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
  static Map<String, Object?> _schemaToMap(Schema schema) {
    // If it's an ObjectSchema, handle it recursively
    if (schema is ObjectSchema) {
      return _objectSchemaToMap(schema);
    }

    // For other schema types, create a basic representation
    final map = <String, Object?>{};
    
    // Add description if available
    final description = schema.description;
    if (description != null && description.isNotEmpty) {
      map['description'] = description;
    }

    // For non-ObjectSchema schemas, we can't easily determine the type
    // from the Schema API, so we'll return a minimal map
    // The actual type checking will be done at validation time
    return map;
  }
}

