import 'dart:async';

import 'package:dart_mcp/server.dart';
import 'package:fly_mcp_server/src/tool_call/tool_call_context.dart';

/// Base class for tool call middleware.
///
/// Each middleware handles one concern and can:
/// - Modify the context using [context.copyWith()]
/// - Short-circuit execution by returning early (not calling [next])
/// - Handle errors
/// - Log information
///
/// Middleware are executed in priority order (lower priority = earlier execution).
abstract class ToolCallMiddleware {
  /// Processes the tool call context.
  ///
  /// [context] - The current context with request/response/state
  /// [next] - Function to invoke the next middleware in the pipeline
  ///
  /// Returns the final [CallToolResult] from the pipeline.
  ///
  /// To short-circuit execution, return a result without calling [next].
  Future<CallToolResult> handle(
    ToolCallContext context,
    Future<CallToolResult> Function(ToolCallContext) next,
  );

  /// Priority for middleware execution (lower = earlier execution).
  ///
  /// Default is 0. Middleware with the same priority are executed
  /// in the order they were added to the pipeline.
  int get priority => 0;
}

