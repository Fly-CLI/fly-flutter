import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/cli/bootstrapping/service_bootstrapper.dart';
import 'package:fly_cli/src/core/cli/bootstrapping/service_bootstrapper_factory.dart';
import 'package:fly_cli/src/core/cli/output_format.dart';
import 'package:fly_cli/src/core/cli/error_handling/error_handler.dart';
import 'package:fly_cli/src/core/cli/formatting/output_format_parser.dart';
import 'package:fly_cli/src/core/cli/formatting/output_formatter.dart';
import 'package:fly_cli/src/core/cli/interfaces/i_context_factory.dart';
import 'package:fly_cli/src/core/cli/interfaces/i_output_formatter.dart';
import 'package:fly_cli/src/core/cli/registration/command_registrar.dart';
import 'package:fly_cli/src/core/command/foundation/flags/cli_flags.dart';
import 'package:fly_cli/src/core/command/foundation/flags/flag_accessor.dart';
import 'package:fly_cli/src/core/command/foundation/flags/global_flags_registry.dart';
import 'package:fly_cli/src/core/utils/version_utils.dart';
import 'package:mason_logger/mason_logger.dart';

/// Enhanced Fly CLI Command Runner with SOLID principles
///
/// This class orchestrates command execution by delegating to specialized
/// components for service initialization, command registration, output formatting,
/// and error handling.
class FlyCommandRunner extends CommandRunner<int> {
  /// Create a FlyCommandRunner with default configuration
  ///
  /// Automatically detects the environment and initializes all services.
  /// Parses global flags early from args to initialize logger with correct settings.
  ///
  /// [args] - Command line arguments to parse global flags early
  factory FlyCommandRunner.create(Iterable<String> args) {
    // Parse global flags early for logger initialization
    final globalParser = GlobalFlagsRegistry.createGlobalParser();
    ArgResults? parsedGlobalArgs;
    try {
      parsedGlobalArgs = globalParser.parse(args);
    } catch (_) {
      // If parsing fails (e.g., unknown command), continue without parsed args
      // The logger will be initialized with defaults and rebuilt later in run()
      parsedGlobalArgs = null;
    }

    final bootstrapper = ServiceBootstrapperFactory.create(args: args);
    final formatter = OutputFormatter();
    final errorHandler = ErrorHandler(
      formatter: formatter,
      logger: bootstrapper.container.get<Logger>(),
    );

    return FlyCommandRunner._(
      bootstrapper: bootstrapper,
      formatter: formatter,
      errorHandler: errorHandler,
      parsedGlobalArgs: parsedGlobalArgs,
    );
  }

  /// Create a FlyCommandRunner with custom dependencies
  ///
  /// This constructor allows injection of dependencies for testing.
  ///
  /// [bootstrapper] - Service bootstrapper for service initialization
  /// [formatter] - Output formatter for formatting output
  /// [errorHandler] - Error handler for error handling
  /// [parsedGlobalArgs] - Optional parsed global arguments (for early initialization)
  FlyCommandRunner._({
    required ServiceBootstrapper bootstrapper,
    required IOutputFormatter formatter,
    required ErrorHandler errorHandler,
    ArgResults? parsedGlobalArgs,
  })  : _bootstrapper = bootstrapper,
        _formatter = formatter,
        _errorHandler = errorHandler,
        _parsedGlobalArgs = parsedGlobalArgs,
        super('fly', 'AI-native Flutter CLI tool') {
    _registerGlobalOptions();
    _registerCommands();
  }

  final ServiceBootstrapper _bootstrapper;
  final IOutputFormatter _formatter;
  final ErrorHandler _errorHandler;
  final ArgResults? _parsedGlobalArgs;

  /// Get the service bootstrapper
  ServiceBootstrapper get bootstrapper => _bootstrapper;

  /// Get the context factory for creating execution contexts
  ///
  /// This factory is accessible to commands for creating execution contexts
  /// with actual arguments during command execution.
  IContextFactory get contextFactory => _bootstrapper.contextFactory;

  /// Register global options using flag registry
  void _registerGlobalOptions() {
    GlobalFlagsRegistry.applyToParser(argParser);
  }

  /// Register all commands using enum-based architecture
  void _registerCommands() {
    final registrar = CommandRegistrar(_bootstrapper.contextFactory);
    registrar.registerCommands(this, GlobalFlagsRegistry.globalFlags);
  }

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      // Parse arguments to check for global flags
      final parsedArgs = argParser.parse(args);

      // Rebuild logging with CLI overrides if not already initialized with parsed args
      // (If we already parsed global args in create(), this is a no-op for global flags)
      if (_parsedGlobalArgs == null || _parsedGlobalArgs != parsedArgs) {
        _bootstrapper.rebuildLogger(parsedArgs);
      }

      final traceId = DateTime.now().microsecondsSinceEpoch.toString();
      final runLogger = _bootstrapper.appLogger.child({
        'trace_id': traceId,
        'args': args.toList(),
        'working_dir': Directory.current.path,
        'cli_version': VersionUtils.getCurrentVersion(),
      })
        ..info('Fly CLI start');

      // Handle version flag
      if (FlagAccessor.getBool(parsedArgs, const GlobalVersionFlag())) {
        final format = OutputFormatParser.parseFromArgResults(parsedArgs);
        return _handleVersionFlag(format);
      }

      // Run the command
      // Note: Context update happens in FlyCommand.run() at the very start,
      // ensuring context has correct args before any code accesses it
      final result = await super.run(args);
      runLogger.info('Fly CLI finish', fields: {'exit_code': result ?? 1});
      return result ?? 1;
    } on UsageException catch (e, stackTrace) {
      return await _errorHandler.handleError(
        e,
        stackTrace,
        args,
        isVerbose: args.contains('--verbose'),
      );
    } catch (e, stackTrace) {
      return await _errorHandler.handleError(
        e,
        stackTrace,
        args,
        isVerbose: args.contains('--verbose'),
      );
    }
  }

  /// Handle version flag using OutputFormatter
  int _handleVersionFlag(OutputFormat format) {
    final versionInfo = VersionUtils.getVersionInfo().toJson();
    final formattedOutput = _formatter.formatVersion(versionInfo, format);
    // Use stdout instead of print for better control
    stdout.writeln(formattedOutput);
    return 0; // Success
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
