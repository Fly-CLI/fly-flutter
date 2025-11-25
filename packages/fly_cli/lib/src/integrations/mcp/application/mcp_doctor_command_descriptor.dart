import 'package:args/command_runner.dart';
import 'package:fly_cli/src/features/commands/domain/categories.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/domain/fly_command_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/application/mcp_doctor_command.dart';

/// Strategy for doctor command
class McpDoctorCommandDescriptor extends FlyCommandDescriptor {
  @override
  String get name => 'doctor';

  @override
  String get description =>
      'Show MCP setup guidance and smoke-test instructions';

  @override
  List<String> get aliases => ['mcp.doctor', 'mcp:doctor'];

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
