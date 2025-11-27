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
    _registerGenerationEngine(serviceContainer, logger);
    // Register use cases as factories so they can be created on-demand
    // when _createModeProfiles needs them
    _registerUseCases(serviceContainer);
    // Now register strategies and registry
    // This will create mode profiles, which need use cases. The use cases will be
    // created directly in _createModeProfiles with a workflow orchestrator that
    // uses a temporary registry, then the real registry will be created and registered.
    // The workflow orchestrator will also be registered as a singleton here.
    _registerStrategiesAndRegistry(serviceContainer, logger);
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

  /// Register generation engine.
  ///
  /// Registers:
  /// - Generation engine (Mason-based)
  void _registerGenerationEngine(
    ServiceContainer container,
    StructuredMasonLogger logger,
  ) {
    container.registerSingleton<IGenerationEngine>(
      MasonGenerationEngine(
        masonAdapter: container.get<IMasonAdapter>(),
        logger: logger,
      ),
    );
  }

  /// Register use cases.
  ///
  /// Registers:
  /// - Use cases (feature, service, project) as factories for lazy initialization
  ///
  /// Note: Use cases are registered as factories so they can be created on-demand
  /// when _createModeProfiles needs them. The workflow orchestrator will be
  /// created when first used, after the registry is available.
  void _registerUseCases(ServiceContainer container) {
    // Register use cases as factories (all delegate to the workflow orchestrator)
    // They'll be created on-demand when _createModeProfiles needs them
    container
      ..registerFactory<GenerateFeatureUseCase>(() {
        return GenerateFeatureUseCase(
          workflowOrchestrator: container.get<IWorkflowOrchestrator>(),
        );
      })
      ..registerFactory<GenerateServiceUseCase>(() {
        return GenerateServiceUseCase(
          workflowOrchestrator: container.get<IWorkflowOrchestrator>(),
        );
      })
      ..registerFactory<GenerateProjectUseCase>(() {
        return GenerateProjectUseCase(
          workflowOrchestrator: container.get<IWorkflowOrchestrator>(),
        );
      });
  }

  /// Register generation mode strategies, registry, and handlers.
  ///
  /// Registers:
  /// - Feature, service, and project generation mode strategies
  /// - Generation mode registry mapping modes to strategies
  /// - Variable processor factory (using mode profiles as single source of truth)
  /// - Command handler and MCP adapter
  void _registerStrategiesAndRegistry(
    ServiceContainer container,
    StructuredMasonLogger logger,
  ) {
    // Create mode profiles - this is the single source of truth for all mode wiring
    final profiles = _createModeProfiles(container, logger);

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
    // Note: This is a temporary registry that will be replaced with the updated one
    final registry = GenerationModeRegistry(profiles);
    container
      ..registerSingleton<GenerationModeRegistry>(registry)
      // Register variable processor factory using the same profiles
      // This ensures the processor factory and registry share the same configuration
      // Note: This will be updated after we create the real use cases
      ..registerSingleton<IVariableProcessorFactory>(
        VariableProcessorFactory.fromProfiles(profiles),
      );

    // Now we'll create the real use cases, strategies, and registry with the correct dependencies.
    // We need to create them in the right order to break the circular dependency:
    // 1. Create a temporary registry (already done above)
    // 2. Create workflow orchestrator with temp registry
    // 3. Create use cases with the workflow orchestrator
    // 4. Create strategies with the use cases
    // 5. Create updated profiles with the strategies
    // 6. Create updated registry with the profiles
    // 7. Recreate everything with the updated registry
    
    // Step 2-3: Create workflow orchestrator and use cases with temp registry
    final tempWorkflowOrchestrator = WorkflowOrchestratorImpl(
      templateManager: container.get<TemplateManager>(),
      variableProcessorFactory: container.get<IVariableProcessorFactory>(),
      logger: logger,
      modeRegistry: registry,
    );
    final tempFeatureUseCase = GenerateFeatureUseCase(
      workflowOrchestrator: tempWorkflowOrchestrator,
    );
    final tempServiceUseCase = GenerateServiceUseCase(
      workflowOrchestrator: tempWorkflowOrchestrator,
    );
    final tempProjectUseCase = GenerateProjectUseCase(
      workflowOrchestrator: tempWorkflowOrchestrator,
    );
    
    // Step 4: Create temp strategies with the temp use cases (needed for profiles)
    final tempFeatureStrategy = FeatureGenerationModeStrategy(
      useCase: tempFeatureUseCase,
    );
    final tempServiceStrategy = ServiceGenerationModeStrategy(
      useCase: tempServiceUseCase,
    );
    final tempProjectStrategy = ProjectGenerationModeStrategy(
      useCase: tempProjectUseCase,
    );
    
    // Step 5: Create updated profiles with the temp strategies
    final updatedProfiles = <GenerationMode, GenerationModeProfile>{
      GenerationMode.feature: GenerationModeProfile(
        mode: GenerationMode.feature,
        brickId: profiles[GenerationMode.feature]!.brickId,
        variableProcessor: profiles[GenerationMode.feature]!.variableProcessor,
        strategy: tempFeatureStrategy,
      ),
      GenerationMode.service: GenerationModeProfile(
        mode: GenerationMode.service,
        brickId: profiles[GenerationMode.service]!.brickId,
        variableProcessor: profiles[GenerationMode.service]!.variableProcessor,
        strategy: tempServiceStrategy,
      ),
      GenerationMode.project: GenerationModeProfile(
        mode: GenerationMode.project,
        brickId: profiles[GenerationMode.project]!.brickId,
        variableProcessor: profiles[GenerationMode.project]!.variableProcessor,
        strategy: tempProjectStrategy,
      ),
    };
    
    // Step 6: Create updated variable processor factory (will be updated with final profiles later)
    final tempVariableProcessorFactory =
        VariableProcessorFactory.fromProfiles(updatedProfiles);
    
    // Step 7: Create a temporary registry to break the circular dependency
    // We need this to create the workflow orchestrator, which is needed for use cases
    final tempRegistry = GenerationModeRegistry(updatedProfiles);
    final tempWorkflowOrchestrator2 = WorkflowOrchestratorImpl(
      templateManager: container.get<TemplateManager>(),
      variableProcessorFactory: tempVariableProcessorFactory,
      logger: logger,
      modeRegistry: tempRegistry,
    );
    
    // Step 8: Create temporary use cases with temp orchestrator (needed for strategies)
    final tempFeatureUseCase2 = GenerateFeatureUseCase(
      workflowOrchestrator: tempWorkflowOrchestrator2,
    );
    final tempServiceUseCase2 = GenerateServiceUseCase(
      workflowOrchestrator: tempWorkflowOrchestrator2,
    );
    final tempProjectUseCase2 = GenerateProjectUseCase(
      workflowOrchestrator: tempWorkflowOrchestrator2,
    );
    
    // Step 9: Create temporary strategies with temp use cases (needed for final profiles)
    final tempFeatureStrategy2 = FeatureGenerationModeStrategy(
      useCase: tempFeatureUseCase2,
    );
    final tempServiceStrategy2 = ServiceGenerationModeStrategy(
      useCase: tempServiceUseCase2,
    );
    final tempProjectStrategy2 = ProjectGenerationModeStrategy(
      useCase: tempProjectUseCase2,
    );
    
    // Step 10: Create final profiles with temp strategies (we'll update them)
    final finalProfiles = <GenerationMode, GenerationModeProfile>{
      GenerationMode.feature: GenerationModeProfile(
        mode: GenerationMode.feature,
        brickId: updatedProfiles[GenerationMode.feature]!.brickId,
        variableProcessor: updatedProfiles[GenerationMode.feature]!.variableProcessor,
        strategy: tempFeatureStrategy2,
      ),
      GenerationMode.service: GenerationModeProfile(
        mode: GenerationMode.service,
        brickId: updatedProfiles[GenerationMode.service]!.brickId,
        variableProcessor: updatedProfiles[GenerationMode.service]!.variableProcessor,
        strategy: tempServiceStrategy2,
      ),
      GenerationMode.project: GenerationModeProfile(
        mode: GenerationMode.project,
        brickId: updatedProfiles[GenerationMode.project]!.brickId,
        variableProcessor: updatedProfiles[GenerationMode.project]!.variableProcessor,
        strategy: tempProjectStrategy2,
      ),
    };
    
    // Step 11: Create final registry and variable processor factory
    final finalRegistry = GenerationModeRegistry(finalProfiles);
    final finalVariableProcessorFactory =
        VariableProcessorFactory.fromProfiles(finalProfiles);
    
    // Step 12: Create final workflow orchestrator with final registry
    // Note: We'll update this to use finalRegistry2 after we update the profiles
    final finalWorkflowOrchestrator = WorkflowOrchestratorImpl(
      templateManager: container.get<TemplateManager>(),
      variableProcessorFactory: finalVariableProcessorFactory,
      logger: logger,
      modeRegistry: finalRegistry,
    );
    
    // Step 13: Create final use cases with final workflow orchestrator
    final finalFeatureUseCase = GenerateFeatureUseCase(
      workflowOrchestrator: finalWorkflowOrchestrator,
    );
    final finalServiceUseCase = GenerateServiceUseCase(
      workflowOrchestrator: finalWorkflowOrchestrator,
    );
    final finalProjectUseCase = GenerateProjectUseCase(
      workflowOrchestrator: finalWorkflowOrchestrator,
    );
    
    // Step 14: Create final strategies with final use cases
    final finalFeatureStrategy = FeatureGenerationModeStrategy(
      useCase: finalFeatureUseCase,
    );
    final finalServiceStrategy = ServiceGenerationModeStrategy(
      useCase: finalServiceUseCase,
    );
    final finalProjectStrategy = ProjectGenerationModeStrategy(
      useCase: finalProjectUseCase,
    );
    
    // Step 15: Update final profiles with final strategies
    finalProfiles[GenerationMode.feature] = GenerationModeProfile(
      mode: GenerationMode.feature,
      brickId: finalProfiles[GenerationMode.feature]!.brickId,
      variableProcessor: finalProfiles[GenerationMode.feature]!.variableProcessor,
      strategy: finalFeatureStrategy,
    );
    finalProfiles[GenerationMode.service] = GenerationModeProfile(
      mode: GenerationMode.service,
      brickId: finalProfiles[GenerationMode.service]!.brickId,
      variableProcessor: finalProfiles[GenerationMode.service]!.variableProcessor,
      strategy: finalServiceStrategy,
    );
    finalProfiles[GenerationMode.project] = GenerationModeProfile(
      mode: GenerationMode.project,
      brickId: finalProfiles[GenerationMode.project]!.brickId,
      variableProcessor: finalProfiles[GenerationMode.project]!.variableProcessor,
      strategy: finalProjectStrategy,
    );
    
    // Step 16: Recreate final registry with updated profiles
    final finalRegistry2 = GenerationModeRegistry(finalProfiles);
    
    // Step 17: Recreate final workflow orchestrator with final registry
    final finalWorkflowOrchestrator2 = WorkflowOrchestratorImpl(
      templateManager: container.get<TemplateManager>(),
      variableProcessorFactory: finalVariableProcessorFactory,
      logger: logger,
      modeRegistry: finalRegistry2,
    );
    
    // Step 18: Recreate final use cases with final workflow orchestrator
    final finalFeatureUseCase2 = GenerateFeatureUseCase(
      workflowOrchestrator: finalWorkflowOrchestrator2,
    );
    final finalServiceUseCase2 = GenerateServiceUseCase(
      workflowOrchestrator: finalWorkflowOrchestrator2,
    );
    final finalProjectUseCase2 = GenerateProjectUseCase(
      workflowOrchestrator: finalWorkflowOrchestrator2,
    );
    
    // Step 19: Recreate final strategies with final use cases
    final finalFeatureStrategy2 = FeatureGenerationModeStrategy(
      useCase: finalFeatureUseCase2,
    );
    final finalServiceStrategy2 = ServiceGenerationModeStrategy(
      useCase: finalServiceUseCase2,
    );
    final finalProjectStrategy2 = ProjectGenerationModeStrategy(
      useCase: finalProjectUseCase2,
    );
    
    // Register everything as singletons
    container
      ..registerSingleton<GenerationModeRegistry>(finalRegistry2)
      ..registerSingleton<IVariableProcessorFactory>(finalVariableProcessorFactory)
      ..registerSingleton<IWorkflowOrchestrator>(finalWorkflowOrchestrator2)
      ..registerSingleton<GenerateFeatureUseCase>(finalFeatureUseCase2)
      ..registerSingleton<GenerateServiceUseCase>(finalServiceUseCase2)
      ..registerSingleton<GenerateProjectUseCase>(finalProjectUseCase2)
      ..registerSingleton<FeatureGenerationModeStrategy>(finalFeatureStrategy2)
      ..registerSingleton<ServiceGenerationModeStrategy>(finalServiceStrategy2)
      ..registerSingleton<ProjectGenerationModeStrategy>(finalProjectStrategy2)
    
    // Register command handler and MCP adapter with final registry

      ..registerSingleton<GenerationCommandHandler>(
        GenerationCommandHandler(
          registry: finalRegistry2,
        ),
      )
      // Register MCP adapter
      // MCP adapter uses the registry to ensure consistency with CLI behavior
      ..registerSingleton<GenerationMcpAdapter>(
        GenerationMcpAdapter(
          registry: finalRegistry,
        ),
      );
  }

  /// Create all generation mode profiles.
  ///
  /// This method centralizes all mode-specific wiring and serves as the single
  /// source of truth for generation mode configuration. To add a new mode:
  /// 1. Create a new `GenerationModeStrategy<T>` implementation
  /// 2. Create the corresponding use case (if needed) and register it in `_registerUseCases`
  /// 3. Create a new `IVariableProcessor` if variables/derivation differ from existing modes
  /// 4. Add a new `GenerationModeProfile` entry to this map
  ///
  /// Returns a map of generation modes to their corresponding profiles.
  ///
  /// Note: Use cases are created directly here (not from container) because they
  /// need a workflow orchestrator, which needs a registry, which is created from
  /// these profiles. We create a temporary workflow orchestrator with a temporary
  /// registry to break the circular dependency.
  Map<GenerationMode, GenerationModeProfile> _createModeProfiles(
    ServiceContainer container,
    StructuredMasonLogger logger,
  ) {
    // Resolve processors (already registered in _registerVariableProcessing)
    final projectProcessor = container.get<ProjectVariableProcessor>();
    final featureProcessor = container.get<FeatureVariableProcessor>();
    final serviceProcessor = container.get<ServiceVariableProcessor>();

    // Create use cases directly (not from container) to avoid circular dependency.
    // We need a workflow orchestrator, which needs a registry. We'll create a
    // temporary registry first, then create the real one after profiles are built.
    // For now, create use cases with a workflow orchestrator that uses a temporary
    // empty registry. The real registry will be created and registered after this.
    final tempProfiles = <GenerationMode, GenerationModeProfile>{};
    final tempRegistry = GenerationModeRegistry(tempProfiles);
    final tempVariableProcessorFactory =
        VariableProcessorFactory.fromProfiles(tempProfiles);
    final tempWorkflowOrchestrator = WorkflowOrchestratorImpl(
      templateManager: container.get<TemplateManager>(),
      variableProcessorFactory: tempVariableProcessorFactory,
      logger: logger,
      modeRegistry: tempRegistry,
    );

    // Create use cases with the temporary workflow orchestrator
    final featureUseCase = GenerateFeatureUseCase(
      workflowOrchestrator: tempWorkflowOrchestrator,
    );
    final serviceUseCase = GenerateServiceUseCase(
      workflowOrchestrator: tempWorkflowOrchestrator,
    );
    final projectUseCase = GenerateProjectUseCase(
      workflowOrchestrator: tempWorkflowOrchestrator,
    );

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
