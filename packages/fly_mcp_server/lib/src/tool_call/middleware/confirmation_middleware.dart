import 'dart:async';

import 'package:dart_mcp/server.dart';
import 'package:fly_mcp_server/src/tool_call/tool_call_context.dart';
import 'package:fly_mcp_server/src/tool_call/tool_call_middleware.dart';

/// Middleware that checks if tool requires confirmation and validates it.
///
/// Priority: 20 (runs after validation)
class ConfirmationMiddleware implements ToolCallMiddleware {
  @override
  int get priority => 20;

  @override
  Future<CallToolResult> handle(
    ToolCallContext context,
    Future<CallToolResult> Function(ToolCallContext) next,
  ) async {
    // Check confirmation requirement
    if (context.metadata?.requiresConfirmation ?? false) {
      final confirmed = (context.request.arguments?['confirm'] as bool?) ?? false;
      if (!confirmed) {
        return CallToolResult(
          isError: true,
          content: [
            TextContent(
              text: 'Confirmation required for tool: ${context.request.name}'
            )
          ],
        );
      }
    }

    // Continue to next middleware
    return next(context);
  }
}

