import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/fly_command_strategy.dart';
import 'package:fly_cli/src/core/command_foundation/domain/fly_command_type.dart';
import 'package:fly_cli/src/features/mcp/application/mcp_doctor_command.dart';

/// Strategy for mcp-doctor command
class McpDoctorCommandStrategy extends FlyCommandStrategy {
  @override
  String get name => 'mcp-doctor';

  @override
  String get description => 'Show MCP setup guidance and smoke-test instructions';

  @override
  List<String> get aliases => ['mcp.doctor', 'mcp:doctor'];

  @override
  FlyCommandType? get parentCommand => null;

  @override
  CommandGroup? get group => const CommandGroup(
        name: 'mcp',
        description: 'Model Context Protocol commands',
      );

  @override
  CommandCategory get category => CommandCategory.integration;

  @override
  Command<int> createInstance(CommandContext context) {
    return McpDoctorCommand.create(context);
  }
}

