import 'package:fly_cli/src/cli/application/bootstrapping/service_bootstrapper_config.dart';
import 'package:fly_cli/src/cli/domain/interfaces/i_service_container.dart';
import 'package:fly_cli/src/features/generate/common/generation_command_handler.dart';
import 'package:fly_cli/src/generation/application/modes/generation_mode_profile.dart';
import 'package:fly_cli/src/generation/application/ports/icache_manager.dart';
import 'package:fly_cli/src/generation/application/ports/igeneration_engine.dart';
import 'package:fly_cli/src/generation/application/ports/ivariable_processor_factory.dart';
import 'package:fly_cli/src/generation/application/ports/iworkflow_orchestrator.dart';
import 'package:fly_cli/src/generation/application/services/processors/feature_variable_processor.dart';
import 'package:fly_cli/src/generation/application/services/processors/project_variable_processor.dart';
import 'package:fly_cli/src/generation/application/services/processors/service_variable_processor.dart';
import 'package:fly_cli/src/generation/application/strategies/feature_generation_mode_strategy.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_mode_registry.dart';
import 'package:fly_cli/src/generation/application/strategies/project_generation_mode_strategy.dart';
import 'package:fly_cli/src/generation/application/strategies/service_generation_mode_strategy.dart';
import 'package:fly_cli/src/generation/application/use_cases/generate_feature_use_case.dart';
import 'package:fly_cli/src/generation/application/use_cases/generate_project_use_case.dart';
import 'package:fly_cli/src/generation/application/use_cases/generate_service_use_case.dart';
import 'package:fly_cli/src/generation/brick/brick_registry.dart';
import 'package:fly_cli/src/generation/domain/repositories/ibrick_repository.dart';
import 'package:fly_cli/src/generation/domain/repositories/itemplate_repository.dart';
import 'package:fly_cli/src/generation/domain/repositories/itemplate_validator.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/generation/infrastructure/adapters/file_system_adapter.dart';
import 'package:fly_cli/src/generation/infrastructure/adapters/ifile_system_adapter.dart';
import 'package:fly_cli/src/generation/infrastructure/adapters/imason_adapter.dart';
import 'package:fly_cli/src/generation/infrastructure/adapters/mason_adapter.dart';
import 'package:fly_cli/src/generation/infrastructure/brick/brick_repository_impl.dart';
import 'package:fly_cli/src/generation/infrastructure/generation/mason_generation_engine.dart';
import 'package:fly_cli/src/generation/infrastructure/template/template_cache_impl.dart';
import 'package:fly_cli/src/generation/infrastructure/template/template_repository_impl.dart';
import 'package:fly_cli/src/generation/infrastructure/template/template_validator_impl.dart';
import 'package:fly_cli/src/generation/infrastructure/variable_processing/variable_processor_factory.dart';
import 'package:fly_cli/src/generation/infrastructure/workflow/workflow_orchestrator_impl.dart';
import 'package:fly_cli/src/generation/template/template_info.dart';
import 'package:fly_cli/src/generation/template/template_manager.dart';
import 'package:fly_cli/src/generation/utils/planning_logger_adapter.dart';
import 'package:fly_cli/src/generation/versioning/compatibility_checker.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/adapters/generation_mcp_adapter.dart';
import 'package:fly_cli/src/shared/di/service_container.dart';
import 'package:fly_cli/src/shared/logging/infrastructure/structured_mason_logger.dart';
import 'package:fly_cli/src/shared/utils/version_utils.dart';
import 'package:pub_semver/pub_semver.dart';

/// Factory interface for creating and registering generation-related services.
///
/// This factory encapsulates all dependency creation and registration logic
/// for generation components, including infrastructure, workflow orchestrators,
/// use cases, strategies, and handlers. This centralizes the composition root
/// for generation services and makes it easier to extend with new generation modes.
abstract class IGenerationServicesFactory {
  /// Register all generation-related services into the provided container.
  ///
  /// This method registers:
  /// - Infrastructure adapters (file system, mason)
  /// - Repositories (brick, template)
  /// - Variable processors and factory
  /// - Generation engine and workflow orchestrator
  /// - Use cases (feature, service, project)
  /// - Generation mode strategies and registry
  /// - Command handler and MCP adapter
  ///
  /// [container] - The service container to register services into
  /// [logger] - The structured logger for generation components
  /// [config] - The bootstrapper configuration (currently unused but reserved for future use)
  void registerGenerationServices({
    required IServiceContainer container,
    required StructuredMasonLogger logger,
    required ServiceBootstrapperConfig config,
  });
}

