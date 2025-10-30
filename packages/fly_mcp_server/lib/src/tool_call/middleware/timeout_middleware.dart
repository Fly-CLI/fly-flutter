import 'dart:async';

import 'package:dart_mcp/server.dart';
import 'package:fly_mcp_server/src/timeout_manager.dart';
import 'package:fly_mcp_server/src/tool_call/tool_call_context.dart';
import 'package:fly_mcp_server/src/tool_call/tool_call_middleware.dart';

/// Middleware that wraps execution in timeout manager.
///
/// Priority: 50 (runs after concurrency)
class TimeoutMiddleware implements ToolCallMiddleware {
  @override
  int get priority => 50;

  @override
  Future<CallToolResult> handle(
    ToolCallContext context,
    Future<CallToolResult> Function(ToolCallContext) next,
  ) async {
    // Ensure timeout is set
    final timeout = context.timeout;
    if (timeout == null) {
      throw StateError('Timeout must be set before TimeoutMiddleware');
    }

    // Wrap execution in timeout manager
    return await TimeoutManager.withTimeout(
      () async => next(context),
      timeout: timeout,
      operationName: context.request.name,
    );
  }
}

