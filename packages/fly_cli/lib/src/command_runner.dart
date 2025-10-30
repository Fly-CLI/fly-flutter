import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/command_foundation/domain/fly_command_type.dart';
import 'package:fly_cli/src/core/command_foundation/infrastructure/command_context_impl.dart';
import 'package:fly_cli/src/core/command_foundation/infrastructure/interactive_prompt.dart';
import 'package:fly_cli/src/core/command_metadata/command_metadata.dart';
import 'package:fly_cli/src/core/dependency_injection/domain/service_container.dart';
import 'package:fly_cli/src/core/diagnostics/system_checker.dart';
import 'package:fly_cli/src/core/logging/domain/logger.dart' as flylog;
import 'package:fly_cli/src/core/logging/infrastructure/structured_mason_logger.dart';
import 'package:fly_cli/src/core/logging/logging_bootstrap.dart';
import 'package:fly_cli/src/core/path_management/path_resolver.dart';
import 'package:fly_cli/src/core/performance/performance_optimizer.dart';
import 'package:fly_cli/src/core/templates/template_manager.dart';
import 'package:fly_cli/src/core/utils/version_utils.dart';
import 'package:fly_core/src/environment/environment_manager.dart';
import 'package:fly_core/src/environment/env_var.dart';
import 'package:mason_logger/mason_logger.dart';

/// Enhanced Fly CLI Command Runner with simplified dependency injection
class FlyCommandRunner extends CommandRunner<int> {
  FlyCommandRunner() : super('fly', 'AI-native Flutter CLI tool') {
    _initializeServices();
    _registerGlobalOptions();
    _registerCommands();
  }

  late final ServiceContainer _services;
  late final CommandPerformanceOptimizer _optimizer;
  late flylog.Logger _appLogger;

  /// Initialize service container and dependencies
  void _initializeServices() {
    final baseMason = Logger();
    final isDevelopment = _isDevelopmentMode();
    
    // Initialize structured logging (root logger)
    _appLogger = LoggingBootstrap.createRootLogger(
      isDevelopment: isDevelopment,
    );

    final structuredLogger = StructuredMasonLogger(baseMason, _appLogger);

    _services = ServiceContainer()
      ..registerSingleton<Logger>(structuredLogger)
      ..registerSingleton<flylog.Logger>(_appLogger)
      ..registerSingleton<PathResolver>(PathResolver(
        logger: structuredLogger,
        isDevelopment: isDevelopment,
      ))
      ..registerSingleton<TemplateManager>(TemplateManager(
        templatesDirectory: '', // Will be resolved by PathResolver
        logger: structuredLogger,
      ))
      ..registerSingleton<SystemChecker>(SystemChecker(logger: structuredLogger))
      ..registerSingleton<InteractivePrompt>(InteractivePrompt(structuredLogger));

    _optimizer = CommandPerformanceOptimizer();
  }

  /// Determine if running in development mode
  bool _isDevelopmentMode() {
    // Check if we're running from source (development) vs installed package
    final scriptPath = Platform.script.toFilePath();
    return scriptPath.contains('packages/fly_cli') || 
           scriptPath.contains('bin/fly.dart');
  }

