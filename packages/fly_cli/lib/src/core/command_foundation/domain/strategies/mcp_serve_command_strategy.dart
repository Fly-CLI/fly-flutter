import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/fly_command_strategy.dart';
import 'package:fly_cli/src/core/command_foundation/domain/fly_command_type.dart';
import 'package:fly_cli/src/features/mcp/application/mcp_serve_command.dart';

/// Strategy for mcp-serve command
class McpServeCommandStrategy extends FlyCommandStrategy {
  @override
  String get name => 'mcp-serve';

  @override
  String get description => 'Start the MCP server over stdio for integration '
      'with assistants';

  @override
  List<String> get aliases => ['mcp.serve', 'mcp:serve'];

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
    return McpServeCommand.create(context);
  }
}

