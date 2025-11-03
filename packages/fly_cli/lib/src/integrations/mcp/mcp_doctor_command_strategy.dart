import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command/foundation/domain/fly_command_strategy.dart';
import 'package:fly_cli/src/core/definitions/categories.dart';
import 'package:fly_cli/src/integrations/mcp/mcp_doctor_command.dart';

/// Strategy for doctor command
class McpDoctorCommandStrategy extends FlyCommandStrategy {
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
