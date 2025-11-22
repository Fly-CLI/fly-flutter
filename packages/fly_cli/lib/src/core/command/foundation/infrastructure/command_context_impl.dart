import 'dart:io';

import 'package:args/args.dart';
import 'package:fly_cli/src/core/cli/interfaces/i_context_factory.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_execution_context.dart';
import 'package:fly_cli/src/core/command/foundation/flags/cli_flags.dart';
import 'package:fly_cli/src/core/command/foundation/flags/flag_accessor.dart';
import 'package:fly_cli/src/core/command/foundation/infrastructure/interactive_prompt.dart';
import 'package:fly_cli/src/core/diagnostics/system_checker.dart';
import 'package:fly_cli/src/core/path_management/path_resolver.dart';
import 'package:fly_cli/src/core/telemetry/domain/metrics_collector.dart';
import 'package:fly_cli/src/core/templates/template/template_manager.dart';
import 'package:fly_core/src/environment/env_var.dart';
import 'package:fly_core/src/environment/environment_manager.dart';
import 'package:mason_logger/mason_logger.dart';

/// Environment information for command execution
class Environment {
  const Environment({
    required this.isWindows,
    required this.isMacOS,
    required this.isLinux,
    required this.isUnix,
    required this.pathSeparator,
    required this.homeDirectory,
    required this.tempDirectory,
  });

  final bool isWindows;
  final bool isMacOS;
  final bool isLinux;
  final bool isUnix;
  final String pathSeparator;
  final String homeDirectory;
  final String tempDirectory;

  factory Environment.current() {
    return Environment(
      isWindows: Platform.isWindows,
      isMacOS: Platform.isMacOS,
      isLinux: Platform.isLinux,
      isUnix: Platform.isLinux || Platform.isMacOS,
      pathSeparator: Platform.pathSeparator,
      homeDirectory: const EnvironmentManager().getString(EnvVar.home) ??
          const EnvironmentManager().getString(EnvVar.userProfile) ??
          '',
      tempDirectory: Directory.systemTemp.path,
    );
  }
}

/// Concrete implementation of CommandContext
///
/// ## Context Lifecycle
///
/// CommandContext instances have two distinct immutable phases:
///
/// ### 1. Registration Phase (Setup)
/// During command registration, a context is created with **empty arguments**
/// (`argParser.parse([])`). This context is used only for:
/// - Command instance creation
/// - Command metadata extraction
/// - Command setup and initialization
///
/// **Important**: This context should NOT be used for execution logic.
/// The `argResults` field contains empty args during this phase and is immutable.
///
/// ### 2. Execution Phase (Runtime)
/// During command execution, a **new immutable context** is created with **actual arguments**
/// from the command line. This context is created via `ContextFactory.createExecutionContext()`:
/// - The `argResults` field is set to the parsed command arguments at creation time
/// - All computed properties (e.g., `jsonOutput`, `planMode`, `verbose`) are
///   calculated based on the actual args from the start
/// - The context is immutable and ready for use by validators, middleware, and command logic
///
/// **Note**: The `argResults` field is immutable (final) after context creation.
/// Contexts are created with the appropriate args for their lifecycle phase.
///
/// ## Usage Example
///
/// ```dart
/// // Registration: Context created with empty args (immutable)
/// final registrationContext = factory.createRegistrationContext();
/// final command = MyCommand(registrationContext);
///
/// // Execution: New immutable context created with actual args
/// final executionContext = factory.createExecutionContext(parsedArgs);
/// // Use executionContext for command execution
/// ```
class CommandContextImpl implements CommandContext {
  CommandContextImpl({
    required this.argResults,
    required this.logger,
    required this.templateManager,
    required this.systemChecker,
    required this.interactivePrompt,
    required this.pathResolver,
    required this.metricsCollector,
    required this.config,
    required this.environment,
    required this.workingDirectory,
    required this.verbose,
    required this.quiet,
    required this.factory,
  });

  /// The parsed arguments for the current command
  ///
  /// **Lifecycle**: This field is immutable after context creation:
  /// - **Registration**: Set to empty args (`argParser.parse([])`) for command setup only
  /// - **Execution**: Set to actual parsed args when context is created, immutable from creation
  ///
  /// **Note**: All computed properties (`jsonOutput`, `planMode`, etc.) depend on
  /// this field. Contexts are created with the appropriate args for their lifecycle phase.
  @override
  final ArgResults argResults;

  @override
  final Logger logger;

  @override
  final TemplateManager templateManager;

  @override
  final SystemChecker systemChecker;

  @override
  final InteractivePrompt interactivePrompt;

  @override
  final PathResolver pathResolver;

  @override
  final MetricsCollector metricsCollector;

  @override
  final Map<String, dynamic> config;

  @override
  final Environment environment;

  @override
  final String workingDirectory;

  @override
  final bool verbose;

  @override
  final bool quiet;

  @override
  final IContextFactory factory;

  final Map<String, dynamic> _data = {};
  String? _commandName;

  @override
  bool get jsonOutput =>
      FlagAccessor.getString(argResults, GlobalFormatFlag()) == 'json';

  @override
  bool get aiOutput =>
      FlagAccessor.getString(argResults, GlobalFormatFlag()) == 'ai';

  @override
  bool get planMode =>
      FlagAccessor.getBool(argResults, const GlobalPlanFlag());

  @override
  String getErrorSuggestion(Object error) => _getErrorSuggestion(error);

  @override
  void setData(String key, dynamic value) {
    _data[key] = value;
  }

  @override
  dynamic getData(String key) {
    return _data[key];
  }

  @override
  CommandExecutionContext? get executionContext =>
      getData('execution_context') as CommandExecutionContext?;

  String? get commandName => _commandName;

  set commandName(String? value) {
    _commandName = value;
  }

  String _getErrorSuggestion(Object error) {
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('permission')) {
      return 'Try running with elevated permissions or check file permissions';
    } else if (errorString.contains('network')) {
      return 'Check your internet connection and try again';
    } else if (errorString.contains('not found')) {
      return 'Make sure Flutter is installed and in your PATH';
    } else if (errorString.contains('template')) {
      return 'Run "fly doctor" to check your setup or try a different template';
    }
    return 'Run "fly doctor" to diagnose system issues';
  }
}
