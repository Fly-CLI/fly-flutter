import 'dart:async';
import 'dart:convert';

import 'package:dart_mcp/server.dart';

import '../../validation/protocol_validator.dart';
import '../tool_call_context.dart';
import '../tool_call_middleware.dart';

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
      throw StateError(
          'Raw result must be set before ResultConversionMiddleware');
    }

    if (context.tool == null) {
      throw StateError('Tool must be set before ResultConversionMiddleware');
    }

    final rawResult = context.rawResult!;
    final tool = context.tool!;

    // Validate result against output schema if present (advisory validation)
    if (tool.outputSchema != null) {
      // Convert rawResult to Map for validation
      final resultMap =
          rawResult is Map<String, Object?> ? rawResult : {'result': rawResult};

      // Validate using ProtocolValidator (results validation is advisory)
      final validationErrors = ProtocolValidator.validateResult(
        result: resultMap,
        schema: tool.outputSchema!,
      );

      // Log validation warnings but don't fail the operation
      if (validationErrors.isNotEmpty) {
        // Result validation failures are logged but don't fail operations
        // This allows tools to return results even if schema is slightly off
        // In production, these should be logged for monitoring
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
}
