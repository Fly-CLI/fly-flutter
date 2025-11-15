import 'dart:io';

import 'package:fly_cli/src/core/command/foundation/application/command_base.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/command/foundation/flags/cli_flags.dart';
import 'package:fly_cli/src/core/command/foundation/flags/flag_accessor.dart';
import 'package:fly_cli/src/core/definitions/mcp_tool.dart';
import 'package:fly_cli/src/core/middleware/domain/command_middleware.dart';
import 'package:fly_cli/src/integrations/mcp/prompt_strategy_registry_provider.dart';
import 'package:fly_cli/src/integrations/mcp/resources/dependencies_resource_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/resources/logs_build_resource_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/resources/logs_run_resource_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/resources/manifest_resource_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/resources/tests_resource_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/resources/workspace_resource_strategy.dart';
import 'package:fly_mcp/fly_mcp.dart' hide LoggingMiddleware;

/// Command to start the MCP server over stdio
class McpServeCommand extends FlyCommand {
  /// Creates an MCP serve command instance
  McpServeCommand(super.context);

  /// Factory constructor to create an MCP serve command instance
  factory McpServeCommand.create(CommandContext context) =>
      McpServeCommand(context);

  @override
  String get name => 'serve';

  @override
  String get description => 'Start the MCP server (stdio)';

  @override
  List<CliFlag> get flags => [
        const McpServeStdioFlag(),
        const McpServeMaxMessageMbFlag(),
        const McpServeDefaultTimeoutSecondsFlag(),
        const McpServeMaxConcurrencyFlag(),
      ];

  @override
  List<CommandMiddleware> get middleware => [
        // Note: DryRunMiddleware is intentionally omitted for serve
        // because it's a long-running server process that must actually execute
      ];

  /// Builds per-tool timeout map from all tool strategies
  Map<String, Duration> get perToolTimeouts {
    final timeouts = <String, Duration>{};
    for (final toolType in McpTool.values) {
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
    for (final toolType in McpTool.values) {
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
            FlagAccessor.getStringOrDefault(
              argResults,
              const McpServeMaxMessageMbFlag(),
              '2',
            ),
          ) ??
          2;
      final defaultTimeoutSeconds = int.tryParse(
            FlagAccessor.getStringOrDefault(
              argResults,
              const McpServeDefaultTimeoutSecondsFlag(),
              '300',
            ),
          ) ??
          300;
      final maxConcurrency = int.tryParse(
            FlagAccessor.getStringOrDefault(
              argResults,
              const McpServeMaxConcurrencyFlag(),
              '10',
            ),
          ) ??
          10;

    // Initialize prompt strategy registry provider
    initializePromptStrategyRegistry();

    // Create log provider for storing tool logs
    final logProvider = LogResourceProvider();

    // Create resource strategies with log provider
    final runStrategy = LogsRunResourceStrategy(logProvider: logProvider);
    final buildStrategy = LogsBuildResourceStrategy(logProvider: logProvider);
    final workspaceStrategy = WorkspaceResourceStrategy()
      ..setPathSandbox(
        PathSandbox(
          workspaceRoot: Directory.current.path,
          securityConfig: null,
        ),
      );

    final manifestStrategy = ManifestResourceStrategy()
      ..setPathSandbox(
        PathSandbox(
          workspaceRoot: Directory.current.path,
          securityConfig: null,
        ),
      );

    final dependenciesStrategy = DependenciesResourceStrategy()
      ..setPathSandbox(
        PathSandbox(
          workspaceRoot: Directory.current.path,
          securityConfig: null,
        ),
      );

    final testsStrategy = TestsResourceStrategy()
      ..setPathSandbox(
        PathSandbox(
          workspaceRoot: Directory.current.path,
          securityConfig: null,
        ),
      );

    // Create resource registry with strategies
    final resourceRegistry = ResourceRegistry(
      strategies: [
        runStrategy,
        buildStrategy,
        workspaceStrategy,
        manifestStrategy,
        dependenciesStrategy,
        testsStrategy,
      ],
    );

    // Register all tools using enum-based architecture
    final tools = ToolRegistry();
    for (final toolType in McpTool.values) {
      final toolAndHandler =
          toolType.createToolAndHandler(context, resourceRegistry);
      tools.register(
        toolAndHandler.tool,
        toolAndHandler.handler,
        requiresConfirmation: toolAndHandler.requiresConfirmation,
      );
    }

    // Create server with resource registry and performance limits
    final server = McpServer.stdio(
      toolRegistry: tools,
      resourceRegistry: resourceRegistry,
      defaultTimeout: Duration(seconds: defaultTimeoutSeconds),
      maxConcurrency: maxConcurrency,
      perToolConcurrency: perToolConcurrency,
      perToolTimeouts: perToolTimeouts,
    );

    // Serve requests over stdio
    await server.serve();

    return CommandResult.success(
      command: 'mcp serve',
      message: 'MCP stdio server exited',
      data: {
        'max_message_mb': maxMb,
      },
    );
  }
}
