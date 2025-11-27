import 'package:fly_cli/src/cli/application/bootstrapping/service_bootstrapper_config.dart';
import 'package:fly_cli/src/cli/domain/interfaces/i_service_container.dart';
import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/features/generate/common/generation_command_handler.dart';
import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/modes/generation_mode_profile.dart';
import 'package:fly_cli/src/generation/application/ports/icache_manager.dart';
import 'package:fly_cli/src/generation/application/ports/igeneration_engine.dart';
import 'package:fly_cli/src/generation/application/ports/ivariable_processor.dart';
import 'package:fly_cli/src/generation/application/ports/ivariable_processor_factory.dart';
import 'package:fly_cli/src/generation/application/ports/iworkflow_orchestrator.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_mode_strategy.dart';
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
abstract class IGenerationServicesFactory {
  void registerGenerationServices({
    required IServiceContainer container,
    required StructuredMasonLogger logger,
    required ServiceBootstrapperConfig config,
  });
}

/// Factory for creating and registering generation-related services.
///
/// Creates all components in dependency order without using stub dependencies.
/// Components are built bottom-up: infrastructure -> processors -> orchestrator -> use cases -> strategies -> registry.
class GenerationServicesFactory implements IGenerationServicesFactory {
  GenerationServicesFactory();

  @override
  void registerGenerationServices({
    required IServiceContainer container,
    required StructuredMasonLogger logger,
    required ServiceBootstrapperConfig config,
  }) {
    final serviceContainer = container as ServiceContainer;

    _registerInfrastructure(serviceContainer, logger);
    _registerVariableProcessing(serviceContainer, logger);
    _registerGenerationEngine(serviceContainer, logger);
    _registerStrategiesAndRegistry(serviceContainer, logger);
  }

  void _registerInfrastructure(
    ServiceContainer container,
    StructuredMasonLogger logger,
  ) {
    container
      ..registerSingleton<IFileSystemAdapter>(const FileSystemAdapter())
      ..registerSingleton<IMasonAdapter>(const MasonAdapter())
      ..registerFactory<BrickRegistry>(
        () => BrickRegistry(logger: logger),
      )
      ..registerFactory<IBrickRepository>(() {
        return BrickRepositoryImpl(
          brickRegistry: container.get<BrickRegistry>(),
        );
      })
      ..registerSingleton<ICacheManager<TemplateInfo>>(
        TemplateCacheImpl(),
      )
      ..registerFactory<CompatibilityChecker>(() {
        final cliVersion = Version.parse(VersionUtils.getCurrentVersion());
        return CompatibilityChecker(
          currentCliVersion: cliVersion,
          currentFlutterVersion: Version.parse('3.10.0'),
          currentDartVersion: Version.parse('3.0.0'),
        );
      })
      ..registerFactory<ITemplateValidator>(() {
        return TemplateValidatorImpl(
          compatibilityChecker: container.get<CompatibilityChecker>(),
          logger: logger,
        );
      })
      ..registerFactory<ITemplateRepository>(() {
        return TemplateRepositoryImpl(
          templateManager: container.get<TemplateManager>(),
          templateCache: container.get<ICacheManager<TemplateInfo>>(),
          templateValidator: container.get<ITemplateValidator>(),
        );
      });
  }

  void _registerVariableProcessing(
    ServiceContainer container,
    StructuredMasonLogger logger,
  ) {
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
  }

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

