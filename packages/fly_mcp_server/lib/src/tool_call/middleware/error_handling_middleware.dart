import 'dart:async';

import 'package:dart_mcp/server.dart';
import 'package:fly_mcp_server/src/cancellation.dart';
import 'package:fly_mcp_server/src/concurrency_limiter.dart';
import 'package:fly_mcp_server/src/logger.dart';
import 'package:fly_mcp_server/src/timeout_manager.dart';
import 'package:fly_mcp_server/src/tool_call/tool_call_context.dart';
import 'package:fly_mcp_server/src/tool_call/tool_call_middleware.dart';

/// Middleware that catches exceptions and converts them to CallToolResult.
///
/// Priority: 90 (runs last in the pipeline, wraps everything)
class ErrorHandlingMiddleware implements ToolCallMiddleware {
  /// Creates error handling middleware.
  ErrorHandlingMiddleware({
    required Logger logger,
  }) : _logger = logger;

  final Logger _logger;

  @override
  int get priority => 90;

  @override
  Future<CallToolResult> handle(
    ToolCallContext context,
    Future<CallToolResult> Function(ToolCallContext) next,
  ) async {
    try {
      // Continue to next middleware
      return await next(context);
    } catch (e) {
      // Log error
      _logError(context, e);

      // Convert exception to CallToolResult
      if (e is ConcurrencyLimitException) {
        return CallToolResult(
          isError: true,
          content: [
            TextContent(text: 'Concurrency limit reached: ${e.message}')
          ],
        );
      } else if (e is TimeoutException) {
        return CallToolResult(
          isError: true,
          content: [TextContent(text: 'Timeout: ${e.message}')],
        );
      } else if (e is CancellationException) {
        return CallToolResult(
          isError: true,
          content: [TextContent(text: 'Cancelled: ${e.message}')],
        );
      } else {
        return CallToolResult(
          isError: true,
          content: [TextContent(text: 'Error: ${e.toString()}')],
        );
      }
    }
  }

  /// Log error with correlation ID
  void _logError(ToolCallContext context, Object error) {
    final logContext = <String, Object?>{
      'operation': 'tool_call',
      'identifier': context.request.name,
      'correlation_id': context.correlationId,
    };

    // Add additional context for specific error types
    if (error is TimeoutException) {
      logContext['error_type'] = 'timeout';
      logContext['message'] = error.message;
      _logger.error(
        'Operation timeout: ${error.message}',
        error: error,
        context: logContext,
      );
    } else if (error is ConcurrencyLimitException) {
      logContext['error_type'] = 'concurrency_limit';
      logContext['message'] = error.message;
      logContext['tool'] = error.toolName;
      logContext['current'] = error.current;
      logContext['limit'] = error.limit;
      _logger.warning(
        'Concurrency limit reached for tool: ${error.toolName}',
        context: logContext,
      );
    } else {
      _logger.error(
        'Operation failed: ${error.toString()}',
        error: error,
        context: logContext,
      );
    }
  }
}

