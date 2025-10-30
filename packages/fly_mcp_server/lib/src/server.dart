import 'dart:async';
import 'dart:io';

import 'package:dart_mcp/server.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:fly_mcp_server/src/concurrency_limiter.dart';
import 'package:fly_mcp_server/src/config/server_config.dart';
import 'package:fly_mcp_server/src/config/size_limits_config.dart';
import 'package:fly_mcp_server/src/errors/server_errors.dart';
import 'package:fly_mcp_server/src/logger.dart';
import 'package:fly_mcp_server/src/registries.dart';
import 'package:fly_mcp_server/src/timeout_manager.dart';
import 'package:fly_mcp_server/src/tool_call/pipeline_context.dart';
import 'package:fly_mcp_server/src/tool_call/pipeline_factory.dart';
import 'package:fly_mcp_server/src/tool_call/tool_call_context.dart';
import 'package:fly_mcp_server/src/tool_call/tool_call_pipeline.dart';
import 'package:fly_mcp_server/src/validation/size_validator.dart';

/// MCP Server implementation using dart_mcp
///
/// This server extends MCPServer from dart_mcp and uses mixins for capabilities.
/// All custom features like concurrency limiting, timeouts, and cancellation are preserved.
///
/// **Important**: The server automatically connects to stdio (stdin/stdout) during
/// construction. This means you should create the server instance when you're ready
/// to start processing requests. Call [serve] to block and wait for requests.
///
/// Example:
/// ```dart
/// final tools = ToolRegistry();
/// final server = McpServer(toolRegistry: tools);
/// await server.serve();
/// ```
final class McpServer extends MCPServer
    with ToolsSupport, ResourcesSupport, PromptsSupport {
  /// Creates an MCP server configured for stdio transport
  ///
  /// The server automatically connects to stdin/stdout during construction.
  /// Create the server when you're ready to start processing requests.
  ///
  /// [toolRegistry] - Registry containing all available tools (required)
  /// [resourceRegistry] - Registry for resources (optional, creates default)
  /// [promptRegistry] - Registry for prompts (optional, creates default)
  /// [defaultTimeout] - Default timeout for tool execution (default: 5 minutes)
  /// [maxConcurrency] - Maximum concurrent tool executions (default: 10)
  /// [perToolConcurrency] - Per-tool concurrency limits (optional)
  /// [perToolTimeouts] - Per-tool timeout overrides (optional)
  /// [securityConfig] - Security configuration (optional)
  /// [loggingConfig] - Logging configuration (optional)
  /// [sizeLimitsConfig] - Size limits configuration (optional)
  /// [workspaceRoot] - Workspace root directory (default: current directory)
  /// [pipelineFactory] - Factory function for creating the middleware pipeline (optional, uses default)
  ///
  /// Example:
  /// ```dart
  /// final tools = ToolRegistry();
  /// final server = McpServer.stdio(toolRegistry: tools);
  /// await server.serve();
  /// ```
  ///
  /// Example with custom pipeline:
  /// ```dart
  /// final server = McpServer.stdio(
  ///   toolRegistry: tools,
  ///   pipelineFactory: (ctx) {
  ///     final pipeline = ToolCallPipeline();
  ///     pipeline.add(MyCustomMiddleware());
  ///     return pipeline;
  ///   },
  /// );
  /// ```
  McpServer.stdio({
    required ToolRegistry toolRegistry,
    ResourceRegistry? resourceRegistry,
    PromptRegistry? promptRegistry,
    Duration? defaultTimeout,
    int? maxConcurrency,
    Map<String, int>? perToolConcurrency,
    Map<String, Duration>? perToolTimeouts,
    SecurityConfig? securityConfig,
    LoggingConfig? loggingConfig,
    SizeLimitsConfig? sizeLimitsConfig,
    String? workspaceRoot,
    ToolCallPipelineFactory? pipelineFactory,
  }) : this._internal(
          toolRegistry: toolRegistry,
          resourceRegistry: resourceRegistry,
          promptRegistry: promptRegistry,
          defaultTimeout: defaultTimeout,
          maxConcurrency: maxConcurrency,
          perToolConcurrency: perToolConcurrency,
          perToolTimeouts: perToolTimeouts,
          securityConfig: securityConfig,
          loggingConfig: loggingConfig,
          sizeLimitsConfig: sizeLimitsConfig,
          workspaceRoot: workspaceRoot,
          pipelineFactory: pipelineFactory,
        );

  /// Creates an MCP server from a [ServerConfig] object with stdio transport
  ///
  /// This constructor accepts a complete [ServerConfig] object and initializes
  /// the server with all configuration values from it. This is the preferred
  /// way to create a server when you have a configuration object.
  ///
  /// [toolRegistry] - Registry containing all available tools (required)
  /// [config] - Complete server configuration (optional, uses defaults if not provided)
  /// [resourceRegistry] - Registry for resources (optional, creates default)
  /// [promptRegistry] - Registry for prompts (optional, creates default)
  /// [workspaceRoot] - Workspace root directory (default: current directory)
  /// [pipelineFactory] - Factory function for creating the middleware pipeline (optional, uses default)
  ///
  /// Example:
  /// ```dart
  /// final config = ServerConfig.defaultConfig();
  /// final server = McpServer.fromConfig(
  ///   toolRegistry: tools,
  ///   config: config,
  /// );
  /// await server.serve();
  /// ```
  factory McpServer.fromConfig({
    required ToolRegistry toolRegistry,
    ServerConfig? config,
    ResourceRegistry? resourceRegistry,
    PromptRegistry? promptRegistry,
    String? workspaceRoot,
    ToolCallPipelineFactory? pipelineFactory,
  }) {
    final effectiveConfig = config ?? ServerConfig.defaultConfig();
    return McpServer._internal(
      toolRegistry: toolRegistry,
      resourceRegistry: resourceRegistry,
      promptRegistry: promptRegistry,
      defaultTimeout: effectiveConfig.defaultTimeout,
      maxConcurrency: effectiveConfig.concurrency.maxConcurrency,
      perToolConcurrency: effectiveConfig.concurrency.perToolLimits,
      perToolTimeouts: effectiveConfig.timeouts.perToolTimeouts,
      securityConfig: effectiveConfig.security,
      loggingConfig: effectiveConfig.logging,
      sizeLimitsConfig: effectiveConfig.sizeLimits,
      workspaceRoot: workspaceRoot,
      pipelineFactory: pipelineFactory,
    );
  }

  /// Internal constructor for shared initialization logic
  ///
  /// Note: This connects to stdio transport immediately during construction
  /// via the parent class's fromStreamChannel constructor. This is a limitation
  /// of the dart_mcp MCPServer base class which requires a channel at construction time.
  McpServer._internal({
    required ToolRegistry toolRegistry,
    ResourceRegistry? resourceRegistry,
    PromptRegistry? promptRegistry,
    Duration? defaultTimeout,
    int? maxConcurrency,
    Map<String, int>? perToolConcurrency,
    Map<String, Duration>? perToolTimeouts,
    SecurityConfig? securityConfig,
    LoggingConfig? loggingConfig,
    SizeLimitsConfig? sizeLimitsConfig,
    String? workspaceRoot,
    ToolCallPipelineFactory? pipelineFactory,
  })  : _tools = toolRegistry,
        _resources = resourceRegistry ?? ResourceRegistry(strategies: []),
        _prompts = promptRegistry ?? PromptRegistry(),
        _concurrencyLimiter = ConcurrencyLimiter(
          maxConcurrency: maxConcurrency ?? 10,
          perToolLimits: perToolConcurrency,
        ),
        _defaultTimeout = defaultTimeout ?? const Duration(minutes: 5),
        _perToolTimeouts = perToolTimeouts ?? {},
        _logger = Logger(config: loggingConfig),
        _sizeValidator =
            SizeValidator(sizeLimitsConfig ?? const SizeLimitsConfig()),
        _pipelineFactory = pipelineFactory ?? DefaultPipelineFactory.create,
        _securityConfig = securityConfig,
        _workspaceRoot = workspaceRoot,
        super.fromStreamChannel(
          stdioChannel(input: stdin, output: stdout),
          implementation: Implementation(name: 'fly-mcp', version: '0.1.0'),
        ) {
    // Configure pipeline after super constructor completes (so 'this' is available)
    _toolCallPipeline = _configureToolCallPipeline();
  }

  final ToolRegistry _tools;
  final ResourceRegistry _resources;
  final PromptRegistry _prompts;
  final ConcurrencyLimiter _concurrencyLimiter;
  final Duration _defaultTimeout;
  final Map<String, Duration> _perToolTimeouts;
  final Logger _logger;
  final SizeValidator _sizeValidator;
  final ToolCallPipelineFactory _pipelineFactory;
  final SecurityConfig? _securityConfig;
  final String? _workspaceRoot;
  late final ToolCallPipeline _toolCallPipeline;

  @override
  FutureOr<InitializeResult> initialize(InitializeRequest request) async {
    // Register all tools from registry
    // ToolRegistry.list() now returns List<Tool> from dart_mcp
    for (final tool in _tools.list()) {
      registerTool(tool, _handleToolCall);
    }

    // Register resources using templates for URI patterns
    // Workspace resources
    addResourceTemplate(
      ResourceTemplate(
        uriTemplate: 'workspace://{path}',
        name: 'workspace',
        description: 'Workspace files and directories',
        mimeType: 'text/plain',
      ),
      _handleResourceRead,
    );

    // Run logs resources
    addResourceTemplate(
      ResourceTemplate(
        uriTemplate: 'logs://run/{id}',
        name: 'logs-run',
        description: 'Execution logs from process runs',
        mimeType: 'text/plain',
      ),
      _handleResourceRead,
    );

    // Build logs resources
    addResourceTemplate(
      ResourceTemplate(
        uriTemplate: 'logs://build/{id}',
        name: 'logs-build',
        description: 'Build logs from compilation processes',
        mimeType: 'text/plain',
      ),
      _handleResourceRead,
    );

    // Register prompts from registry
    for (final prompt in _prompts.list()) {
      addPrompt(prompt, _handlePromptGet);
    }

    return await super.initialize(request);
  }

  /// Handle resource read requests
  Future<ReadResourceResult?> _handleResourceRead(
      ReadResourceRequest request) async {
    try {
      // ResourceRegistry now returns ReadResourceResult directly
      return _resources.read(request);
    } catch (e) {
      _logger.error('Error reading resource: ${e.toString()}', error: e);
      // Return null to let other templates try
      return null;
    }
  }

  /// Handle a tool call with all the custom features
  Future<CallToolResult> _handleToolCall(CallToolRequest request) async {
    final start = DateTime.now();
    final correlationId = _generateCorrelationId(request.name);

    // Create context from request
    final context = ToolCallContext(
      request: request,
      correlationId: correlationId,
      startTime: start,
    );

    // Execute pipeline
    return await _toolCallPipeline.execute(context);
  }

  /// Configures the tool call pipeline using the factory.
  ToolCallPipeline _configureToolCallPipeline() {
    // Create pipeline context with all dependencies
    final context = ToolCallPipelineContext(
      toolRegistry: _tools,
      concurrencyLimiter: _concurrencyLimiter,
      logger: _logger,
      sizeValidator: _sizeValidator,
      server: this,
      defaultTimeout: _defaultTimeout,
      perToolTimeouts: _perToolTimeouts,
    );

    // Use factory to create pipeline
    return _pipelineFactory(context);
  }

  /// Handle a prompt get request
  Future<GetPromptResult> _handlePromptGet(GetPromptRequest request) async {
    try {
      final result = await _prompts
          .getPrompt({'id': request.name, 'arguments': request.arguments});
      return result;
    } catch (e) {
      _logger.error('Error getting prompt: ${e.toString()}', error: e);
      rethrow;
    }
  }

  /// Serve requests over stdio transport
  ///
  /// Starts the MCP server and waits for it to process requests. The server
  /// is configured to communicate over stdin/stdout using the MCP stdio
  /// transport protocol (connection happens during construction).
  ///
  /// This method blocks until the server is shut down or encounters an error.
  ///
  /// Example:
  /// ```dart
  /// final server = McpServer.stdio(toolRegistry: tools);
  /// await server.serve();
  /// ```
  ///
  /// Note: The server connects to stdio during construction, this method
  /// waits for initialization and keeps the server serving requests.
  Future<void> serve() async {
    await initialized;
    await done;
  }

  /// Generate a correlation ID for request tracking
  String _generateCorrelationId(String identifier) {
    return 'req_${identifier}_${DateTime.now().microsecondsSinceEpoch}';
  }

  /// Log error with correlation ID
  void _logError(
    String operation,
    String identifier,
    String correlationId,
    Object error,
  ) {
    final context = <String, Object?>{
      'operation': operation,
      'identifier': identifier,
      'correlation_id': correlationId,
    };

    // Add additional context for specific error types
    if (error is TimeoutException) {
      context['error_type'] = 'timeout';
      context['message'] = error.message;
      _logger.error(
        'Operation timeout: ${error.message}',
        error: error,
        context: context,
      );
    } else if (error is ConcurrencyLimitException) {
      context['error_type'] = 'concurrency_limit';
      context['message'] = error.message;
      context['tool'] = error.toolName;
      context['current'] = error.current;
      context['limit'] = error.limit;
      _logger.warning(
        'Concurrency limit reached for tool: ${error.toolName}',
        context: context,
      );
    } else if (error is McpServerException) {
      context['error_type'] = error.runtimeType.toString();
      context['message'] = error.message;
      if (error.context != null) {
        context.addAll(error.context!);
      }
      _logger.error(
        'Server error: ${error.message}',
        error: error,
        context: context,
      );
    } else {
      _logger.error(
        'Operation failed: $error',
        error: error,
        context: context,
      );
    }
  }
}