/// Concrete implementation of [IGenerationServicesFactory].
///
/// This factory handles the creation and registration of all generation-related
/// dependencies following Clean Architecture principles. It preserves existing
/// singleton vs factory registration patterns and lazy initialization behavior.
///
/// To add a new generation mode:
/// 1. Create a new `GenerationModeStrategy<T>` implementation
/// 2. Create the corresponding use case (if needed)
/// 3. Update `_createStrategies` to include the new strategy
/// 4. Register the new use case in `_registerUseCases`
class GenerationServicesFactory implements IGenerationServicesFactory {
  /// Creates a new [GenerationServicesFactory] instance.
  GenerationServicesFactory();

  @override
  void registerGenerationServices({
    required IServiceContainer container,
    required StructuredMasonLogger logger,
    required ServiceBootstrapperConfig config,
  }) {
    final serviceContainer = container as ServiceContainer;

    // Register components in dependency order
    _registerInfrastructure(serviceContainer, logger);
    _registerVariableProcessing(serviceContainer, logger);
    // Note: Workflow orchestrator and use cases are registered after registry
    // to allow the orchestrator to access the mode registry
    _registerStrategiesAndRegistry(serviceContainer);
    _registerWorkflowAndUseCases(serviceContainer, logger);
  }

  /// Register infrastructure adapters and repositories.
  ///
  /// Registers:
  /// - File system and Mason adapters
  /// - Brick registry and repository
  /// - Template cache, validator, and repository
  /// - Compatibility checker
  void _registerInfrastructure(
    ServiceContainer container,
    StructuredMasonLogger logger,
  ) {
    container
      ..registerSingleton<IFileSystemAdapter>(const FileSystemAdapter())
      ..registerSingleton<IMasonAdapter>(const MasonAdapter())
      // Register repositories
      // Create BrickRegistry with logger
      ..registerFactory<BrickRegistry>(
        () => BrickRegistry(
          logger: logger,
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
          logger: logger,
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
      });
  }

  /// Register variable processors and factory.
  ///
  /// Registers:
  /// - Project, feature, and service variable processors
  /// - Variable processor factory that maps modes to processors
  ///
  /// Note: The variable processor factory is now created from mode profiles
  /// in `_registerStrategiesAndRegistry` to ensure a single source of truth.
  void _registerVariableProcessing(
    ServiceContainer container,
    StructuredMasonLogger logger,
  ) {
    // Wrap StructuredMasonLogger with ComposerLoggerAdapter for compatibility
    final composerLogger = ComposerLoggerAdapter(logger);
    container
      ..registerSingleton<ProjectVariableProcessor>(
        ProjectVariableProcessor(logger: composerLogger),
      )
      ..registerSingleton<FeatureVariableProcessor>(
        FeatureVariableProcessor(logger: composerLogger),
      )
      ..registerSingleton<ServiceVariableProcessor>(
        ServiceVariableProcessor(logger: composerLogger),
      );
    // Note: VariableProcessorFactory is now registered in _registerStrategiesAndRegistry
    // after mode profiles are created, to use the single source of truth.
  }

