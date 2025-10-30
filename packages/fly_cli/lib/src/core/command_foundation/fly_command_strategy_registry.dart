import 'package:fly_cli/src/core/command_foundation/fly_command_strategy.dart';
import 'package:fly_cli/src/core/command_foundation/fly_command_type.dart';
import 'package:fly_cli/src/features/completion/completion_command_strategy.dart';
import 'package:fly_cli/src/features/context/context_command_strategy.dart';
import 'package:fly_cli/src/features/create/create_command_strategy.dart';
import 'package:fly_cli/src/features/doctor/doctor_command_strategy.dart';
import 'package:fly_cli/src/features/mcp/mcp_doctor_command_strategy.dart';
import 'package:fly_cli/src/features/mcp/mcp_serve_command_strategy.dart';
import 'package:fly_cli/src/features/schema/schema_command_strategy.dart';
import 'package:fly_cli/src/features/add/screen_command_strategy.dart';
import 'package:fly_cli/src/features/add/service_command_strategy.dart';
import 'package:fly_cli/src/features/version/version_command_strategy.dart';

/// Registry for Fly command strategies
/// 
/// Maps FlyCommandType enum values to their corresponding strategy instances.
/// Strategies are created lazily on demand and cached for reuse.
class FlyCommandStrategyRegistry {
  final Map<FlyCommandType, FlyCommandStrategy> _strategies = {};

  /// Gets the strategy for the given command type
  /// 
  /// Creates and caches the strategy instance on first access.
  FlyCommandStrategy getStrategy(FlyCommandType commandType) {
    return _strategies.putIfAbsent(commandType, () => _createStrategy(commandType));
  }

  /// Creates a strategy instance for the given command type
  FlyCommandStrategy _createStrategy(FlyCommandType commandType) {
    switch (commandType) {
      case FlyCommandType.create:
        return CreateCommandStrategy();
      case FlyCommandType.doctor:
        return DoctorCommandStrategy();
      case FlyCommandType.schema:
        return SchemaCommandStrategy();
      case FlyCommandType.version:
        return VersionCommandStrategy();
      case FlyCommandType.context:
        return ContextCommandStrategy();
      case FlyCommandType.completion:
        return CompletionCommandStrategy();
      case FlyCommandType.screen:
        return ScreenCommandStrategy();
      case FlyCommandType.service:
        return ServiceCommandStrategy();
      case FlyCommandType.mcpServe:
        return McpServeCommandStrategy();
      case FlyCommandType.mcpDoctor:
        return McpDoctorCommandStrategy();
    }
  }
}

/// Global strategy registry instance
final flyCommandStrategyRegistry = FlyCommandStrategyRegistry();

