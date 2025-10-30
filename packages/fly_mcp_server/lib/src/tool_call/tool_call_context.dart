import 'dart:async';

import 'package:dart_mcp/server.dart';
import 'package:fly_mcp_server/src/cancellation.dart';
import 'package:fly_mcp_server/src/progress.dart';
import 'package:fly_mcp_server/src/registries.dart';

/// Immutable context that carries request/response/state through the middleware pipeline.
///
/// Each middleware can read from the context and create a new context with
/// updated values using [copyWith] to maintain immutability.
class ToolCallContext {
  /// Creates a new context from a request.
  ToolCallContext({
    required this.request,
    required this.correlationId,
    required this.startTime,
    this.tool,
    this.metadata,
    this.cancelToken,
    this.progressNotifier,
    this.timeout,
    this.rawResult,
    this.result,
    this.error,
  });

  /// Original request
  final CallToolRequest request;

  /// Request correlation ID for tracking
  final String correlationId;

  /// Request start time
  final DateTime startTime;

  /// Resolved tool definition
  final Tool? tool;

  /// Tool metadata
  final ToolMetadata? metadata;

  /// Cancellation token
  final CancellationToken? cancelToken;

  /// Progress notifier for progress updates
  final ProgressNotifier? progressNotifier;

  /// Timeout for execution
  final Duration? timeout;

  /// Raw result from tool execution
  final Object? rawResult;

  /// Execution result (set by execution/conversion middleware)
  final CallToolResult? result;

  /// Error if any occurred
  final Object? error;

  /// Creates a copy of this context with updated fields.
  ToolCallContext copyWith({
    CallToolRequest? request,
    String? correlationId,
    DateTime? startTime,
    Tool? tool,
    ToolMetadata? metadata,
    CancellationToken? cancelToken,
    ProgressNotifier? progressNotifier,
    Duration? timeout,
    Object? rawResult,
    CallToolResult? result,
    Object? error,
  }) {
    return ToolCallContext(
      request: request ?? this.request,
      correlationId: correlationId ?? this.correlationId,
      startTime: startTime ?? this.startTime,
      tool: tool ?? this.tool,
      metadata: metadata ?? this.metadata,
      cancelToken: cancelToken ?? this.cancelToken,
      progressNotifier: progressNotifier ?? this.progressNotifier,
      timeout: timeout ?? this.timeout,
      rawResult: rawResult ?? this.rawResult,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }
}

