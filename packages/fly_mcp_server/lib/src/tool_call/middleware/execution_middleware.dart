import 'dart:async';

import 'package:dart_mcp/server.dart';
import 'package:fly_mcp_server/src/registries.dart';
import 'package:fly_mcp_server/src/tool_call/tool_call_context.dart';
import 'package:fly_mcp_server/src/tool_call/tool_call_middleware.dart';
import 'package:fly_mcp_server/src/validation/size_validator.dart';

/// Middleware that calls the tool handler and validates result size.
///
/// Priority: 60 (runs after timeout)
class ExecutionMiddleware implements ToolCallMiddleware {
  /// Creates execution middleware.
  ExecutionMiddleware({
    required ToolRegistry toolRegistry,
    required SizeValidator sizeValidator,
  })  : _toolRegistry = toolRegistry,
        _sizeValidator = sizeValidator;

  final ToolRegistry _toolRegistry;
  final SizeValidator _sizeValidator;

  @override
  int get priority => 60;

  @override
  Future<CallToolResult> handle(
    ToolCallContext context,
    Future<CallToolResult> Function(ToolCallContext) next,
  ) async {
    // Ensure required fields are set
    if (context.tool == null) {
      throw StateError('Tool must be set before ExecutionMiddleware');
    }

    // Call the tool handler
    final rawResult = await _toolRegistry.call(
      context.request.name,
      context.request.arguments ?? {},
      cancelToken: context.cancelToken,
      progressNotifier: context.progressNotifier,
    );

    // Validate result size
    _sizeValidator.validateResult(rawResult);

    // Update context with raw result
    final updatedContext = context.copyWith(rawResult: rawResult);

    // Continue to next middleware
    return next(updatedContext);
  }
}

