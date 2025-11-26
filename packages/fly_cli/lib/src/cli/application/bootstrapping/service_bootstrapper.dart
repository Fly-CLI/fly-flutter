import 'package:args/args.dart';
import 'package:fly_cli/src/cli/application/bootstrapping/service_bootstrapper_config.dart';
import 'package:fly_cli/src/cli/domain/interfaces/i_context_factory.dart';
import 'package:fly_cli/src/cli/domain/interfaces/i_logger_factory.dart';
import 'package:fly_cli/src/cli/domain/interfaces/i_metrics_collector_factory.dart';
import 'package:fly_cli/src/cli/domain/interfaces/i_service_container.dart';
import 'package:fly_cli/src/cli/infrastructure/path_management/path_resolver.dart';
import 'package:fly_cli/src/cli/infrastructure/telemetry/domain/metric.dart';
import 'package:fly_cli/src/cli/infrastructure/telemetry/domain/metrics_collector.dart';
import 'package:fly_cli/src/cli/infrastructure/telemetry/infrastructure/metrics_config.dart';
import 'package:fly_cli/src/cli/infrastructure/telemetry/infrastructure/metrics_factory.dart';
import 'package:fly_cli/src/features/commands/infrastructure/context_factory.dart';
import 'package:fly_cli/src/features/commands/infrastructure/interactive_prompt.dart';
import 'package:fly_cli/src/features/diagnostics/domain/system_checker.dart';
import 'package:fly_cli/src/features/generate/common/generation_command_handler.dart';
import 'package:fly_cli/src/generation/application/ports/icache_manager.dart';
import 'package:fly_cli/src/generation/application/ports/igeneration_engine.dart';
import 'package:fly_cli/src/generation/application/ports/ivariable_processor.dart';
import 'package:fly_cli/src/generation/application/ports/iworkflow_orchestrator.dart';
import 'package:fly_cli/src/generation/application/services/variable_processing_service.dart';
import 'package:fly_cli/src/generation/application/use_cases/generate_feature_use_case.dart';
import 'package:fly_cli/src/generation/application/use_cases/generate_project_use_case.dart';
import 'package:fly_cli/src/generation/application/use_cases/generate_service_use_case.dart';
import 'package:fly_cli/src/generation/brick/brick_registry.dart';
import 'package:fly_cli/src/generation/domain/repositories/ibrick_repository.dart';
import 'package:fly_cli/src/generation/domain/repositories/itemplate_repository.dart';
import 'package:fly_cli/src/generation/domain/repositories/itemplate_validator.dart';
import 'package:fly_cli/src/generation/infrastructure/adapters/file_system_adapter.dart';
import 'package:fly_cli/src/generation/infrastructure/adapters/ifile_system_adapter.dart';
import 'package:fly_cli/src/generation/infrastructure/adapters/imason_adapter.dart';
import 'package:fly_cli/src/generation/infrastructure/adapters/mason_adapter.dart';
import 'package:fly_cli/src/generation/infrastructure/brick/brick_repository_impl.dart';
import 'package:fly_cli/src/generation/infrastructure/generation/mason_generation_engine.dart';
import 'package:fly_cli/src/generation/infrastructure/template/template_cache_impl.dart';
import 'package:fly_cli/src/generation/infrastructure/template/template_repository_impl.dart';
import 'package:fly_cli/src/generation/infrastructure/template/template_validator_impl.dart';
import 'package:fly_cli/src/generation/infrastructure/workflow/workflow_orchestrator_impl.dart';
import 'package:fly_cli/src/generation/template/template_info.dart';
import 'package:fly_cli/src/generation/template/template_manager.dart';
import 'package:fly_cli/src/generation/versioning/compatibility_checker.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/adapters/generation_mcp_adapter.dart';
import 'package:fly_cli/src/shared/di/service_container.dart';
import 'package:fly_cli/src/shared/logging/domain/logger.dart' as flylog;
import 'package:fly_cli/src/shared/logging/infrastructure/logging_bootstrap.dart';
import 'package:fly_cli/src/shared/logging/infrastructure/structured_mason_logger.dart';
import 'package:fly_cli/src/shared/utils/version_utils.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_semver/pub_semver.dart';

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
  }) : _loggerFactory = loggerFactory ?? _DefaultLoggerFactory(),
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
      final metricsConfig = MetricsConfig.fromEnvironment(
        isProd: !config.isDevelopment,
      );
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
      ..registerSingleton<PathResolver>(
        PathResolver(
          logger: structuredLogger,
          isDevelopment: config.isDevelopment,
        ),
      )
      // Register TemplateManager as factory (lazy initialization)
      // This avoids expensive initialization for simple commands like --version
      ..registerFactory<TemplateManager>(
        () => TemplateManager(
          templatesDirectory:
              config.templatesDirectory ??
              TemplateManager.findTemplatesDirectory(),
          logger: structuredLogger,
        ),
      )
      ..registerSingleton<SystemChecker>(
        SystemChecker(logger: structuredLogger),
      )
      ..registerSingleton<InteractivePrompt>(
        InteractivePrompt(structuredLogger),
      );

    // Register architecture components
    _registerArchitectureComponents(structuredLogger, config);

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
    (_container as ServiceContainer).registerSingleton<flylog.Logger>(
      _appLogger,
    );
  }

  /// Register all architecture components.
  ///
  /// This method registers repositories, services, use cases, handlers,
  /// and adapters following Clean Architecture principles.
  void _registerArchitectureComponents(
    StructuredMasonLogger structuredLogger,
    ServiceBootstrapperConfig config,
  ) {
    final container = _container as ServiceContainer;

    // Register infrastructure adapters

    container
      ..registerSingleton<IFileSystemAdapter>(const FileSystemAdapter())
      ..registerSingleton<IMasonAdapter>(const MasonAdapter())
      // Register repositories
      // Create BrickRegistry with logger
      ..registerFactory<BrickRegistry>(
        () => BrickRegistry(
          logger: structuredLogger,
        ),
      )
      // Register BrickRepository implementation
      ..registerFactory<IBrickRepository>(() {
        final brickRegistry = container.get<BrickRegistry>();
        return BrickRepositoryImpl(brickRegistry: brickRegistry);
      })
      // Register TemplateCache
      ..registerSingleton<ICacheManager<TemplateInfo>>(
        TemplateCacheImpl(),
      )
      // Register CompatibilityChecker (lazy initialization)
      // Note: CompatibilityChecker requires async SDK version detection,
      // so we create it lazily when first needed
      ..registerFactory<CompatibilityChecker>(() {
        // This will be initialized lazily when first used
        // For now, use default versions - actual versions will be detected on first use
        final cliVersion = Version.parse(VersionUtils.getCurrentVersion());
        // Use safe defaults - actual versions will be detected by SdkVersionCache
        return CompatibilityChecker(
          currentCliVersion: cliVersion,
          currentFlutterVersion: Version.parse('3.10.0'),
          // Default, will be updated
          currentDartVersion: Version.parse(
            '3.0.0',
          ), // Default, will be updated
        );
      })
      // Register TemplateValidator
      ..registerFactory<ITemplateValidator>(() {
        final compatibilityChecker = container.get<CompatibilityChecker>();
        return TemplateValidatorImpl(
          compatibilityChecker: compatibilityChecker,
          logger: structuredLogger,
        );
      })
      // Register TemplateRepository implementation
      ..registerFactory<ITemplateRepository>(() {
        final templateManager = container.get<TemplateManager>();
        final templateCache = container.get<ICacheManager<TemplateInfo>>();
        final templateValidator = container.get<ITemplateValidator>();
        return TemplateRepositoryImpl(
          templateManager: templateManager,
          templateCache: templateCache,
          templateValidator: templateValidator,
        );
      })
      // Register services
      ..registerSingleton<IVariableProcessor>(
        VariableProcessingService(),
      )
      ..registerSingleton<IGenerationEngine>(
        MasonGenerationEngine(
          masonAdapter: container.get<IMasonAdapter>(),
          logger: structuredLogger,
        ),
      )
      // Register workflow orchestrator
      ..registerFactory<IWorkflowOrchestrator>(() {
        return WorkflowOrchestratorImpl(
          templateManager: container.get<TemplateManager>(),
          brickRepository: container.get<IBrickRepository>(),
          variableProcessor: container.get<IVariableProcessor>(),
          generationEngine: container.get<IGenerationEngine>(),
          logger: structuredLogger,
        );
      })
      // Register use cases (all delegate to the workflow orchestrator)
      ..registerSingleton<GenerateFeatureUseCase>(
        GenerateFeatureUseCase(
          workflowOrchestrator: container.get<IWorkflowOrchestrator>(),
        ),
      )
      ..registerSingleton<GenerateServiceUseCase>(
        GenerateServiceUseCase(
          workflowOrchestrator: container.get<IWorkflowOrchestrator>(),
        ),
      )
      ..registerSingleton<GenerateProjectUseCase>(
        GenerateProjectUseCase(
          workflowOrchestrator: container.get<IWorkflowOrchestrator>(),
        ),
      )
      // Register command handler
      ..registerSingleton<GenerationCommandHandler>(
        GenerationCommandHandler(
          generateFeatureUseCase: container.get<GenerateFeatureUseCase>(),
          generateServiceUseCase: container.get<GenerateServiceUseCase>(),
          generateProjectUseCase: container.get<GenerateProjectUseCase>(),
        ),
      )
      // Register MCP adapter
      ..registerSingleton<GenerationMcpAdapter>(
        GenerationMcpAdapter(
          generateFeatureUseCase: container.get<GenerateFeatureUseCase>(),
          generateServiceUseCase: container.get<GenerateServiceUseCase>(),
          generateProjectUseCase: container.get<GenerateProjectUseCase>(),
        ),
      );
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
  double getAverageExecutionTime(String operation) => 0;

  @override
  int getExecutionCount(String operation) => 0;

  @override
  int getErrorCount(String operation) => 0;

  @override
  double getSuccessRate(String operation) => 1;

  @override
  void clear() {}

  @override
  void clearByOperation(String operation) {}

  @override
  Future<void> export() async {}
}
