import 'dart:async';

import 'package:dart_mcp/server.dart';
import 'package:fly_mcp_server/src/cancellation.dart';
import 'package:fly_mcp_server/src/progress.dart';
import 'package:fly_mcp_server/src/tool_call/tool_call_context.dart';
import 'package:fly_mcp_server/src/tool_call/tool_call_middleware.dart';

/// Middleware that creates cancellation token, progress notifier, and determines timeout.
///
/// Priority: 30 (runs after confirmation)
class SetupMiddleware implements ToolCallMiddleware {
  /// Creates setup middleware.
  SetupMiddleware({
    required MCPServer server,
    required Duration defaultTimeout,
    required Map<String, Duration> perToolTimeouts,
  })  : _server = server,
        _defaultTimeout = defaultTimeout,
        _perToolTimeouts = perToolTimeouts;

  final MCPServer _server;
  final Duration _defaultTimeout;
  final Map<String, Duration> _perToolTimeouts;

  @override
  int get priority => 30;

  @override
  Future<CallToolResult> handle(
    ToolCallContext context,
    Future<CallToolResult> Function(ToolCallContext) next,
  ) async {
    // Create cancellation token
    final cancelToken = CancellationToken();

    // Get progress token from request if available
    final progressToken = context.request.meta?.progressToken;
    final progressNotifier = progressToken != null
        ? ProgressNotifier(
            server: _server,
            progressToken: progressToken,
            enabled: true,
          )
        : null;

    // Get timeout for this tool
    final timeout = _perToolTimeouts[context.request.name] ?? _defaultTimeout;

    // Update context with setup values
    final updatedContext = context.copyWith(
      cancelToken: cancelToken,
      progressNotifier: progressNotifier,
      timeout: timeout,
    );

    // Continue to next middleware
    return next(updatedContext);
  }
}

