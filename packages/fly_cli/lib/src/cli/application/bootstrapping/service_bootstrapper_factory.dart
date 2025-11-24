import 'package:args/args.dart';
import 'package:fly_cli/src/cli/application/bootstrapping/environment_detector.dart';
import 'package:fly_cli/src/cli/application/bootstrapping/service_bootstrapper.dart';
import 'package:fly_cli/src/cli/application/bootstrapping/service_bootstrapper_config.dart';
import 'package:fly_cli/src/features/commands/infrastructure/flags/global_flags_registry.dart';

/// Factory for creating service bootstrappers with different configurations
class ServiceBootstrapperFactory {
  /// Create a bootstrapper for production mode
  ///
  /// Automatically detects the environment and creates appropriate configuration.
  ///
  /// [args] - Optional command line arguments to parse global flags early.
  static ServiceBootstrapper createProduction({Iterable<String>? args}) {
    final config = ServiceBootstrapperConfig.production();
    final bootstrapper = ServiceBootstrapper(config);

    ArgResults? parsedGlobalArgs;
    if (args != null) {
      try {
        final globalParser = _createGlobalParser();
        parsedGlobalArgs = globalParser.parse(args);
      } catch (_) {
        parsedGlobalArgs = null;
      }
    }

    bootstrapper.initialize(parsedGlobalArgs: parsedGlobalArgs);
    return bootstrapper;
  }

  /// Create a bootstrapper for development mode
  ///
  /// Automatically detects the environment and creates appropriate configuration.
  ///
  /// [args] - Optional command line arguments to parse global flags early.
  static ServiceBootstrapper createDevelopment({Iterable<String>? args}) {
    final config = ServiceBootstrapperConfig.development();
    final bootstrapper = ServiceBootstrapper(config);

    ArgResults? parsedGlobalArgs;
    if (args != null) {
      try {
        final globalParser = _createGlobalParser();
        parsedGlobalArgs = globalParser.parse(args);
      } catch (_) {
        parsedGlobalArgs = null;
      }
    }

    bootstrapper.initialize(parsedGlobalArgs: parsedGlobalArgs);
    return bootstrapper;
  }

  /// Create a bootstrapper with auto-detected environment
  ///
  /// Automatically detects whether running in development or production mode
  /// and creates appropriate configuration.
  ///
  /// [args] - Optional command line arguments to parse global flags early.
  /// If provided, global flags will be parsed and logger initialized with them.
  static ServiceBootstrapper create({Iterable<String>? args}) {
    final isDevelopment = EnvironmentDetector.isDevelopmentMode();
    final config = isDevelopment
        ? ServiceBootstrapperConfig.development()
        : ServiceBootstrapperConfig.production();
    final bootstrapper = ServiceBootstrapper(config);

    // Parse global flags early if args provided
    ArgResults? parsedGlobalArgs;
    if (args != null) {
      try {
        final globalParser = _createGlobalParser();
        parsedGlobalArgs = globalParser.parse(args);
      } catch (_) {
        // If parsing fails (e.g., unknown command), continue without parsed args
        // The logger will be initialized with defaults and rebuilt later
        parsedGlobalArgs = null;
      }
    }

    bootstrapper.initialize(parsedGlobalArgs: parsedGlobalArgs);
    return bootstrapper;
  }

  /// Create a parser with only global flags for early parsing
  static ArgParser _createGlobalParser() {
    return GlobalFlagsRegistry.createGlobalParser();
  }

  /// Create a bootstrapper for testing
  ///
  /// Creates a bootstrapper with test-friendly configuration:
  /// - Development mode enabled
  /// - Metrics disabled by default
  /// - Custom logger name
  ///
  /// [args] - Optional command line arguments to parse global flags early.
  static ServiceBootstrapper createTest({
    String loggerName = 'fly_test',
    bool enableMetrics = false,
    Iterable<String>? args,
  }) {
    final config = ServiceBootstrapperConfig.test(
      loggerName: loggerName,
      enableMetrics: enableMetrics,
    );
    final bootstrapper = ServiceBootstrapper(config);

    ArgResults? parsedGlobalArgs;
    if (args != null) {
      try {
        final globalParser = _createGlobalParser();
        parsedGlobalArgs = globalParser.parse(args);
      } catch (_) {
        parsedGlobalArgs = null;
      }
    }

    bootstrapper.initialize(parsedGlobalArgs: parsedGlobalArgs);
    return bootstrapper;
  }
}
