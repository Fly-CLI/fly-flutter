import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_mcp/server.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:fly_mcp_server/src/cancellation.dart';
import 'package:fly_mcp_server/src/concurrency_limiter.dart';
import 'package:fly_mcp_server/src/config/server_config.dart';
import 'package:fly_mcp_server/src/config/size_limits_config.dart';
import 'package:fly_mcp_server/src/errors/server_errors.dart';
import 'package:fly_mcp_server/src/logger.dart';
import 'package:fly_mcp_server/src/progress.dart';
import 'package:fly_mcp_server/src/registries.dart';
import 'package:fly_mcp_server/src/timeout_manager.dart';
import 'package:fly_mcp_server/src/validation/size_validator.dart';

/// MCP Server implementation using dart_mcp
/// 
/// This server extends MCPServer from dart_mcp and uses mixins for capabilities.
/// All custom features like concurrency limiting, timeouts, and cancellation are preserved.
/// 
/// Example:
/// ```dart
/// final tools = ToolRegistry();
/// final server = McpServer(toolRegistry: tools);
/// await server.connectStdioServer();
/// ```
final class McpServer extends MCPServer
    with ToolsSupport, ResourcesSupport, PromptsSupport {
  /// Creates an MCP server with the specified registries and configuration
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
  /// [workspaceRoot] - Workspace root directory (default: current directory)
  McpServer({
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
        );

  /// Creates an MCP server from a [ServerConfig] object
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
  /// 
  /// Example:
  /// ```dart
  /// final config = ServerConfig.defaultConfig();
  /// final server = McpServer.fromConfig(
  ///   toolRegistry: tools,
  ///   config: config,
  /// );
  /// ```
  factory McpServer.fromConfig({
    required ToolRegistry toolRegistry,
    ServerConfig? config,
    ResourceRegistry? resourceRegistry,
    PromptRegistry? promptRegistry,
    String? workspaceRoot,
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
    );
  }

  /// Internal constructor for shared initialization logic
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
  })  : _tools = toolRegistry,
        _resources = resourceRegistry ??
            ResourceRegistry(
              securityConfig: securityConfig,
              workspaceRoot: workspaceRoot,
            ),
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
        super.fromStreamChannel(
          stdioChannel(input: stdin, output: stdout),
          implementation: Implementation(name: 'fly-mcp', version: '0.1.0'),
        );

  final ToolRegistry _tools;
  final ResourceRegistry _resources;
  final PromptRegistry _prompts;
  final ConcurrencyLimiter _concurrencyLimiter;
  final Duration _defaultTimeout;
  final Map<String, Duration> _perToolTimeouts;
  final Logger _logger;
  final SizeValidator _sizeValidator;

  @override
  FutureOr<InitializeResult> initialize(InitializeRequest request) async {
    // Register all tools from registry
    for (final toolDef in _tools.list()) {
      final tool = _createToolFromDefinition(toolDef);
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
    for (final promptJson in _prompts.list()) {
      final prompt = _createPromptFromJson(promptJson);
      addPrompt(prompt, _handlePromptGet);
    }

    return await super.initialize(request);
  }

  /// Handle resource read requests
  Future<ReadResourceResult?> _handleResourceRead(
      ReadResourceRequest request) async {
    try {
      final result = _resources.read({'uri': request.uri});

      // Convert result to ResourceContents
      final content = result['content'] as String?;
      final mimeType = result['mimeType'] as String?;

      if (content == null) {
        return null; // Template didn't match
      }

      return ReadResourceResult(
        contents: [
          TextResourceContents(
            uri: request.uri,
            text: content,
            mimeType: mimeType,
          ),
        ],
      );
    } catch (e) {
      _logger.error('Error reading resource: ${e.toString()}', error: e);
      // Return null to let other templates try
      return null;
    }
  }

  /// Convert a ToolDefinition JSON to dart_mcp Tool
  Tool _createToolFromDefinition(Map<String, Object?> toolJson) {
    final name = toolJson['name'] as String;
    final description = toolJson['description'] as String? ?? '';
    final inputSchema = toolJson['inputSchema'] as Map<String, Object?>?;

    // Convert input schema to ObjectSchema
    final schema = inputSchema != null
        ? ObjectSchema.fromMap(inputSchema)
        : ObjectSchema();

    // Create annotations from tool metadata
    ToolAnnotations? annotations;
    if (toolJson['readOnly'] == true ||
        toolJson['writesToDisk'] == true ||
        toolJson['requiresConfirmation'] == true ||
        toolJson['idempotent'] == true) {
      annotations = ToolAnnotations(
        readOnlyHint: toolJson['readOnly'] as bool?,
        destructiveHint: toolJson['writesToDisk'] as bool?,
        idempotentHint: toolJson['idempotent'] as bool?,
      );
    }

    return Tool(
      name: name,
      description: description,
      inputSchema: schema,
      annotations: annotations,
    );
  }

  /// Handle a tool call with all the custom features
  Future<CallToolResult> _handleToolCall(CallToolRequest request) async {
    final start = DateTime.now();
    final correlationId = _generateCorrelationId(request.name);

    try {
      // Validate size before processing
      _sizeValidator.validateParameters(request.arguments ?? {});

      // Get tool definition
      final tool = _tools.getTool(request.name);
      if (tool == null) {
        return CallToolResult(
          isError: true,
          content: [TextContent(text: 'Tool not found: ${request.name}')],
        );
      }

      // Check confirmation requirement
      if (tool.requiresConfirmation) {
        final confirmed = (request.arguments?['confirm'] as bool?) ?? false;
        if (!confirmed) {
          return CallToolResult(
            isError: true,
            content: [
              TextContent(
                  text: 'Confirmation required for tool: ${request.name}')
            ],
          );
        }
      }

      // Create cancellation token
      final cancelToken = CancellationToken();

      // Get progress token from request if available
      final progressToken = request.meta?.progressToken;
      final progressNotifier = progressToken != null
          ? ProgressNotifier(
              server: this,
              progressToken: progressToken,
              enabled: true,
            )
          : null;

      // Get timeout for this tool
      final timeout = _perToolTimeouts[request.name] ?? _defaultTimeout;

      // Wrap with concurrency limiting and timeout
      final result = await _concurrencyLimiter.execute(
        request.name,
        () async {
          return await TimeoutManager.withTimeout(
            () async {
              // Call the tool handler
              final result = await _tools.call(
                request.name,
                request.arguments ?? {},
                cancelToken: cancelToken,
                progressNotifier: progressNotifier,
              );

              // Validate result size
              _sizeValidator.validateResult(result);

              // Convert result to TextContent
              // For now, we'll serialize as JSON string
              final resultJson = jsonEncode(result);
              return CallToolResult(
                content: [TextContent(text: resultJson)],
              );
            },
            timeout: timeout,
            operationName: request.name,
          );
        },
      );

      final elapsed = DateTime.now().difference(start);
      _logger.info(
        'Tool call completed',
        context: {
          'tool': request.name,
          'correlation_id': correlationId,
          'elapsed_ms': elapsed.inMilliseconds,
        },
      );

      return result;
    } catch (e) {
      _logError('tool_call', request.name, correlationId, e);

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

  /// Convert prompt JSON to dart_mcp Prompt
  Prompt _createPromptFromJson(Map<String, Object?> promptJson) {
    final name = promptJson['name'] as String? ?? promptJson['id'] as String;
    final description = promptJson['description'] as String?;
    final title = promptJson['title'] as String?;

    // Convert variables to PromptArguments
    final variables = promptJson['variables'] as List?;
    List<PromptArgument>? arguments;
    if (variables != null) {
      arguments = variables.map((v) {
        final varMap = v as Map<String, Object?>;
        return PromptArgument(
          name: varMap['name'] as String,
          description: varMap['description'] as String?,
          required: varMap['required'] as bool? ?? false,
        );
      }).toList();
    }

    return Prompt(
      name: name,
      title: title,
      description: description,
      arguments: arguments,
    );
  }

  /// Handle a prompt get request
  Future<GetPromptResult> _handlePromptGet(GetPromptRequest request) async {
    try {
      final result = _prompts
          .getPrompt({'id': request.name, 'arguments': request.arguments});

      // Convert result to GetPromptResult
      // Extract messages if present, otherwise create from text
      List<PromptMessage> messages = [];
      if (result['text'] != null) {
        messages.add(PromptMessage(
          role: Role.user,
          content: TextContent(text: result['text'] as String),
        ));
      }

      return GetPromptResult(
        description: result['description'] as String?,
        messages: messages,
      );
    } catch (e) {
      _logger.error('Error getting prompt: ${e.toString()}', error: e);
      rethrow;
    }
  }

  /// Connect server to stdio transport
  ///
  /// Configures the server to communicate over stdin/stdout using the MCP
  /// stdio transport protocol. This is the standard way to run an MCP server
  /// that will be used by MCP desktop clients.
  ///
  /// Example:
  /// ```dart
  /// final server = McpServer(toolRegistry: tools);
  /// await server.connectStdioServer();
  /// ```
  ///
  /// Note: This function will block until the server is shut down.
  Future<void> connectStdioServer() async {
    // The server is already connected via the constructor
    // Just wait for initialization and then keep running
    await initialized;
    await done;
  }

  /// Generate a correlation ID for request tracking
  String _generateCorrelationId(String identifier) {
    return 'req_${identifier}_${DateTime.now().microsecondsSinceEpoch}';
  }

  /// Log error with correlation ID
  void _logError(String operation,
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
        'Operation failed: ${error.toString()}',
        error: error,
        context: context,
      );
    }
  }
}
