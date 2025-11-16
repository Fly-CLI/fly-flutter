import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/definitions/categories.dart';
import 'package:fly_cli/src/integrations/mcp/mcp_tool_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/mcp_tool_strategy_registry.dart';
import 'package:fly_mcp/fly_mcp.dart';

/// Enum representing all available MCP tools
///
/// Tools are organized by category for better discoverability:
/// - Diagnostic: echo, doctor
/// - Template: templateList, templateApply
/// - Generation: generateScreen, generateService
/// - Export: contextExport, schemaExport
/// - Integration: completion, version
enum McpTool {
  // Diagnostic tools
  echo,
  doctor,

  // Template tools
  templateList,
  templateApply,

  // Generation tools
  generateFeature,
  generateService,

  // Export tools
  contextExport,
  schemaExport,

  // Integration tools
  completion,
  version,
}

/// Extension providing tool metadata and factory methods
///
/// Delegates to strategy classes for tool-specific implementation details,
/// maintaining enum exhaustiveness while leveraging the Strategy pattern
/// for flexibility and extensibility.
extension McpToolExtension on McpTool {
  /// Gets the strategy for this tool type
  McpToolStrategy get _strategy => mcpToolStrategyRegistry.getStrategy(this);

  /// The tool name as it appears in MCP
  String get name => _strategy.name;

  /// Human-readable description of the tool
  String get description => _strategy.description;

  /// JSON schema for tool parameters
  ObjectSchema get paramsSchema => _strategy.paramsSchema;

  /// JSON schema for tool results
  ObjectSchema get resultSchema => _strategy.resultSchema;

  /// Whether this tool is read-only
  bool get readOnly => _strategy.readOnly;

  /// Whether this tool writes to disk
  bool get writesToDisk => _strategy.writesToDisk;

  /// Whether this tool requires confirmation
  bool get requiresConfirmation => _strategy.requiresConfirmation;

  /// Whether this tool is idempotent
  bool get idempotent => _strategy.idempotent;

  /// Tool category for better organization
  ToolCategory get category => _getCategory();

  /// Custom timeout for this tool, or null to use the default timeout
  Duration? get timeout => _strategy.timeout;

  /// Maximum concurrency for this tool, or null to use the default concurrency
  int? get maxConcurrency => _strategy.maxConcurrency;

  /// Get the category for this tool
  ToolCategory _getCategory() {
    switch (this) {
      case McpTool.echo:
      case McpTool.doctor:
        return ToolCategory.diagnostic;
      case McpTool.templateList:
      case McpTool.templateApply:
        return ToolCategory.template;
      case McpTool.generateFeature:
      case McpTool.generateService:
        return ToolCategory.generation;
      case McpTool.contextExport:
      case McpTool.schemaExport:
        return ToolCategory.export;
      case McpTool.completion:
      case McpTool.version:
        return ToolCategory.integration;
    }
  }

  /// Create a handler function for this tool
  ToolHandler createHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return _strategy.createHandler(context, resourceRegistry);
  }

  /// Create a [Tool] instance from `dart_mcp/src/api/tools.dart` for this tool
  ///
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
    return _strategy.createToolAndHandler(context, resourceRegistry);
  }
}
