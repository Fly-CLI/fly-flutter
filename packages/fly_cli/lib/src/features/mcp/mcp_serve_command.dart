import 'dart:io';

import 'package:args/args.dart';
import 'package:fly_cli/src/core/command_foundation/command_base.dart';
import 'package:fly_cli/src/core/command_foundation/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/command_middleware.dart';
import 'package:fly_cli/src/core/command_foundation/command_result.dart';
import 'package:fly_cli/src/features/mcp/mcp_tool_type.dart';
import 'package:fly_cli/src/features/mcp/resources/dependencies_resource_strategy.dart';
import 'package:fly_cli/src/features/mcp/resources/logs_build_resource_strategy.dart';
import 'package:fly_cli/src/features/mcp/resources/logs_run_resource_strategy.dart';
import 'package:fly_cli/src/features/mcp/resources/manifest_resource_strategy.dart';
import 'package:fly_cli/src/features/mcp/resources/tests_resource_strategy.dart';
import 'package:fly_cli/src/features/mcp/resources/workspace_resource_strategy.dart';
import 'package:fly_cli/src/features/mcp/prompt_strategy_registry_provider.dart';
import 'package:fly_mcp_server/fly_mcp_server.dart';

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
        // Note: DryRunMiddleware is intentionally omitted for serve
        // because it's a long-running server process that must actually execute
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
    for (final toolType in McpToolType.values) {
      final toolAndHandler = toolType.createToolAndHandler(context, resourceRegistry);
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