  void _registerStrategiesAndRegistry(
    ServiceContainer container,
    StructuredMasonLogger logger,
  ) {
    final templateManager = container.get<TemplateManager>();
    final projectProcessor = container.get<ProjectVariableProcessor>();
    final featureProcessor = container.get<FeatureVariableProcessor>();
    final serviceProcessor = container.get<ServiceVariableProcessor>();

    // Create mode configuration
    final modeConfig = {
      GenerationMode.feature: (BrickId.feature, featureProcessor),
      GenerationMode.service: (BrickId.service, serviceProcessor),
      GenerationMode.project: (BrickId.project, projectProcessor),
    };

    // Create processors map for variable processor factory
    final processorsMap = <GenerationMode, IVariableProcessor>{
      for (final entry in modeConfig.entries)
        entry.key: entry.value.$2,
    };

    // Create profiles for variable processor factory (strategies will be added later)
    final profilesForFactory = <GenerationMode, GenerationModeProfile>{};
    for (final entry in modeConfig.entries) {
      // Create a minimal profile with a no-op strategy just for the factory
      // The factory only uses variableProcessor, not strategy
      profilesForFactory[entry.key] = GenerationModeProfile(
        mode: entry.key,
        brickId: entry.value.$1,
        variableProcessor: entry.value.$2,
        strategy: _NoOpStrategy(entry.key),
      );
    }

    // Create variable processor factory
    final variableProcessorFactory =
        VariableProcessorFactory.fromProfiles(profilesForFactory);

    // Create initial registry with no-op strategies (only needed for brick ID lookup)
    final initialRegistry = GenerationModeRegistry(profilesForFactory);

    // Create workflow orchestrator
    final workflowOrchestrator = WorkflowOrchestratorImpl(
      templateManager: templateManager,
      variableProcessorFactory: variableProcessorFactory,
      logger: logger,
      modeRegistry: initialRegistry,
    );

    // Create use cases
    final featureUseCase =
        GenerateFeatureUseCase(workflowOrchestrator: workflowOrchestrator);
    final serviceUseCase =
        GenerateServiceUseCase(workflowOrchestrator: workflowOrchestrator);
    final projectUseCase =
        GenerateProjectUseCase(workflowOrchestrator: workflowOrchestrator);

    // Create strategies
    final featureStrategy =
        FeatureGenerationModeStrategy(useCase: featureUseCase);
    final serviceStrategy =
        ServiceGenerationModeStrategy(useCase: serviceUseCase);
    final projectStrategy =
        ProjectGenerationModeStrategy(useCase: projectUseCase);

    // Create final profiles with real strategies
    final finalProfiles = <GenerationMode, GenerationModeProfile>{
      GenerationMode.feature: GenerationModeProfile(
        mode: GenerationMode.feature,
        brickId: modeConfig[GenerationMode.feature]!.$1,
        variableProcessor: modeConfig[GenerationMode.feature]!.$2,
        strategy: featureStrategy,
      ),
      GenerationMode.service: GenerationModeProfile(
        mode: GenerationMode.service,
        brickId: modeConfig[GenerationMode.service]!.$1,
        variableProcessor: modeConfig[GenerationMode.service]!.$2,
        strategy: serviceStrategy,
      ),
      GenerationMode.project: GenerationModeProfile(
        mode: GenerationMode.project,
        brickId: modeConfig[GenerationMode.project]!.$1,
        variableProcessor: modeConfig[GenerationMode.project]!.$2,
        strategy: projectStrategy,
      ),
    };

    // Create final registry and factory
    final finalRegistry = GenerationModeRegistry(finalProfiles);
    final finalVariableProcessorFactory =
        VariableProcessorFactory.fromProfiles(finalProfiles);

    // Create final workflow orchestrator
    final finalWorkflowOrchestrator = WorkflowOrchestratorImpl(
      templateManager: templateManager,
      variableProcessorFactory: finalVariableProcessorFactory,
      logger: logger,
      modeRegistry: finalRegistry,
    );

    // Create final use cases
    final finalFeatureUseCase = GenerateFeatureUseCase(
      workflowOrchestrator: finalWorkflowOrchestrator,
    );
    final finalServiceUseCase = GenerateServiceUseCase(
      workflowOrchestrator: finalWorkflowOrchestrator,
    );
    final finalProjectUseCase = GenerateProjectUseCase(
      workflowOrchestrator: finalWorkflowOrchestrator,
    );

    // Create final strategies
    final finalFeatureStrategy =
        FeatureGenerationModeStrategy(useCase: finalFeatureUseCase);
    final finalServiceStrategy =
        ServiceGenerationModeStrategy(useCase: finalServiceUseCase);
    final finalProjectStrategy =
        ProjectGenerationModeStrategy(useCase: finalProjectUseCase);

    // Register all services
    container
      ..registerSingleton<GenerationModeRegistry>(finalRegistry)
      ..registerSingleton<IVariableProcessorFactory>(finalVariableProcessorFactory)
      ..registerSingleton<IWorkflowOrchestrator>(finalWorkflowOrchestrator)
      ..registerSingleton<GenerateFeatureUseCase>(finalFeatureUseCase)
      ..registerSingleton<GenerateServiceUseCase>(finalServiceUseCase)
      ..registerSingleton<GenerateProjectUseCase>(finalProjectUseCase)
      ..registerSingleton<FeatureGenerationModeStrategy>(finalFeatureStrategy)
      ..registerSingleton<ServiceGenerationModeStrategy>(finalServiceStrategy)
      ..registerSingleton<ProjectGenerationModeStrategy>(finalProjectStrategy)
      ..registerSingleton<GenerationCommandHandler>(
        GenerationCommandHandler(registry: finalRegistry),
      )
      ..registerSingleton<GenerationMcpAdapter>(
        GenerationMcpAdapter(registry: finalRegistry),
      );
  }
}

/// No-op strategy used only during initialization.
///
/// This strategy is never executed - it's only used to satisfy type requirements
/// when creating initial profiles for the variable processor factory and registry.
/// The workflow orchestrator only uses the registry for brick ID lookup, not
/// strategy execution.
class _NoOpStrategy implements GenerationModeStrategy<GenerationRequestDto> {
  _NoOpStrategy(this._mode);

  final GenerationMode _mode;

  @override
  GenerationMode get mode => _mode;

  @override
  Future<GenerationResultDto> execute(GenerationRequestDto request) {
    throw StateError(
      'No-op strategy should never be executed. '
      'This indicates a bug in factory initialization.',
    );
  }

  @override
  List<NextStep> getNextSteps(GenerationResultDto result) {
    throw StateError(
      'No-op strategy should never be executed. '
      'This indicates a bug in factory initialization.',
    );
  }
}