  /// Register global options
  void _registerGlobalOptions() {
    argParser
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Enable verbose output',
        negatable: false,
      )
      ..addFlag(
        'quiet',
        abbr: 'q',
        help: 'Suppress output',
        negatable: false,
      )
      ..addOption(
        'log-level',
        help: 'Logging level (trace, debug, info, warn, error, fatal)',
        allowed: ['trace', 'debug', 'info', 'warn', 'error', 'fatal'],
      )
      ..addOption(
        'log-format',
        help: 'Logging format (human or json)',
        allowed: ['human', 'json'],
      )
      ..addOption(
        'log-file',
        help: 'Write logs to file (in addition to console)',
      )
      ..addFlag(
        'no-color',
        help: 'Disable color output for human logs',
        negatable: false,
      )
      ..addFlag(
        'trace',
        help: 'Enable extra diagnostic tracing in logs',
        negatable: false,
      )
      ..addFlag(
        'version',
        help: 'Show version information',
        negatable: false,
      )
      ..addFlag(
        'plan',
        help: 'Show execution plan without running',
        negatable: false,
      )
      ..addOption(
        'output',
        abbr: 'f',
        allowed: ['human', 'json', 'ai'],
        defaultsTo: 'human',
        help: 'Output format (human, json, or ai)',
      );
  }

  /// Register all commands using enum-based architecture
  void _registerCommands() {
    // Create a temporary context for command registration
    final tempArgs = ArgParser()
      ..addFlag('verbose', negatable: false)
      ..addFlag('quiet', negatable: false);
    final context = _createContext(tempArgs.parse([]));

    // Delegate command creation to registry
    final registrationData =
        CommandMetadataRegistry.instance.createAndInitialize(
      context: context,
      globalOptionsParser: argParser,
    );

    // Register top-level commands
    for (final entry in registrationData.topLevelCommands.entries) {
      final commandType = entry.key;
      final commandInstance = entry.value;

      // Register top-level command
      addCommand(commandInstance);

      // Register aliases for top-level commands
      for (final alias in commandType.aliases) {
        addCommand(AliasCommand(alias, commandInstance));
      }
    }

    // Register all command groups
    for (final group in registrationData.commandGroups.values) {
      addCommand(group);
    }
  }

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      // Parse arguments to check for global flags
      final parsedArgs = argParser.parse(args);
      // Rebuild logging with CLI overrides
      final isDevelopment = _isDevelopmentMode();
      _appLogger = LoggingBootstrap.createRootLogger(
        isDevelopment: isDevelopment,
        parsedArgs: parsedArgs,
      );
      final traceId = DateTime.now().microsecondsSinceEpoch.toString();
      final runLogger = _appLogger.child({
        'trace_id': traceId,
        'args': args.toList(),
        'working_dir': Directory.current.path,
        'cli_version': VersionUtils.getCurrentVersion(),
      });
      runLogger.info('Fly CLI start');

      // Handle version flag
      if (parsedArgs['version'] == true) {
        return _handleVersionFlag(parsedArgs['output'] as String? ?? 'human');
      }

      // Preload critical services for performance
      await _optimizer.preloadCriticalServices();

      // Run the command
      final result = await super.run(args);
      runLogger.info('Fly CLI finish', fields: {'exit_code': result ?? 1});
      return result ?? 1;
    } catch (e, stackTrace) {
      return _handleError(e, stackTrace, args);
    }
  }

  /// Create a command context with services
  CommandContext _createContext(ArgResults args) {
    // Respect environment variables for working directory (12-Factor App pattern)
    // FLY_OUTPUT_DIR for explicit test control, PWD for Unix standard
    const env = EnvironmentManager();
    final workingDir = env.getString(EnvVar.flyOutputDir)
        ?? env.getString(EnvVar.pwd)
        ?? Directory.current.path;
    
    return CommandContextImpl(
      argResults: args,
      logger: _services.get<Logger>(),
      templateManager: _services.get<TemplateManager>(),
      systemChecker: _services.get<SystemChecker>(),
      interactivePrompt: _services.get<InteractivePrompt>(),
      pathResolver: _services.get<PathResolver>(),
      config: _getConfig(),
      environment: Environment.current(),
      workingDirectory: workingDir,
      verbose: args['verbose'] as bool? ?? false,
      quiet: args['quiet'] as bool? ?? false,
    );
  }

  /// Get configuration
  Map<String, dynamic> _getConfig() => {
    'cli_version': VersionUtils.getCurrentVersion(),
    'templates_directory': TemplateManager.findTemplatesDirectory(),
    'plugins_enabled': true,
  };

  /// Handle version flag using CommandResult for consistency
  int _handleVersionFlag(String outputFormat) {
    final logger = _services.get<Logger>();
    final versionInfo = VersionUtils.getVersionInfo().toJson();

    final result = CommandResult.success(
      command: 'version',
      message: 'Version information retrieved',
      data: versionInfo,
      metadata: {
        'cli_version': VersionUtils.getCurrentVersion(),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Use CommandResult's built-in output handling
    if (outputFormat == 'json') {
      logger.info(json.encode(result.toJson()));
    } else if (outputFormat == 'ai') {
      logger.info(json.encode(result.toAiJson()));
    } else {
      result.displayHuman();
    }
    return result.exitCode;
  }

  /// Handle errors with proper error handling
  int _handleError(Object e, StackTrace stackTrace, Iterable<String> args) {
    final logger = _services.get<Logger>();
    _appLogger.error('Unhandled error', error: e, stackTrace: stackTrace, fields: {
      'args': args.toList(),
      'cli_version': VersionUtils.getCurrentVersion(),
    });
    final outputFormat = args.contains('--output=json') ? 'json' : 
                        args.contains('--output=ai') ? 'ai' : 'human';
    
    final errorResult = CommandResult.error(
      message: e.toString(),
      suggestion: 'Check your command syntax and try again',
      metadata: {
        'cli_version': VersionUtils.getCurrentVersion(),
        'timestamp': DateTime.now().toIso8601String(),
        'verbose': args.contains('--verbose'),
      },
    );

    // Use CommandResult's built-in output handling
    if (outputFormat == 'json') {
      logger.info(json.encode(errorResult.toJson()));
    } else if (outputFormat == 'ai') {
      logger.info(json.encode(errorResult.toAiJson()));
    } else {
      errorResult.displayHuman();
      if (args.contains('--verbose')) {
        logger.err('Stack trace: $stackTrace');
      }
    }
    return errorResult.exitCode;
  }

  @override
  String get usage => '''
$description

Usage: fly <command> [arguments]

Global options:
${argParser.usage}

Available commands:
${commands.keys.map((name) => '  $name').join('\n')}

Run "fly help <command>" for more information about a command.
''';
}
