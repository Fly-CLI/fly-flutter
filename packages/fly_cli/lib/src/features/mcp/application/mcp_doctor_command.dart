import 'package:fly_cli/src/core/command_foundation/application/command_base.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_middleware.dart';

class McpDoctorCommand extends FlyCommand {
  McpDoctorCommand(CommandContext context) : super(context);

  factory McpDoctorCommand.create(CommandContext context) => McpDoctorCommand(context);

  @override
  String get name => 'mcp-doctor';

  @override
  String get description => 'Run an MCP smoke test and show setup guidance';

  @override
  List<CommandMiddleware> get middleware => [
        LoggingMiddleware(),
        MetricsMiddleware(),
        DryRunMiddleware(),
      ];

  @override
  Future<CommandResult> execute() async {
    logger.info('MCP doctor: Ensure your assistant is configured to run:');
    logger.info('  fly mcp-serve --stdio');
    logger.info('Then use your assistant to list tools and call fly.echo.');

    return CommandResult.success(
      command: 'mcp doctor',
      message: 'MCP doctor guidance printed',
      nextSteps: const [
        NextStep(
          command: 'fly mcp-serve --stdio',
          description: 'Start MCP server via stdio',
        ),
      ],
    );
  }
}


