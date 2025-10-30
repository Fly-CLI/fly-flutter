import 'package:fly_cli/src/features/mcp/mcp_tool_strategy.dart';
import 'package:fly_cli/src/features/mcp/mcp_tool_type.dart';
import 'package:fly_cli/src/features/mcp/tools/flutter_build_strategy.dart';
import 'package:fly_cli/src/features/mcp/tools/flutter_create_strategy.dart';
import 'package:fly_cli/src/features/mcp/tools/flutter_doctor_strategy.dart';
import 'package:fly_cli/src/features/mcp/tools/flutter_run_strategy.dart';
import 'package:fly_cli/src/features/mcp/tools/fly_echo_strategy.dart';
import 'package:fly_cli/src/features/mcp/tools/fly_template_apply_strategy.dart';
import 'package:fly_cli/src/features/mcp/tools/types/fly_template_list_strategy.dart';

/// Registry for MCP tool strategies
/// 
/// Maps McpToolType enum values to their corresponding strategy instances.
/// Strategies are created lazily on demand and cached for reuse.
class McpToolStrategyRegistry {
  final Map<McpToolType, McpToolStrategy> _strategies = {};

  /// Gets the strategy for the given tool type
  /// 
  /// Creates and caches the strategy instance on first access.
  McpToolStrategy getStrategy(McpToolType toolType) {
    return _strategies.putIfAbsent(toolType, () => _createStrategy(toolType));
  }

  /// Creates a strategy instance for the given tool type
  McpToolStrategy _createStrategy(McpToolType toolType) {
    switch (toolType) {
      case McpToolType.flyEcho:
        return FlyEchoStrategy();
      case McpToolType.flutterDoctor:
        return FlutterDoctorStrategy();
      case McpToolType.flyTemplateList:
        return FlyTemplateListStrategy();
      case McpToolType.flyTemplateApply:
        return FlyTemplateApplyStrategy();
      case McpToolType.flutterCreate:
        return FlutterCreateStrategy();
      case McpToolType.flutterRun:
        return FlutterRunStrategy();
      case McpToolType.flutterBuild:
        return FlutterBuildStrategy();
    }
  }
}

/// Global strategy registry instance
final mcpToolStrategyRegistry = McpToolStrategyRegistry();


