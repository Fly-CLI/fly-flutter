import 'dart:io';

import 'package:args/args.dart';
import 'package:fly_cli/src/cli/domain/interfaces/i_context_factory.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/infrastructure/flags/cli_flags.dart';
import 'package:fly_cli/src/features/commands/infrastructure/flags/flag_accessor.dart';
import 'package:fly_cli/src/features/commands/infrastructure/flags/global_flags_registry.dart';
import 'package:fly_cli/src/features/commands/infrastructure/command_context_impl.dart';
import 'package:fly_cli/src/features/commands/infrastructure/interactive_prompt.dart';
import 'package:fly_cli/src/shared/di/service_container.dart';
import 'package:fly_cli/src/features/diagnostics/domain/system_checker.dart';
import 'package:fly_cli/src/cli/infrastructure/path_management/path_resolver.dart';
import 'package:fly_cli/src/cli/infrastructure/telemetry/domain/metrics_collector.dart';
import 'package:fly_cli/src/generation/template/template_manager.dart';
import 'package:fly_cli/src/shared/utils/version_utils.dart';
import 'package:fly_core/src/environment/env_var.dart';
import 'package:fly_core/src/environment/environment_manager.dart';
import 'package:mason_logger/mason_logger.dart';

/// Factory for creating CommandContext instances
///
/// This factory centralizes context creation logic, making it reusable for
/// both production and testing. It provides clear separation between:
/// - **Registration contexts**: Created during command setup with empty args
/// - **Execution contexts**: Created during command execution with actual args
///
/// Example usage:
/// ```dart
/// // Production: Create factory with service container
/// final factory = ContextFactory(services);
/// final context = factory.createExecutionContext(parsedArgs);
///
/// // Testing: Create factory with test services
/// final testFactory = ContextFactory(testServices);
/// final testContext = testFactory.createTestContext(testArgs);
/// ```
class ContextFactory implements IContextFactory {
  /// Creates a new ContextFactory
  ///
  /// [services] - Service container providing all required dependencies
  /// [config] - Optional configuration map. If not provided, default config is used
  /// [workingDirectory] - Optional working directory. If not provided, resolved from environment
  ContextFactory(
    this.services, {
    Map<String, dynamic>? config,
    String? workingDirectory,
  })  : _config = config,
        _workingDirectory = workingDirectory;

  /// Service container providing all required dependencies
  final ServiceContainer services;

  /// Optional configuration map
  final Map<String, dynamic>? _config;

  /// Optional working directory
  final String? _workingDirectory;

  /// Creates a minimal context for command registration (setup only)
  ///
  /// This context is used during command setup when actual arguments are not
  /// yet available. It uses empty args and is suitable only for command
  /// initialization, not for execution.
  ///
  /// **Note**: This context should NOT be used for command execution.
  /// Use [createExecutionContext] instead for execution contexts.
  CommandContext createRegistrationContext() {
    final emptyArgs = GlobalFlagsRegistry.createGlobalParser().parse([]);
    return _createContext(emptyArgs);
  }

  /// Creates a full context for command execution with actual arguments
  ///
  /// This context is used during command execution when actual arguments
  /// are available. It includes all flags and options from the parsed args.
  ///
  /// [args] - Parsed command arguments
  CommandContext createExecutionContext(ArgResults args) {
    return _createContext(args);
  }

  /// Creates a test context with optional overrides
  ///
  /// This method is designed for testing scenarios where you want to
  /// override specific services or configuration.
  ///
  /// [args] - Parsed command arguments (defaults to empty args)
  /// [services] - Optional service container override (uses factory's services if not provided)
  /// [config] - Optional configuration override
  /// [workingDirectory] - Optional working directory override
  /// [factory] - Optional factory override (uses this factory if not provided)
  @override
  CommandContext createTestContext(
    ArgResults args, {
    dynamic services,
    Map<String, dynamic>? config,
    String? workingDirectory,
    IContextFactory? factory,
  }) {
    final effectiveServices = (services as ServiceContainer?) ?? this.services;
    final effectiveConfig = config ?? _config ?? _getDefaultConfig();
    final effectiveWorkingDir =
        workingDirectory ?? _workingDirectory ?? _resolveWorkingDirectory();
    final effectiveFactory = factory ?? this;

    return CommandContextImpl(
      argResults: args,
      logger: effectiveServices.get<Logger>(),
      templateManager: effectiveServices.get<TemplateManager>(),
      systemChecker: effectiveServices.get<SystemChecker>(),
      interactivePrompt: effectiveServices.get<InteractivePrompt>(),
      pathResolver: effectiveServices.get<PathResolver>(),
      metricsCollector: effectiveServices.get<MetricsCollector>(),
      config: effectiveConfig,
      environment: Environment.current(),
      workingDirectory: effectiveWorkingDir,
      verbose: FlagAccessor.getBool(args, const GlobalVerboseFlag()),
      quiet: FlagAccessor.getBool(args, const GlobalQuietFlag()),
      factory: effectiveFactory,
    );
  }

  /// Internal method to create a context with the given arguments
  CommandContext _createContext(ArgResults args) {
    return CommandContextImpl(
      argResults: args,
      logger: services.get(),
      templateManager: services.get(),
      systemChecker: services.get(),
      interactivePrompt: services.get(),
      pathResolver: services.get(),
      metricsCollector: services.get(),
      config: _config ?? _getDefaultConfig(),
      environment: Environment.current(),
      workingDirectory: _workingDirectory ?? _resolveWorkingDirectory(),
      verbose: FlagAccessor.getBool(args, const GlobalVerboseFlag()),
      quiet: FlagAccessor.getBool(args, const GlobalQuietFlag()),
      factory: this,
    );
  }

  /// Resolves working directory from environment variables
  ///
  /// Respects environment variables for working directory (12-Factor App pattern):
  /// - FLY_OUTPUT_DIR for explicit test control
  /// - PWD for Unix standard
  /// - Falls back to current directory
  String _resolveWorkingDirectory() {
    const env = EnvironmentManager();
    return env.getString(EnvVar.flyOutputDir) ??
        env.getString(EnvVar.pwd) ??
        Directory.current.path;
  }

  /// Gets default configuration map
  Map<String, dynamic> _getDefaultConfig() => {
        'cli_version': VersionUtils.getCurrentVersion(),
        'templates_directory': TemplateManager.findTemplatesDirectory(),
        'plugins_enabled': true,
      };
}

