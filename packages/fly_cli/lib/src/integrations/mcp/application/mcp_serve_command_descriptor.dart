import 'package:args/command_runner.dart';
import 'package:fly_cli/src/features/commands/domain/categories.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/domain/fly_command_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/application/mcp_serve_command.dart';

/// Strategy for serve command
class McpServeCommandDescriptor extends FlyCommandDescriptor {
  @override
  String get name => 'serve';

  @override
  String get description =>
      'Start the MCP server over stdio for integration '
      'with assistants';

  @override
  List<String> get aliases => ['mcp.serve', 'mcp:serve'];

  @override
  CommandGroup? get group => const CommandGroup(
    name: 'mcp',
    description: 'Model Context Protocol commands',
  );

  @override
  CommandCategory get category => CommandCategory.integration;

  @override
  Command<int> createInstance(CommandContext context) {
    return McpServeCommand.create(context);
  }
}
