import 'package:args/args.dart';
import 'package:fly_cli/src/core/command_foundation/application/command_base.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_middleware.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_result.dart';
import 'package:fly_cli/src/features/mcp/domain/mcp_tool_type.dart';
import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Command to start the MCP server over stdio
class McpServeCommand extends FlyCommand {
  /// Creates an MCP serve command instance
  McpServeCommand(super.context);

  /// Factory constructor to create an MCP serve command instance
  factory McpServeCommand.create(CommandContext context) =>
      McpServeCommand(context);

  @override
  String get name => 'mcp-serve';

  @override
  String get description => 'Start the MCP server (stdio)';

  @override
  ArgParser get argParser {
    final parser = super.argParser
      ..addFlag(
        'stdio',
        help: 'Use stdio transport (required for MCP desktop clients)',
        defaultsTo: true,
      )
      ..addOption(
        'max-message-mb',
        defaultsTo: '2',
        help: 'Max message size in MB',
      )
      ..addOption(
        'default-timeout-seconds',
        defaultsTo: '300',
        help: 'Default timeout for tools in seconds (default: 5 minutes)',
      )
      ..addOption(
        'max-concurrency',
        defaultsTo: '10',
        help: 'Maximum concurrent tool executions',
      );
    return parser;
  }

  @override
  List<CommandMiddleware> get middleware => [
        LoggingMiddleware(),
        MetricsMiddleware(),
        DryRunMiddleware(),
      ];

  /// Builds per-tool timeout map from all tool strategies
  Map<String, Duration> get perToolTimeouts {
    final timeouts = <String, Duration>{};
    for (final toolType in McpToolType.values) {
      final timeout = toolType.timeout;
      if (timeout != null) {
        timeouts[toolType.name] = timeout;
      }
    }
    return timeouts;
  }

  /// Builds per-tool concurrency map from all tool strategies
  Map<String, int> get perToolConcurrency {
    final concurrency = <String, int>{};
    for (final toolType in McpToolType.values) {
      final maxConcurrency = toolType.maxConcurrency;
      if (maxConcurrency != null) {
        concurrency[toolType.name] = maxConcurrency;
      }
    }
    return concurrency;
  }

  @override
  Future<CommandResult> execute() async {
    final maxMb = int.tryParse(
          argResults?['max-message-mb'] as String? ?? '2',
        ) ??
        2;
    final defaultTimeoutSeconds = int.tryParse(
          argResults?['default-timeout-seconds'] as String? ?? '300',
        ) ??
        300;
    final maxConcurrency = int.tryParse(
          argResults?['max-concurrency'] as String? ?? '10',
        ) ??
        10;

    // Create resource registry with log provider for storing tool logs
    final resourceRegistry = ResourceRegistry();

    // Register all tools using enum-based architecture
    final tools = ToolRegistry();
    for (final toolType in McpToolType.values) {
      tools.register(toolType.createDefinition(context, resourceRegistry));
    }

    // Create server with resource registry and performance limits
    final server = McpServer(
      toolRegistry: tools,
      resourceRegistry: resourceRegistry,
      defaultTimeout: Duration(seconds: defaultTimeoutSeconds),
      maxConcurrency: maxConcurrency,
      perToolConcurrency: perToolConcurrency,
      perToolTimeouts: perToolTimeouts,
    );
    
    // Connect to stdio and wait for server to complete
    await server.connectStdioServer();

    return CommandResult.success(
      command: 'mcp serve',
      message: 'MCP stdio server exited',
      data: {
        'max_message_mb': maxMb,
      },
    );
  }
}
