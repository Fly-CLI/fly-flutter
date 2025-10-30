import 'dart:async';

import 'package:dart_mcp/server.dart';
import 'package:fly_mcp_server/src/tool_call/tool_call_context.dart';
import 'package:fly_mcp_server/src/tool_call/tool_call_middleware.dart';

/// Pipeline that orchestrates middleware execution in priority order.
///
/// Middleware are executed in order of their priority (lower = earlier).
/// Each middleware can modify the context and call the next middleware.
class ToolCallPipeline {
  final List<ToolCallMiddleware> _middleware = [];

  /// Adds a middleware to the pipeline.
  void add(ToolCallMiddleware middleware) {
    _middleware.add(middleware);
  }

  /// Finds the index of the first middleware matching the specified type.
  ///
  /// Uses exact type matching (runtimeType comparison), not subtype matching.
  /// Returns null if no matching middleware is found.
  int? findFirstIndexByType(Type type) {
    for (int i = 0; i < _middleware.length; i++) {
      if (_middleware[i].runtimeType == type) {
        return i;
      }
    }
    return null;
  }

  /// Removes all middleware of the specified type.
  ///
  /// Uses exact type matching (runtimeType comparison).
  /// Iterates in reverse to avoid index shifting issues.
  void removeByType(Type type) {
    for (int i = _middleware.length - 1; i >= 0; i--) {
      if (_middleware[i].runtimeType == type) {
        _middleware.removeAt(i);
      }
    }
  }

  /// Removes middleware at the specified index.
  ///
  /// Throws [RangeError] if index is out of bounds.
  void removeAt(int index) {
    if (index < 0 || index >= _middleware.length) {
      throw RangeError('Index $index out of range (0-${_middleware.length - 1})');
    }
    _middleware.removeAt(index);
  }

  /// Inserts middleware at the specified index.
  ///
  /// If index is equal to length, the middleware is added at the end.
  /// Throws [RangeError] if index is negative or greater than length.
  void insertAt(int index, ToolCallMiddleware middleware) {
    if (index < 0 || index > _middleware.length) {
      throw RangeError('Index $index out of range (0-${_middleware.length})');
    }
    _middleware.insert(index, middleware);
  }

  /// Finds the Type of the first middleware matching the type predicate.
  ///
  /// Uses subtype checking (is T), which matches subclasses.
  /// Returns null if no matching middleware is found.
  /// This is used internally by CustomPipelineFactory to find types.
  Type? findFirstTypeByPredicate(bool Function(ToolCallMiddleware) predicate) {
    for (final middleware in _middleware) {
      if (predicate(middleware)) {
        return middleware.runtimeType;
      }
    }
    return null;
  }

  /// Executes the pipeline with the given context.
  ///
  /// Middleware are sorted by priority (ascending), then executed in sequence.
  /// Each middleware receives the context and a function to call the next
  /// middleware (or return a result if it's the last).
  Future<CallToolResult> execute(ToolCallContext context) async {
    // Sort middleware by priority (lower = earlier)
    final sorted = List<ToolCallMiddleware>.from(_middleware)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    // Build the pipeline chain in reverse order
    Future<CallToolResult> Function(ToolCallContext) next = (ctx) {
      // If no middleware left, return an error (shouldn't happen if pipeline is set up correctly)
      throw StateError('No middleware to execute');
    };

    // Build chain from last to first
    for (var i = sorted.length - 1; i >= 0; i--) {
      final middleware = sorted[i];
      final previousNext = next;
      next = (ctx) => middleware.handle(ctx, previousNext);
    }

    return next(context);
  }
}

