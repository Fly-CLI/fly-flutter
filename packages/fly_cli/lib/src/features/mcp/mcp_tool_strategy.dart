import 'package:fly_cli/src/core/command_foundation/command_context.dart';
import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Typed handler function for tool execution
/// 
/// [params] - Typed tool parameters
/// [cancelToken] - Cancellation token to check for cancellation requests
/// [progressNotifier] - Progress notifier for sending progress updates
/// 
/// Returns the typed tool execution result.
typedef TypedToolHandler<TP extends ToolParameter, TR extends ToolResult> = 
  Future<TR> Function(
    TP params, {
    CancellationToken? cancelToken,
    ProgressNotifier? progressNotifier,
  });

/// Abstract base class for MCP tool strategies
/// 
/// Each tool implements a concrete strategy that encapsulates all tool-specific
/// metadata, schemas, and handler creation logic.
/// 
/// [TP] - The typed parameter class implementing ToolParameter
/// [TR] - The typed result class implementing ToolResult
abstract class McpToolStrategy<
    TP extends ToolParameter,
    TR extends ToolResult> {
  /// The tool name as it appears in MCP (e.g., 'fly.echo')
  String get name;

  /// Human-readable description of the tool
  String get description;

  /// JSON schema for tool parameters
  ObjectSchema get paramsSchema;

  /// JSON schema for tool results
  ObjectSchema get resultSchema;

  /// Whether this tool is read-only (does not modify system state)
  bool get readOnly;

  /// Whether this tool writes to disk
  bool get writesToDisk;

  /// Whether this tool requires user confirmation before execution
  bool get requiresConfirmation;

  /// Whether this tool is idempotent (can be safely called multiple times)
  bool get idempotent;

  /// Custom timeout for this tool, or null to use the default timeout
  Duration? get timeout => null;

  /// Maximum concurrency for this tool, or null to use the default concurrency
  int? get maxConcurrency => null;

  /// Create a typed parameter instance from JSON Map
  /// 
  /// [json] - The JSON Map representation
  /// 
  /// Returns an instance of the typed parameter class.
  TP paramsFromJson(Map<String, Object?> json);

  /// Creates a typed handler function for this tool
  /// 
  /// The handler will be called when the tool is invoked via MCP.
  /// This is the preferred method for creating handlers with full type safety.
  TypedToolHandler<TP, TR> createTypedHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  );

  /// Creates a handler function for this tool (for protocol compatibility)
  /// 
  /// The handler will be called when the tool is invoked via MCP.
  /// This method wraps the typed handler and converts between Map and typed
  /// models.
  ToolHandler createHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    final typedHandler = createTypedHandler(context, resourceRegistry);
    return (Map<String, Object?> mapParams, {
      CancellationToken? cancelToken,
      ProgressNotifier? progressNotifier,
    }) async {
      // Convert Map to typed parameter
      final params = paramsFromJson(mapParams);
      
      // Validate parameters against schema
      final validationErrors = params.validate(paramsSchema);
      if (validationErrors.isNotEmpty) {
        throw ArgumentError(
          'Parameter validation failed: ${validationErrors.join('; ')}',
        );
      }
      
      // Execute typed handler
      final result = await typedHandler(
        params,
        cancelToken: cancelToken,
        progressNotifier: progressNotifier,
      );
      
      // Validate result against schema
      final resultValidationErrors = result.validate(resultSchema);
      if (resultValidationErrors.isNotEmpty) {
        throw StateError(
          'Result validation failed: ${resultValidationErrors.join('; ')}',
        );
      }
      
      // Convert typed result to Map for protocol
      return result.toJson();
    };
  }

  /// Creates a [Tool] instance from `dart_mcp/src/api/tools.dart` for this tool
  /// 
  /// This factory method uses all metadata from the strategy to create
  /// a complete [Tool] object that can be registered with ToolRegistry.
  /// Returns the Tool, handler, and requiresConfirmation separately,
  /// since Tool doesn't include the handler or confirmation requirement.
  ({
    Tool tool,
    ToolHandler handler,
    bool requiresConfirmation,
  }) createToolAndHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    final handler = createHandler(context, resourceRegistry);
    final tool = createTool(
      name: name,
      description: description,
      inputSchema: paramsSchema,
      outputSchema: resultSchema,
      readOnly: readOnly,
      writesToDisk: writesToDisk,
      requiresConfirmation: requiresConfirmation,
      idempotent: idempotent,
    );
    return (
      tool: tool,
      handler: handler,
      requiresConfirmation: requiresConfirmation,
    );
  }
}


