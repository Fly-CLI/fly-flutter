import 'dart:async';

import 'package:dart_mcp/server.dart';
import 'package:fly_core/fly_core.dart';
import '../tool_call_context.dart';
import '../tool_call_middleware.dart';

/// Middleware that wraps execution in concurrency limiter.
///
/// Priority: 40 (runs after setup)
class ConcurrencyMiddleware implements ToolCallMiddleware {
  /// Creates concurrency middleware.
  ConcurrencyMiddleware({
    required ConcurrencyLimiter concurrencyLimiter,
  }) : _concurrencyLimiter = concurrencyLimiter;

  final ConcurrencyLimiter _concurrencyLimiter;

  @override
  int get priority => 40;

  @override
  Future<CallToolResult> handle(
    ToolCallContext context,
    Future<CallToolResult> Function(ToolCallContext) next,
  ) async {
    // Wrap execution in concurrency limiter
    return await _concurrencyLimiter.execute(
      context.request.name,
      () async => next(context),
    );
  }
}
