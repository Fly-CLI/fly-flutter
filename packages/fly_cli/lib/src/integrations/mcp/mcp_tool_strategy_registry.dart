import 'package:fly_cli/src/core/definitions/mcp_tool.dart';
import 'package:fly_cli/src/integrations/mcp/mcp_tool_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/fly_add_screen_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/fly_add_service_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/fly_completion_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/fly_context_export_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/fly_doctor_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/fly_echo_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/fly_schema_export_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/fly_template_apply_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/fly_version_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/types/fly_template_list_strategy.dart';

/// Registry for MCP tool strategies
///
/// Maps McpTool enum values to their corresponding strategy instances.

/// Strategies are created lazily on demand and cached for reuse.
class McpToolStrategyRegistry {
  final Map<McpTool, McpToolStrategy> _strategies = {};

  /// Gets the strategy for the given tool type
  ///
  /// Creates and caches the strategy instance on first access.
  McpToolStrategy getStrategy(McpTool toolType) {
    return _strategies.putIfAbsent(toolType, () => _createStrategy(toolType));
  }

  /// Creates a strategy instance for the given tool type
  McpToolStrategy _createStrategy(McpTool toolType) {
    switch (toolType) {
      case McpTool.echo:
        return FlyEchoStrategy();
      case McpTool.templateList:
        return FlyTemplateListStrategy();
      case McpTool.templateApply:
        return FlyTemplateApplyStrategy();
      case McpTool.addScreen:
        return FlyAddScreenStrategy();
      case McpTool.addService:
        return FlyAddServiceStrategy();
      case McpTool.contextExport:
        return FlyContextExportStrategy();
      case McpTool.schemaExport:
        return FlySchemaExportStrategy();
      case McpTool.completion:
        return FlyCompletionStrategy();
      case McpTool.version:
        return FlyVersionStrategy();
      case McpTool.doctor:
        return FlyDoctorStrategy();
    }
  }
}

/// Global strategy registry instance
final mcpToolStrategyRegistry = McpToolStrategyRegistry();
