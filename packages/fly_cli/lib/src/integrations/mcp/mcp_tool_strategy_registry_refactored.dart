import 'package:fly_cli/src/core/definitions/mcp_tool.dart';
import 'package:fly_cli/src/integrations/mcp/mcp_tool_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/registry/tool_strategy_factory.dart';
import 'package:fly_cli/src/integrations/mcp/tools/command_schema_export_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/diagnostic_echo_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/generate_screen_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/project_context_export_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/generate_flutter_project_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/generate_service_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/shell_completion_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/system_diagnostics_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/template_apply_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/types/template_list_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/version_info_strategy.dart';

/// Refactored registry for MCP tool strategies using DI and plugin pattern.
///
/// This version uses a factory pattern instead of a switch statement,
/// making it extensible and following the Open/Closed Principle.
class McpToolStrategyRegistryRefactored {
  McpToolStrategyRegistryRefactored({
    IToolStrategyFactory? factory,
  }) : _factory = factory ?? _createDefaultFactory();

  final IToolStrategyFactory _factory;
  final Map<McpTool, McpToolStrategy> _cache = {};

  /// Gets the strategy for the given tool type.
  ///
  /// Creates and caches the strategy instance on first access.
  McpToolStrategy getStrategy(McpTool toolType) {
    return _cache.putIfAbsent(toolType, () => _factory.create(toolType));
  }

  /// Clear the strategy cache.
  void clearCache() {
    _cache.clear();
  }

  /// Create the default factory with all tool strategies.
  static IToolStrategyFactory _createDefaultFactory() {
    final factories = <McpTool, McpToolStrategy Function()>{
      McpTool.echo: () => DiagnosticEchoStrategy(),
      McpTool.templateList: () => TemplateListStrategy(),
      McpTool.templateApply: () => TemplateApplyStrategy(),
      McpTool.generateProject: () => GenerateFlutterProjectStrategy(),
      McpTool.generateFeature: () => GenerateScreenStrategy(),
      McpTool.generateService: () => GenerateServiceStrategy(),
      McpTool.contextExport: () => ProjectContextExportStrategy(),
      McpTool.schemaExport: () => CommandSchemaExportStrategy(),
      McpTool.completion: () => ShellCompletionStrategy(),
      McpTool.version: () => VersionInfoStrategy(),
      McpTool.doctor: () => SystemDiagnosticsStrategy(),
    };

    return ToolStrategyFactory(factories: factories);
  }
}