  /// Register workflow orchestrator and use cases.
  ///
  /// Registers:
  /// - Generation engine (Mason-based)
  /// - Workflow orchestrator (factory for lazy initialization)
  /// - Use cases (feature, service, project)
  ///
  /// Note: The workflow orchestrator is registered as a factory to allow
  /// lazy initialization after the mode registry is created. The registry
  /// is injected to enable brick ID resolution from mode profiles.
  void _registerWorkflowAndUseCases(
    ServiceContainer container,
    StructuredMasonLogger logger,
  ) {
    container
      // Register services
      ..registerSingleton<IGenerationEngine>(
        MasonGenerationEngine(
          masonAdapter: container.get<IMasonAdapter>(),
          logger: logger,
        ),
      )
      // Register workflow orchestrator as factory (lazy initialization)
      // The registry is now available since _registerStrategiesAndRegistry runs first
      ..registerFactory<IWorkflowOrchestrator>(() {
        return WorkflowOrchestratorImpl(
          templateManager: container.get<TemplateManager>(),
          variableProcessorFactory: container.get<IVariableProcessorFactory>(),
          logger: logger,
          modeRegistry: container.get<GenerationModeRegistry>(),
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
      );
  }

  /// Register generation mode strategies, registry, and handlers.
  ///
  /// Registers:
  /// - Feature, service, and project generation mode strategies
  /// - Generation mode registry mapping modes to strategies
  /// - Variable processor factory (using mode profiles as single source of truth)
  /// - Command handler and MCP adapter
  void _registerStrategiesAndRegistry(ServiceContainer container) {
    // Create mode profiles - this is the single source of truth for all mode wiring
    final profiles = _createModeProfiles(container);

    // Register individual strategies as singletons
    for (final entry in profiles.entries) {
      final mode = entry.key;
      final profile = entry.value;
      switch (mode) {
        case GenerationMode.feature:
          container.registerSingleton<FeatureGenerationModeStrategy>(
            profile.strategy as FeatureGenerationModeStrategy,
          );
        case GenerationMode.service:
          container.registerSingleton<ServiceGenerationModeStrategy>(
            profile.strategy as ServiceGenerationModeStrategy,
          );
        case GenerationMode.project:
          container.registerSingleton<ProjectGenerationModeStrategy>(
            profile.strategy as ProjectGenerationModeStrategy,
          );
      }
    }

    // Register generation mode registry from profiles
    // This registry is the authoritative mapping between GenerationMode enum values
    // and their corresponding strategy implementations. All generation execution
    // should route through this registry to ensure consistency and extensibility.
    // Profiles are mandatory to ensure a single source of truth.
    final registry = GenerationModeRegistry(profiles);
    container
      ..registerSingleton<GenerationModeRegistry>(registry)
      // Register variable processor factory using the same profiles
      // This ensures the processor factory and registry share the same configuration
      ..registerSingleton<IVariableProcessorFactory>(
        VariableProcessorFactory.fromProfiles(profiles),
      )
      // Register command handler
      ..registerSingleton<GenerationCommandHandler>(
        GenerationCommandHandler(
          registry: registry,
        ),
      )
      // Register MCP adapter
      // MCP adapter uses the registry to ensure consistency with CLI behavior
      ..registerSingleton<GenerationMcpAdapter>(
        GenerationMcpAdapter(
          registry: registry,
        ),
      );
  }

  /// Create all generation mode profiles.
  ///
  /// This method centralizes all mode-specific wiring and serves as the single
  /// source of truth for generation mode configuration. To add a new mode:
  /// 1. Create a new `GenerationModeStrategy<T>` implementation
  /// 2. Create the corresponding use case (if needed) and register it in `_registerWorkflowAndUseCases`
  /// 3. Create a new `IVariableProcessor` if variables/derivation differ from existing modes
  /// 4. Add a new `GenerationModeProfile` entry to this map
  ///
  /// Returns a map of generation modes to their corresponding profiles.
  Map<GenerationMode, GenerationModeProfile> _createModeProfiles(
    ServiceContainer container,
  ) {
    // Resolve processors (already registered in _registerVariableProcessing)
    final projectProcessor = container.get<ProjectVariableProcessor>();
    final featureProcessor = container.get<FeatureVariableProcessor>();
    final serviceProcessor = container.get<ServiceVariableProcessor>();

    // Resolve use cases (already registered in _registerWorkflowAndUseCases)
    final featureUseCase = container.get<GenerateFeatureUseCase>();
    final serviceUseCase = container.get<GenerateServiceUseCase>();
    final projectUseCase = container.get<GenerateProjectUseCase>();

    // Create strategies
    final featureStrategy = FeatureGenerationModeStrategy(
      useCase: featureUseCase,
    );
    final serviceStrategy = ServiceGenerationModeStrategy(
      useCase: serviceUseCase,
    );
    final projectStrategy = ProjectGenerationModeStrategy(
      useCase: projectUseCase,
    );

    // Build profiles - this is the single source of truth
    return {
      GenerationMode.feature: GenerationModeProfile(
        mode: GenerationMode.feature,
        brickId: BrickId.feature,
        variableProcessor: featureProcessor,
        strategy: featureStrategy,
      ),
      GenerationMode.service: GenerationModeProfile(
        mode: GenerationMode.service,
        brickId: BrickId.service,
        variableProcessor: serviceProcessor,
        strategy: serviceStrategy,
      ),
      GenerationMode.project: GenerationModeProfile(
        mode: GenerationMode.project,
        brickId: BrickId.project,
        variableProcessor: projectProcessor,
        strategy: projectStrategy,
      ),
    };
  }
}
