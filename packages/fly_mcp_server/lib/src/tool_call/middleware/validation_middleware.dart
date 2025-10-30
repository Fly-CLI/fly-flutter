import 'dart:async';

import 'package:dart_mcp/server.dart';
import 'package:fly_mcp_server/src/registries.dart';
import 'package:fly_mcp_server/src/tool_call/tool_call_context.dart';
import 'package:fly_mcp_server/src/tool_call/tool_call_middleware.dart';
import 'package:fly_mcp_server/src/validation/size_validator.dart';

/// Middleware that validates request size and resolves tool definition.
///
/// Priority: 10 (runs early in the pipeline)
class ValidationMiddleware implements ToolCallMiddleware {
  /// Creates validation middleware.
  ValidationMiddleware({
    required ToolRegistry toolRegistry,
    required SizeValidator sizeValidator,
  })  : _toolRegistry = toolRegistry,
        _sizeValidator = sizeValidator;

  final ToolRegistry _toolRegistry;
  final SizeValidator _sizeValidator;

  @override
  int get priority => 10;

  @override
  Future<CallToolResult> handle(
    ToolCallContext context,
    Future<CallToolResult> Function(ToolCallContext) next,
  ) async {
    // Validate size before processing
    _sizeValidator.validateParameters(context.request.arguments ?? {});

    // Get tool definition
    final tool = _toolRegistry.getTool(context.request.name);
    if (tool == null) {
      return CallToolResult(
        isError: true,
        content: [
          TextContent(text: 'Tool not found: ${context.request.name}')
        ],
      );
    }

    // Get metadata
    final metadata = _toolRegistry.getMetadata(context.request.name);

    // Update context with tool and metadata
    final updatedContext = context.copyWith(
      tool: tool,
      metadata: metadata,
    );

    // Continue to next middleware
    return next(updatedContext);
  }
}

