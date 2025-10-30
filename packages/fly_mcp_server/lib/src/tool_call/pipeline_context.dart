import 'dart:async';

import 'package:dart_mcp/server.dart';
import 'package:fly_mcp_server/src/concurrency_limiter.dart';
import 'package:fly_mcp_server/src/logger.dart';
import 'package:fly_mcp_server/src/registries.dart';
import 'package:fly_mcp_server/src/validation/size_validator.dart';

/// Context that provides all dependencies needed to create middleware and build pipelines.
///
/// This context is passed to pipeline factories to give them access to
/// all the necessary components (registries, validators, loggers, etc.)
/// needed to instantiate middleware.
class ToolCallPipelineContext {
  /// Creates a new pipeline context.
  ToolCallPipelineContext({
    required this.toolRegistry,
    required this.concurrencyLimiter,
    required this.logger,
    required this.sizeValidator,
    required this.server,
    required this.defaultTimeout,
    required this.perToolTimeouts,
  });

  /// Tool registry for resolving tools
  final ToolRegistry toolRegistry;

  /// Concurrency limiter for rate limiting
  final ConcurrencyLimiter concurrencyLimiter;

  /// Logger for logging operations
  final Logger logger;

  /// Size validator for validating input/output sizes
  final SizeValidator sizeValidator;

  /// MCP server instance (needed for progress notifications)
  final MCPServer server;

  /// Default timeout for tool execution
  final Duration defaultTimeout;

  /// Per-tool timeout overrides
  final Map<String, Duration> perToolTimeouts;
}

