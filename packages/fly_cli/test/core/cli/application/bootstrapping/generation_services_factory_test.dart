import 'package:fly_cli/src/cli/application/bootstrapping/generation_services_factory.dart';
import 'package:fly_cli/src/cli/application/bootstrapping/service_bootstrapper_config.dart';
import 'package:fly_cli/src/cli/domain/interfaces/i_service_container.dart';
import 'package:fly_cli/src/generation/application/ports/icache_manager.dart';
import 'package:fly_cli/src/generation/application/ports/igeneration_engine.dart';
import 'package:fly_cli/src/generation/application/ports/ivariable_processor_factory.dart';
import 'package:fly_cli/src/generation/application/ports/iworkflow_orchestrator.dart';
import 'package:fly_cli/src/generation/application/services/processors/feature_variable_processor.dart';
import 'package:fly_cli/src/generation/application/services/processors/project_variable_processor.dart';
import 'package:fly_cli/src/generation/application/services/processors/service_variable_processor.dart';
import 'package:fly_cli/src/generation/application/strategies/feature_generation_executor.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_executor_registry.dart';
import 'package:fly_cli/src/generation/application/strategies/project_generation_executor.dart';
import 'package:fly_cli/src/generation/application/strategies/service_generation_executor.dart';
import 'package:fly_cli/src/generation/application/use_cases/generate_feature_use_case.dart';
import 'package:fly_cli/src/generation/application/use_cases/generate_project_use_case.dart';
import 'package:fly_cli/src/generation/application/use_cases/generate_service_use_case.dart';
import 'package:fly_cli/src/generation/brick/brick_registry.dart';
import 'package:fly_cli/src/generation/domain/repositories/ibrick_repository.dart';
import 'package:fly_cli/src/generation/domain/repositories/itemplate_repository.dart';
import 'package:fly_cli/src/generation/domain/repositories/itemplate_validator.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/generation/infrastructure/adapters/ifile_system_adapter.dart';
import 'package:fly_cli/src/generation/infrastructure/adapters/imason_adapter.dart';
import 'package:fly_cli/src/generation/template/template_info.dart';
import 'package:fly_cli/src/generation/template/template_manager.dart';
import 'package:fly_cli/src/generation/versioning/compatibility_checker.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/adapters/generation_mcp_adapter.dart';
import 'package:fly_cli/src/shared/di/service_container.dart';
import 'package:fly_cli/src/shared/logging/domain/log_level.dart';
import 'package:fly_cli/src/shared/logging/domain/logger.dart' as flylog;
import 'package:fly_cli/src/shared/logging/infrastructure/structured_mason_logger.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';

