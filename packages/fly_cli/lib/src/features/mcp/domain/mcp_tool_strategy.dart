import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Abstract base class for MCP tool strategies
/// 
/// Each tool implements a concrete strategy that encapsulates all tool-specific
/// metadata, schemas, and handler creation logic.
abstract class McpToolStrategy {
  /// The tool name as it appears in MCP (e.g., 'fly.echo')
  String get name;

  /// Human-readable description of the tool
  String get description;

  /// JSON schema for tool parameters
  Map<String, Object?> get paramsSchema;

  /// JSON schema for tool results
  Map<String, Object?> get resultSchema;

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

  /// Creates a handler function for this tool
  /// 
  /// The handler will be called when the tool is invoked via MCP.
  ToolHandler createHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  );

  /// Creates a ToolDefinition instance for this tool
  /// 
  /// This factory method uses all metadata from the strategy to create
  /// a complete ToolDefinition that can be registered with ToolRegistry.
  ToolDefinition createDefinition(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return ToolDefinition(
      name: name,
      description: description,
      paramsSchema: paramsSchema,
      resultSchema: resultSchema,
      handler: createHandler(context, resourceRegistry),
      readOnly: readOnly,
      writesToDisk: writesToDisk,
      requiresConfirmation: requiresConfirmation,
      idempotent: idempotent,
    );
  }
}


