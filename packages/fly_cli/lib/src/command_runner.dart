import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/command_foundation/flags/cli_flags.dart';
import 'package:fly_cli/src/core/command_foundation/flags/flag_accessor.dart';
import 'package:fly_cli/src/core/command_foundation/flags/global_flags_registry.dart';
import 'package:fly_cli/src/core/command_foundation/infrastructure/command_context_impl.dart';
import 'package:fly_cli/src/core/command_foundation/infrastructure/interactive_prompt.dart';
import 'package:fly_cli/src/core/command_metadata/command_registry.dart';
import 'package:fly_cli/src/core/command_metadata/command_wrappers.dart';
import 'package:fly_cli/src/core/definitions/fly_command.dart';
import 'package:fly_cli/src/core/dependency_injection/service_container.dart';
import 'package:fly_cli/src/core/diagnostics/system_checker.dart';
import 'package:fly_cli/src/core/logging/logger.dart' as flylog;
import 'package:fly_cli/src/core/logging/logging_bootstrap.dart';
import 'package:fly_cli/src/core/logging/structured_mason_logger.dart';
import 'package:fly_cli/src/core/path_management/path_resolver.dart';
import 'package:fly_cli/src/core/telemetry/domain/metrics_collector.dart';
import 'package:fly_cli/src/core/telemetry/infrastructure/metrics_config.dart';
import 'package:fly_cli/src/core/telemetry/infrastructure/metrics_factory.dart';
import 'package:fly_cli/src/core/templates/template_manager.dart';
import 'package:fly_cli/src/core/utils/version_utils.dart';
import 'package:fly_core/src/environment/env_var.dart';
import 'package:fly_core/src/environment/environment_manager.dart';
import 'package:mason_logger/mason_logger.dart';

/// Enhanced Fly CLI Command Runner with simplified dependency injection
class FlyCommandRunner extends CommandRunner<int> {
  FlyCommandRunner() : super('fly', 'AI-native Flutter CLI tool') {
    _initializeServices();
    _registerGlobalOptions();
    _registerCommands();
  }

  late final ServiceContainer _services;
  late final MetricsCollector _metrics;
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

    // Initialize metrics collector
    final metricsConfig = MetricsConfig.fromEnvironment(isProd: !isDevelopment);
    _metrics = MetricsFactory(metricsConfig).create();

    _services = ServiceContainer()
      ..registerSingleton<Logger>(structuredLogger)
      ..registerSingleton<flylog.Logger>(_appLogger)
      ..registerSingleton<MetricsCollector>(_metrics)
      ..registerSingleton<PathResolver>(PathResolver(
        logger: structuredLogger,
        isDevelopment: isDevelopment,
      ))
      ..registerSingleton<TemplateManager>(TemplateManager(
        templatesDirectory: '', // Will be resolved by PathResolver
        logger: structuredLogger,
      ))
      ..registerSingleton<SystemChecker>(
          SystemChecker(logger: structuredLogger))
      ..registerSingleton<InteractivePrompt>(
          InteractivePrompt(structuredLogger));
  }

  /// Determine if running in development mode
  bool _isDevelopmentMode() {
    // Check if we're running from source (development) vs installed package
    final scriptPath = Platform.script.toFilePath();
    return scriptPath.contains('packages/fly_cli') ||
        scriptPath.contains('bin/fly.dart');
  }

  /// Register global options using flag registry
  void _registerGlobalOptions() {
    GlobalFlagsRegistry.applyToParser(argParser);
  }

  /// Register all commands using enum-based architecture
  void _registerCommands() {
    // Create a temporary context for command registration
    final tempParser = ArgParser();
    GlobalFlagsRegistry.applyToParser(tempParser);
    final context = _createContext(tempParser.parse([]));

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
    registrationData.commandGroups.values.forEach(addCommand);
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
      })
        ..info('Fly CLI start');

      // Handle version flag
      if (FlagAccessor.getBool(parsedArgs, const GlobalVersionFlag())) {
        final format = FlagAccessor.getStringOrDefault(
          parsedArgs,
          GlobalFormatFlag(),
          'human',
        );
        return _handleVersionFlag(format);
      }

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
    final workingDir = env.getString(EnvVar.flyOutputDir) ??
        env.getString(EnvVar.pwd) ??
        Directory.current.path;

    return CommandContextImpl(
      argResults: args,
      logger: _services.get<Logger>(),
      templateManager: _services.get<TemplateManager>(),
      systemChecker: _services.get<SystemChecker>(),
      interactivePrompt: _services.get<InteractivePrompt>(),
      pathResolver: _services.get<PathResolver>(),
      metricsCollector: _services.get<MetricsCollector>(),
      config: _getConfig(),
      environment: Environment.current(),
      workingDirectory: workingDir,
      verbose: FlagAccessor.getBool(args, const GlobalVerboseFlag()),
      quiet: FlagAccessor.getBool(args, const GlobalQuietFlag()),
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
    _appLogger
        .error('Unhandled error', error: e, stackTrace: stackTrace, fields: {
      'args': args.toList(),
      'cli_version': VersionUtils.getCurrentVersion(),
    });
    // Check for format flag (industry standard handling)
    final outputFormat = args.contains('--format=json')
        ? 'json'
        : args.contains('--format=ai')
            ? 'ai'
            : 'human';

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
