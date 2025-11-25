import 'package:fly_cli/src/features/commands/domain/mcp_tool.dart';
import 'package:fly_cli/src/integrations/mcp/application/mcp_tool_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/tools/command_schema_export_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/tools/diagnostic_echo_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/tools/generate_flutter_project_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/tools/generate_screen_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/tools/generate_service_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/tools/project_context_export_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/tools/shell_completion_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/tools/system_diagnostics_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/tools/template_apply_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/tools/types/template_list_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/tools/version_info_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/registry/tool_strategy_factory.dart';

/// Registry for MCP tool strategies using factory pattern.
///
/// Maps McpTool enum values to their corresponding strategy instances.
/// Strategies are created lazily on demand and cached for reuse.
/// Uses IToolStrategyFactory for extensibility and dependency injection.
class McpToolStrategyRegistry {
  McpToolStrategyRegistry({
    IToolStrategyFactory? factory,
  }) : _factory = factory ?? _createDefaultFactory();

  final IToolStrategyFactory _factory;
  final Map<McpTool, McpToolStrategy> _strategies = {};

  /// Gets the strategy for the given tool type
  ///
  /// Creates and caches the strategy instance on first access.
  McpToolStrategy getStrategy(McpTool toolType) {
    return _strategies.putIfAbsent(
      toolType,
      () => _factory.create(toolType),
    );
  }

  /// Register a custom strategy factory for a tool type
  ///
  /// Allows extending the registry with new tools without modifying existing code.
  void registerStrategy(
    McpTool toolType,
    McpToolStrategy Function() factory,
  ) {
    _factory.register(toolType, factory);
    // Clear cache for this tool type to force recreation
    _strategies.remove(toolType);
  }

  /// Create default factory with all built-in strategies
  static IToolStrategyFactory _createDefaultFactory() {
    final factories = <McpTool, McpToolStrategy Function()>{
      McpTool.echo: DiagnosticEchoStrategy.new,
      McpTool.templateList: TemplateListStrategy.new,
      McpTool.templateApply: TemplateApplyStrategy.new,
      McpTool.generateProject: GenerateFlutterProjectStrategy.new,
      McpTool.generateFeature: GenerateScreenStrategy.new,
      McpTool.generateService: GenerateServiceStrategy.new,
      McpTool.contextExport: ProjectContextExportStrategy.new,
      McpTool.schemaExport: CommandSchemaExportStrategy.new,
      McpTool.completion: ShellCompletionStrategy.new,
      McpTool.version: VersionInfoStrategy.new,
      McpTool.doctor: SystemDiagnosticsStrategy.new,
    };

    return ToolStrategyFactory(factories: factories);
  }
}

/// Global strategy registry instance
final mcpToolStrategyRegistry = McpToolStrategyRegistry();