void main() {
  group('GenerationServicesFactory', () {
    late GenerationServicesFactory factory;
    late ServiceContainer container;
    late StructuredMasonLogger logger;
    late ServiceBootstrapperConfig config;

    setUp(() {
      factory = GenerationServicesFactory();
      container = ServiceContainer();
      logger = StructuredMasonLogger(Logger(), MockLogger());
      config = ServiceBootstrapperConfig.test();

      // Register TemplateManager as it's required by the factory
      // but is registered separately in ServiceBootstrapper
      container.registerFactory<TemplateManager>(
        () => TemplateManager(
          templatesDirectory: '/test/templates',
          logger: logger,
        ),
      );
    });

    test('should register all infrastructure adapters', () {
      factory.registerGenerationServices(
        container: container,
        logger: logger,
        config: config,
      );

      expect(container.isRegistered<IFileSystemAdapter>(), isTrue);
      expect(container.isRegistered<IMasonAdapter>(), isTrue);
      expect(container.get<IFileSystemAdapter>(), isNotNull);
      expect(container.get<IMasonAdapter>(), isNotNull);
    });

    test('should register repositories as factories', () {
      factory.registerGenerationServices(
        container: container,
        logger: logger,
        config: config,
      );

      expect(container.isRegistered<BrickRegistry>(), isTrue);
      expect(container.isRegistered<IBrickRepository>(), isTrue);
      expect(container.isRegistered<ITemplateRepository>(), isTrue);
      expect(container.isRegistered<ITemplateValidator>(), isTrue);

      // Factories should create instances on get
      final brickRegistry1 = container.get<BrickRegistry>();
      final brickRegistry2 = container.get<BrickRegistry>();
      // Factory registrations cache after first get, so instances should be the same
      expect(brickRegistry1, equals(brickRegistry2));
    });

    test('should register template cache as singleton', () {
      factory.registerGenerationServices(
        container: container,
        logger: logger,
        config: config,
      );

      expect(container.isRegistered<ICacheManager<TemplateInfo>>(), isTrue);
      final cache1 = container.get<ICacheManager<TemplateInfo>>();
      final cache2 = container.get<ICacheManager<TemplateInfo>>();
      expect(cache1, same(cache2));
    });

    test('should register compatibility checker as factory', () {
      factory.registerGenerationServices(
        container: container,
        logger: logger,
        config: config,
      );

      expect(container.isRegistered<CompatibilityChecker>(), isTrue);
      final checker = container.get<CompatibilityChecker>();
      expect(checker, isNotNull);
    });

    test('should register variable processors as singletons', () {
      factory.registerGenerationServices(
        container: container,
        logger: logger,
        config: config,
      );

      expect(container.isRegistered<ProjectVariableProcessor>(), isTrue);
      expect(container.isRegistered<FeatureVariableProcessor>(), isTrue);
      expect(container.isRegistered<ServiceVariableProcessor>(), isTrue);

      final projectProcessor1 = container.get<ProjectVariableProcessor>();
      final projectProcessor2 = container.get<ProjectVariableProcessor>();
      expect(projectProcessor1, same(projectProcessor2));

      final featureProcessor1 = container.get<FeatureVariableProcessor>();
      final featureProcessor2 = container.get<FeatureVariableProcessor>();
      expect(featureProcessor1, same(featureProcessor2));

      final serviceProcessor1 = container.get<ServiceVariableProcessor>();
      final serviceProcessor2 = container.get<ServiceVariableProcessor>();
      expect(serviceProcessor1, same(serviceProcessor2));
    });

    test('should register variable processor factory as singleton', () {
      factory.registerGenerationServices(
        container: container,
        logger: logger,
        config: config,
      );

      expect(container.isRegistered<IVariableProcessorFactory>(), isTrue);
      final factory1 = container.get<IVariableProcessorFactory>();
      final factory2 = container.get<IVariableProcessorFactory>();
      expect(factory1, same(factory2));
    });

    test('should register generation engine as singleton', () {
      factory.registerGenerationServices(
        container: container,
        logger: logger,
        config: config,
      );

      expect(container.isRegistered<IGenerationEngine>(), isTrue);
      final engine1 = container.get<IGenerationEngine>();
      final engine2 = container.get<IGenerationEngine>();
      expect(engine1, same(engine2));
    });

    test('should register workflow orchestrator as factory', () {
      factory.registerGenerationServices(
        container: container,
        logger: logger,
        config: config,
      );

      expect(container.isRegistered<IWorkflowOrchestrator>(), isTrue);
      final orchestrator1 = container.get<IWorkflowOrchestrator>();
      final orchestrator2 = container.get<IWorkflowOrchestrator>();
      // Factory registrations cache after first get
      expect(orchestrator1, equals(orchestrator2));
    });

    test('should register use cases as singletons', () {
      factory.registerGenerationServices(
        container: container,
        logger: logger,
        config: config,
      );

      expect(container.isRegistered<GenerateFeatureUseCase>(), isTrue);
      expect(container.isRegistered<GenerateServiceUseCase>(), isTrue);
      expect(container.isRegistered<GenerateProjectUseCase>(), isTrue);

      final featureUseCase1 = container.get<GenerateFeatureUseCase>();
      final featureUseCase2 = container.get<GenerateFeatureUseCase>();
      expect(featureUseCase1, same(featureUseCase2));

      final serviceUseCase1 = container.get<GenerateServiceUseCase>();
      final serviceUseCase2 = container.get<GenerateServiceUseCase>();
      expect(serviceUseCase1, same(serviceUseCase2));

      final projectUseCase1 = container.get<GenerateProjectUseCase>();
      final projectUseCase2 = container.get<GenerateProjectUseCase>();
      expect(projectUseCase1, same(projectUseCase2));
    });

    test('should register generation mode strategies as singletons', () {
      factory.registerGenerationServices(
        container: container,
        logger: logger,
        config: config,
      );

      expect(
        container.isRegistered<FeatureGenerationExecutor>(),
        isTrue,
      );
      expect(
        container.isRegistered<ServiceGenerationExecutor>(),
        isTrue,
      );
      expect(
        container.isRegistered<ProjectGenerationExecutor>(),
        isTrue,
      );

      final featureStrategy1 = container.get<FeatureGenerationExecutor>();
      final featureStrategy2 = container.get<FeatureGenerationExecutor>();
      expect(featureStrategy1, same(featureStrategy2));

      final serviceStrategy1 = container.get<ServiceGenerationExecutor>();
      final serviceStrategy2 = container.get<ServiceGenerationExecutor>();
      expect(serviceStrategy1, same(serviceStrategy2));

      final projectStrategy1 = container.get<ProjectGenerationExecutor>();
      final projectStrategy2 = container.get<ProjectGenerationExecutor>();
      expect(projectStrategy1, same(projectStrategy2));
    });

    test('should register generation mode registry as singleton', () {
      factory.registerGenerationServices(
        container: container,
        logger: logger,
        config: config,
      );

      expect(container.isRegistered<GenerationExecutorRegistry>(), isTrue);
      final registry1 = container.get<GenerationExecutorRegistry>();
      final registry2 = container.get<GenerationExecutorRegistry>();
      expect(registry1, same(registry2));
    });

    test('should register all expected generation modes in registry', () {
      factory.registerGenerationServices(
        container: container,
        logger: logger,
        config: config,
      );

      final registry = container.get<GenerationExecutorRegistry>();
      expect(registry.isRegistered(GenerationMode.feature), isTrue);
      expect(registry.isRegistered(GenerationMode.service), isTrue);
      expect(registry.isRegistered(GenerationMode.project), isTrue);
    });

    test('should use mode profiles as single source of truth', () {
      factory.registerGenerationServices(
        container: container,
        logger: logger,
        config: config,
      );

      final registry = container.get<GenerationExecutorRegistry>();
      final processorFactory = container.get<IVariableProcessorFactory>();

      // Verify that registry has profiles (constructed from profiles)
      expect(registry.getProfile(GenerationMode.feature), isNotNull);
      expect(registry.getProfile(GenerationMode.service), isNotNull);
      expect(registry.getProfile(GenerationMode.project), isNotNull);

      // Verify brick IDs are accessible from registry
      expect(
        registry.getBrickId(GenerationMode.feature),
        equals(BrickId.feature),
      );
      expect(
        registry.getBrickId(GenerationMode.service),
        equals(BrickId.service),
      );
      expect(
        registry.getBrickId(GenerationMode.project),
        equals(BrickId.project),
      );

      // Verify that processor factory and registry share the same processors
      final featureProcessorFromFactory = processorFactory.getProcessor(
        GenerationMode.feature,
      );
      final featureProcessorFromRegistry = registry
          .getProfile(GenerationMode.feature)!
          .variableProcessor;
      expect(featureProcessorFromFactory, same(featureProcessorFromRegistry));

      final serviceProcessorFromFactory = processorFactory.getProcessor(
        GenerationMode.service,
      );
      final serviceProcessorFromRegistry = registry
          .getProfile(GenerationMode.service)!
          .variableProcessor;
      expect(serviceProcessorFromFactory, same(serviceProcessorFromRegistry));

      final projectProcessorFromFactory = processorFactory.getProcessor(
        GenerationMode.project,
      );
      final projectProcessorFromRegistry = registry
          .getProfile(GenerationMode.project)!
          .variableProcessor;
      expect(projectProcessorFromFactory, same(projectProcessorFromRegistry));
    });

    test('should register executor registry as singleton', () {
      factory.registerGenerationServices(
        container: container,
        logger: logger,
        config: config,
      );

      expect(container.isRegistered<GenerationExecutorRegistry>(), isTrue);
      final registry1 = container.get<GenerationExecutorRegistry>();
      final registry2 = container.get<GenerationExecutorRegistry>();
      expect(registry1, same(registry2));
    });

    test('should register MCP adapter as singleton', () {
      factory.registerGenerationServices(
        container: container,
        logger: logger,
        config: config,
      );

      expect(container.isRegistered<GenerationMcpAdapter>(), isTrue);
      final adapter1 = container.get<GenerationMcpAdapter>();
      final adapter2 = container.get<GenerationMcpAdapter>();
      expect(adapter1, same(adapter2));
    });

    test('should preserve singleton vs factory registration semantics', () {
      factory.registerGenerationServices(
        container: container,
        logger: logger,
        config: config,
      );

      // Singletons should return the same instance
      final cache1 = container.get<ICacheManager<TemplateInfo>>();
      final cache2 = container.get<ICacheManager<TemplateInfo>>();
      expect(cache1, same(cache2));

      final processor1 = container.get<ProjectVariableProcessor>();
      final processor2 = container.get<ProjectVariableProcessor>();
      expect(processor1, same(processor2));

      // Factories cache after first get, but the pattern is preserved
      final registry1 = container.get<BrickRegistry>();
      final registry2 = container.get<BrickRegistry>();
      expect(registry1, equals(registry2));
    });
  });

  group('IGenerationServicesFactory interface', () {
    test('should allow custom factory implementation', () {
      final customFactory = _CustomGenerationServicesFactory();
      final container = ServiceContainer();
      final logger = StructuredMasonLogger(Logger(), MockLogger());
      final config = ServiceBootstrapperConfig.test();

      // Should not throw
      expect(
        () => customFactory.registerGenerationServices(
          container: container,
          logger: logger,
          config: config,
        ),
        returnsNormally,
      );
    });
  });
}

/// Mock logger for testing
class MockLogger implements flylog.Logger {
  @override
  String get name => 'MockLogger';

  @override
  flylog.Logger child(flylog.JsonMap contextFields) => this;

  @override
  flylog.Logger withFields(flylog.JsonMap fields) => this;

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    flylog.JsonMap? fields,
  }) {}

  @override
  void trace(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    flylog.JsonMap? fields,
  }) {}

  @override
  void debug(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    flylog.JsonMap? fields,
  }) {}

  @override
  void info(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    flylog.JsonMap? fields,
  }) {}

  @override
  void warn(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    flylog.JsonMap? fields,
  }) {}

  @override
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    flylog.JsonMap? fields,
  }) {}

  @override
  void fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    flylog.JsonMap? fields,
  }) {}
}

/// Custom factory implementation for testing interface
class _CustomGenerationServicesFactory implements IGenerationServicesFactory {
  @override
  void registerGenerationServices({
    required IServiceContainer container,
    required StructuredMasonLogger logger,
    required ServiceBootstrapperConfig config,
  }) {
    // Minimal implementation for testing
  }
}
