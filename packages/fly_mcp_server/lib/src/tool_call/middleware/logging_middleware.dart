import 'dart:async';

import 'package:dart_mcp/server.dart';
import 'package:fly_mcp_server/src/logger.dart';
import 'package:fly_mcp_server/src/tool_call/tool_call_context.dart';
import 'package:fly_mcp_server/src/tool_call/tool_call_middleware.dart';

/// Middleware that logs execution start and completion.
///
/// Priority: 80 (runs after result conversion)
class LoggingMiddleware implements ToolCallMiddleware {
  /// Creates logging middleware.
  LoggingMiddleware({
    required Logger logger,
  }) : _logger = logger;

  final Logger _logger;

  @override
  int get priority => 80;

  @override
  Future<CallToolResult> handle(
    ToolCallContext context,
    Future<CallToolResult> Function(ToolCallContext) next,
  ) async {
    // Log execution start
    _logger.info(
      'Tool call started',
      context: {
        'tool': context.request.name,
        'correlation_id': context.correlationId,
      },
    );

    try {
      // Continue to next middleware
      final result = await next(context);

      // Log completion
      final elapsed = DateTime.now().difference(context.startTime);
      _logger.info(
        'Tool call completed',
        context: {
          'tool': context.request.name,
          'correlation_id': context.correlationId,
          'elapsed_ms': elapsed.inMilliseconds,
        },
      );

      return result;
    } catch (e) {
      // Log error
      final elapsed = DateTime.now().difference(context.startTime);
      _logger.error(
        'Tool call failed',
        error: e,
        context: {
          'tool': context.request.name,
          'correlation_id': context.correlationId,
          'elapsed_ms': elapsed.inMilliseconds,
        },
      );
      rethrow;
    }
  }
}

