import 'package:fly_cli/src/core/definitions/mcp_tool.dart';
import 'package:fly_cli/src/integrations/mcp/mcp_tool_strategy.dart';

/// Factory interface for creating tool strategies.
///
/// Allows for dependency injection and makes the registry extensible.
abstract class IToolStrategyFactory {
  /// Create a strategy for the given tool type.
  McpToolStrategy create(McpTool toolType);

  /// Register a strategy factory for a tool type.
  void register(McpTool toolType, McpToolStrategy Function() factory);
}

/// Factory for creating MCP tool strategies.
///
/// Uses a plugin-based approach where strategies are registered
/// via a map, making it easy to extend without modifying existing code.
class ToolStrategyFactory implements IToolStrategyFactory {
  ToolStrategyFactory({
    required Map<McpTool, McpToolStrategy Function()> factories,
  }) : _factories = factories;

  final Map<McpTool, McpToolStrategy Function()> _factories;

  @override
  McpToolStrategy create(McpTool toolType) {
    final factory = _factories[toolType];
    if (factory == null) {
      throw UnsupportedToolException(toolType);
    }
    return factory();
  }

  /// Register a strategy factory for a tool type.
  @override
  void register(McpTool toolType, McpToolStrategy Function() factory) {
    _factories[toolType] = factory;
  }
}

/// Exception thrown when a tool type is not supported.
class UnsupportedToolException implements Exception {
  UnsupportedToolException(this.toolType);

  final McpTool toolType;

  @override
  String toString() => 'Unsupported tool type: $toolType';
}

