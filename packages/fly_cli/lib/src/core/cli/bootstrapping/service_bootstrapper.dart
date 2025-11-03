import 'package:args/args.dart';
import 'package:fly_cli/src/core/cli/bootstrapping/service_bootstrapper_config.dart';
import 'package:fly_cli/src/core/cli/interfaces/i_context_factory.dart';
import 'package:fly_cli/src/core/cli/interfaces/i_logger_factory.dart';
import 'package:fly_cli/src/core/cli/interfaces/i_metrics_collector_factory.dart';
import 'package:fly_cli/src/core/cli/interfaces/i_service_container.dart';
import 'package:fly_cli/src/core/command/foundation/infrastructure/context_factory.dart';
import 'package:fly_cli/src/core/command/foundation/infrastructure/interactive_prompt.dart';
import 'package:fly_cli/src/core/dependency_injection/service_container.dart';
import 'package:fly_cli/src/core/diagnostics/system_checker.dart';
import 'package:fly_cli/src/core/logging/logger.dart' as flylog;
import 'package:fly_cli/src/core/logging/logging_bootstrap.dart';
import 'package:fly_cli/src/core/logging/structured_mason_logger.dart';
import 'package:fly_cli/src/core/path_management/path_resolver.dart';
import 'package:fly_cli/src/core/telemetry/domain/metric.dart';
import 'package:fly_cli/src/core/telemetry/domain/metrics_collector.dart';
import 'package:fly_cli/src/core/telemetry/infrastructure/metrics_config.dart';
import 'package:fly_cli/src/core/telemetry/infrastructure/metrics_factory.dart';
import 'package:fly_cli/src/core/templates/template_manager.dart';
import 'package:mason_logger/mason_logger.dart';

/// Bootstraps and initializes all services for the CLI
///
/// This class handles all service registration and initialization,
/// separating service setup from command runner logic.
class ServiceBootstrapper {
  /// Create a new service bootstrapper
  ///
  /// [config] - Configuration for service initialization
  /// [loggerFactory] - Optional logger factory (uses default if not provided)
  /// [metricsFactory] - Optional metrics factory (uses default if not provided)
  ServiceBootstrapper(
    this.config, {
    ILoggerFactory? loggerFactory,
    IMetricsCollectorFactory? metricsFactory,
  })  : _loggerFactory = loggerFactory ?? _DefaultLoggerFactory(),
        _metricsFactory = metricsFactory ?? _DefaultMetricsCollectorFactory();

  final ServiceBootstrapperConfig config;
  final ILoggerFactory _loggerFactory;
  final IMetricsCollectorFactory _metricsFactory;

  late final IServiceContainer _container;
  late final MetricsCollector _metrics;
  late flylog.Logger _appLogger;
  late final IContextFactory _contextFactory;

  /// Get the initialized service container
  IServiceContainer get container => _container;

  /// Get the initialized metrics collector
  MetricsCollector get metrics => _metrics;

  /// Get the initialized app logger
  flylog.Logger get appLogger => _appLogger;

  /// Get the initialized context factory
  IContextFactory get contextFactory => _contextFactory;

  /// Initialize all services
  ///
  /// This method registers all required services in the service container
  /// and creates the context factory.
  ///
  /// [parsedGlobalArgs] - Optional parsed global arguments for early logger initialization.
  /// If provided, logger will be initialized with these args from the start.
  void initialize({ArgResults? parsedGlobalArgs}) {
    final baseMason = Logger();

    // Initialize structured logging (root logger) with parsed args if available
    _appLogger = _loggerFactory.createRootLogger(
      isDevelopment: config.isDevelopment,
      parsedArgs: parsedGlobalArgs,
      loggerName: config.loggerName,
    );

    final structuredLogger = StructuredMasonLogger(baseMason, _appLogger);

    // Initialize metrics collector if enabled
    if (config.enableMetrics) {
      final metricsConfig =
          MetricsConfig.fromEnvironment(isProd: !config.isDevelopment);
      _metrics = _metricsFactory.create(metricsConfig);
    } else {
      // Create a no-op metrics collector
      _metrics = _NoOpMetricsCollector();
    }

    // Create service container
    _container = ServiceContainer()
      ..registerSingleton<Logger>(structuredLogger)
      ..registerSingleton<flylog.Logger>(_appLogger)
      ..registerSingleton<MetricsCollector>(_metrics)
      ..registerSingleton<PathResolver>(PathResolver(
        logger: structuredLogger,
        isDevelopment: config.isDevelopment,
      ))
      ..registerSingleton<TemplateManager>(TemplateManager(
        templatesDirectory: config.templatesDirectory ?? '',
        logger: structuredLogger,
      ))
      ..registerSingleton<SystemChecker>(
          SystemChecker(logger: structuredLogger))
      ..registerSingleton<InteractivePrompt>(
          InteractivePrompt(structuredLogger));

    // Initialize context factory after services are ready
    _contextFactory = ContextFactory(_container as ServiceContainer);
  }

  /// Rebuild logger with CLI overrides from parsed arguments
  ///
  /// This is called during command execution to apply CLI-specific
  /// logging configuration (e.g., --log-level, --log-format).
  ///
  /// [parsedArgs] - Parsed command arguments
  void rebuildLogger(ArgResults parsedArgs) {
    _appLogger = _loggerFactory.createRootLogger(
      isDevelopment: config.isDevelopment,
      parsedArgs: parsedArgs,
      loggerName: config.loggerName,
    );

    // Update logger in service container
    (_container as ServiceContainer)
        .registerSingleton<flylog.Logger>(_appLogger);
  }
}

/// Default logger factory implementation
class _DefaultLoggerFactory implements ILoggerFactory {
  @override
  flylog.Logger createRootLogger({
    required bool isDevelopment,
    ArgResults? parsedArgs,
    String loggerName = 'fly',
  }) {
    return LoggingBootstrap.createRootLogger(
      isDevelopment: isDevelopment,
      parsedArgs: parsedArgs,
      loggerName: loggerName,
    );
  }
}

/// Default metrics collector factory implementation
class _DefaultMetricsCollectorFactory implements IMetricsCollectorFactory {
  @override
  MetricsCollector create(MetricsConfig config) {
    return MetricsFactory(config).create();
  }
}

/// No-op metrics collector for when metrics are disabled
class _NoOpMetricsCollector implements MetricsCollector {
  @override
  void recordDuration(
    String operation,
    int milliseconds, {
    Map<String, String>? tags,
  }) {}

  @override
  void recordError(
    String operation,
    String error, {
    Map<String, String>? tags,
  }) {}

  @override
  void incrementCounter(
    String name, {
    int amount = 1,
    Map<String, String>? tags,
  }) {}

  @override
  void recordGauge(
    String name,
    num value, {
    String? unit,
    Map<String, String>? tags,
  }) {}

  @override
  void startTimer(String name) {}

  @override
  void stopTimer(
    String name, {
    Map<String, String>? tags,
  }) {}

  @override
  MetricSnapshot? getMetric(String name) => null;

  @override
  Map<String, MetricSnapshot> getAllMetrics() => {};

  @override
  Map<String, MetricSnapshot> getMetricsByOperation(String operation) => {};

  @override
  double getAverageExecutionTime(String operation) => 0.0;

  @override
  int getExecutionCount(String operation) => 0;

  @override
  int getErrorCount(String operation) => 0;

  @override
  double getSuccessRate(String operation) => 1.0;

  @override
  void clear() {}

  @override
  void clearByOperation(String operation) {}

  @override
  Future<void> export() async {}
}
