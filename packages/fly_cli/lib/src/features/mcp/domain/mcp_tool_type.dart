import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/features/mcp/domain/mcp_tool_strategy.dart';
import 'package:fly_cli/src/features/mcp/domain/mcp_tool_strategy_registry.dart';
import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Enum representing all available MCP tools
enum McpToolType {
  flyEcho,
  flutterDoctor,
  flyTemplateList,
  flyTemplateApply,
  flutterCreate,
  flutterRun,
  flutterBuild,
}

/// Extension providing tool metadata and factory methods
/// 
/// Delegates to strategy classes for tool-specific implementation details,
/// maintaining enum exhaustiveness while leveraging the Strategy pattern
/// for flexibility and extensibility.
extension McpToolTypeExtension on McpToolType {
  /// Gets the strategy for this tool type
  McpToolStrategy get _strategy => mcpToolStrategyRegistry.getStrategy(this);

  /// The tool name as it appears in MCP
  String get name => _strategy.name;

  /// Human-readable description of the tool
  String get description => _strategy.description;

  /// JSON schema for tool parameters
  Map<String, Object?> get paramsSchema => _strategy.paramsSchema;

  /// JSON schema for tool results
  Map<String, Object?> get resultSchema => _strategy.resultSchema;

  /// Whether this tool is read-only
  bool get readOnly => _strategy.readOnly;

  /// Whether this tool writes to disk
  bool get writesToDisk => _strategy.writesToDisk;

  /// Whether this tool requires confirmation
  bool get requiresConfirmation => _strategy.requiresConfirmation;

  /// Whether this tool is idempotent
  bool get idempotent => _strategy.idempotent;

  /// Custom timeout for this tool, or null to use the default timeout
  Duration? get timeout => _strategy.timeout;

  /// Maximum concurrency for this tool, or null to use the default concurrency
  int? get maxConcurrency => _strategy.maxConcurrency;

  /// Create a handler function for this tool
  ToolHandler createHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return _strategy.createHandler(context, resourceRegistry);
  }

  /// Create a ToolDefinition instance for this tool
  ToolDefinition createDefinition(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return _strategy.createDefinition(context, resourceRegistry);
  }
}

