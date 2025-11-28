import 'package:fly_cli/src/cli/application/bootstrapping/service_bootstrapper_config.dart';
import 'package:fly_cli/src/cli/domain/interfaces/i_service_container.dart';
import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/modes/generation_mode_profile.dart';
import 'package:fly_cli/src/generation/application/modes/generation_request_factory.dart';
import 'package:fly_cli/src/generation/application/ports/icache_manager.dart';
import 'package:fly_cli/src/generation/application/ports/igeneration_engine.dart';
import 'package:fly_cli/src/generation/application/ports/ivariable_processor.dart';
import 'package:fly_cli/src/generation/application/ports/iworkflow_orchestrator.dart';
import 'package:fly_cli/src/generation/application/services/processors/feature_variable_processor.dart';
import 'package:fly_cli/src/generation/application/services/processors/project_variable_processor.dart';
import 'package:fly_cli/src/generation/application/services/processors/service_variable_processor.dart';
import 'package:fly_cli/src/generation/application/strategies/feature_generation_executor.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_executor_registry.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_executor.dart';
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
import 'package:fly_cli/src/generation/generation_variable_builder.dart';
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
import 'package:fly_cli/src/generation/utils/planning_logger_adapter.dart';
import 'package:fly_cli/src/generation/versioning/compatibility_checker.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/adapters/generation_mcp_adapter.dart';
import 'package:fly_cli/src/shared/di/service_container.dart';
import 'package:fly_cli/src/shared/logging/infrastructure/structured_mason_logger.dart';
import 'package:fly_cli/src/shared/utils/version_utils.dart';
import 'package:pub_semver/pub_semver.dart';

/// Type alias for the profiles map - the single source of truth for generation modes.
typedef GenerationProfiles = Map<GenerationMode, GenerationModeProfile>;

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
/// Creates all components in dependency order with GenerationModeProfile as the
/// single source of truth. All mode-specific logic and dependencies flow from
/// the profiles map, which is built once and injected everywhere.
///
/// Initialization flow:
/// 1. Infrastructure (adapters, repositories)
/// 2. Variable processors
/// 3. Generation engine
/// 4. Workflow orchestrator (mode-agnostic at construction)
/// 5. Use cases, strategies, and profiles (built together for each mode)
/// 6. Registry and handlers (consume profiles directly)
class GenerationServicesFactory implements IGenerationServicesFactory {
  /// Creates a new GenerationServicesFactory instance.
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
    _registerStrategiesAndProfiles(serviceContainer, logger);
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

  void _registerStrategiesAndProfiles(
    ServiceContainer container,
    StructuredMasonLogger logger,
  ) {
    final templateManager = container.get<TemplateManager>();
    final projectProcessor = container.get<ProjectVariableProcessor>();
    final featureProcessor = container.get<FeatureVariableProcessor>();
    final serviceProcessor = container.get<ServiceVariableProcessor>();

    // Step 1: Create workflow orchestrator (mode-agnostic, no profile dependencies)
    final workflowOrchestrator = WorkflowOrchestratorImpl(
      templateManager: templateManager,
      logger: logger,
    );

    // Step 2: Build mode-specific components for each mode
    // Each mode's components (use case, strategy, profile) are built together
    // to ensure proper wiring without circular dependencies

    final featureComponents = _buildModeComponents(
      mode: GenerationMode.feature,
      brickId: BrickId.feature,
      processor: featureProcessor,
      orchestrator: workflowOrchestrator,
    );

    final serviceComponents = _buildModeComponents(
      mode: GenerationMode.service,
      brickId: BrickId.service,
      processor: serviceProcessor,
      orchestrator: workflowOrchestrator,
    );

    final projectComponents = _buildModeComponents(
      mode: GenerationMode.project,
      brickId: BrickId.project,
      processor: projectProcessor,
      orchestrator: workflowOrchestrator,
    );

    // Step 3: Build the canonical profiles map - single source of truth
    final profiles = <GenerationMode, GenerationModeProfile>{
      GenerationMode.feature: featureComponents.profile,
      GenerationMode.service: serviceComponents.profile,
      GenerationMode.project: projectComponents.profile,
    };

    // Step 4: Create registry as a thin view over profiles
    final registry = GenerationExecutorRegistry(profiles);

    // Step 5: Register all services
    container
      ..registerSingleton<GenerationProfiles>(profiles)
      ..registerSingleton<IWorkflowOrchestrator>(workflowOrchestrator)
      ..registerSingleton<GenerateFeatureUseCase>(
        featureComponents.useCase as GenerateFeatureUseCase,
      )
      ..registerSingleton<GenerateServiceUseCase>(
        serviceComponents.useCase as GenerateServiceUseCase,
      )
      ..registerSingleton<GenerateProjectUseCase>(
        projectComponents.useCase as GenerateProjectUseCase,
      )
      ..registerSingleton<FeatureGenerationExecutor>(
        featureComponents.strategy as FeatureGenerationExecutor,
      )
      ..registerSingleton<ServiceGenerationExecutor>(
        serviceComponents.strategy as ServiceGenerationExecutor,
      )
      ..registerSingleton<ProjectGenerationExecutor>(
        projectComponents.strategy as ProjectGenerationExecutor,
      )
      ..registerSingleton<GenerationExecutorRegistry>(registry)
      ..registerSingleton<GenerationMcpAdapter>(
        GenerationMcpAdapter(registry: registry),
      );
  }

  /// Builds all components for a single generation mode.
  ///
  /// Creates use case, strategy, variable builder, request factory, and profile together.
  /// Since profiles need strategies, strategies need use cases, and use cases need profiles,
  /// we break the circular dependency by building them together atomically.
  ///
  /// The solution: create temporary components only during construction (they're never executed),
  /// then create the final components with everything properly wired.
  _ModeComponents _buildModeComponents({
    required GenerationMode mode,
    required BrickId brickId,
    required IVariableProcessor processor,
    required IWorkflowOrchestrator orchestrator,
  }) {
    // Create mode-specific variable builder and request factory
    final variableBuilder = _createVariableBuilder(mode);
    final requestFactory = _createRequestFactory(mode);

    // Phase 1: Create temporary components to break circular dependency
    // These are only used during construction, never executed in production
    final tempStrategy = _GenerationExecutor(mode);
    final tempProfile = GenerationModeProfile(
      mode: mode,
      brickId: brickId,
      variableProcessor: processor,
      strategy: tempStrategy,
      variableBuilder: variableBuilder,
      requestFactory: requestFactory,
    );

    // Phase 2: Create use case with temporary profile
    final tempUseCase = _createUseCase(mode, orchestrator, tempProfile);

    // Phase 3: Create strategy with use case
    final strategy =
        _createStrategy(
              mode,
              tempUseCase,
            );

    // Phase 4: Create final profile with real strategy
    final profile = GenerationModeProfile(
      mode: mode,
      brickId: brickId,
      variableProcessor: processor,
      strategy: strategy,
      variableBuilder: variableBuilder,
      requestFactory: requestFactory,
    );

    // Phase 5: Create final use case with final profile
    final finalUseCase = _createUseCase(mode, orchestrator, profile);

    // Phase 6: Create final strategy with final use case
    final finalStrategy =
        _createStrategy(
              mode,
              finalUseCase,
            );

    // Phase 7: Create ultimate final profile with final strategy
    final finalProfile = GenerationModeProfile(
      mode: mode,
      brickId: brickId,
      variableProcessor: processor,
      strategy: finalStrategy,
      variableBuilder: variableBuilder,
      requestFactory: requestFactory,
    );

    return _ModeComponents(
      mode: mode,
      useCase: finalUseCase,
      strategy: finalStrategy,
      profile: finalProfile,
    );
  }

  /// Creates a variable builder for the given mode.
  GenerationVariableBuilder _createVariableBuilder(GenerationMode mode) {
    switch (mode) {
      case GenerationMode.feature:
        return const FeatureVariableBuilder();
      case GenerationMode.service:
        return const ServiceVariableBuilder();
      case GenerationMode.project:
        return const ProjectVariableBuilder();
    }
  }

  /// Creates a request factory for the given mode.
  GenerationRequestFactory _createRequestFactory(GenerationMode mode) {
    switch (mode) {
      case GenerationMode.feature:
        return const FeatureRequestFactory();
      case GenerationMode.service:
        return const ServiceRequestFactory();
      case GenerationMode.project:
        return const ProjectRequestFactory();
    }
  }

  dynamic _createUseCase(
    GenerationMode mode,
    IWorkflowOrchestrator orchestrator,
    GenerationModeProfile profile,
  ) {
    switch (mode) {
      case GenerationMode.feature:
        return GenerateFeatureUseCase(
          workflowOrchestrator: orchestrator,
          profile: profile,
        );
      case GenerationMode.service:
        return GenerateServiceUseCase(
          workflowOrchestrator: orchestrator,
          profile: profile,
        );
      case GenerationMode.project:
        return GenerateProjectUseCase(
          workflowOrchestrator: orchestrator,
          profile: profile,
        );
    }
  }

  GenerationExecutor<GenerationRequestDto> _createStrategy(
    GenerationMode mode,
    dynamic useCase,
  ) {
    switch (mode) {
      case GenerationMode.feature:
        return FeatureGenerationExecutor(
          useCase: useCase as GenerateFeatureUseCase,
        );
      case GenerationMode.service:
        return ServiceGenerationExecutor(
          useCase: useCase as GenerateServiceUseCase,
        );
      case GenerationMode.project:
        return ProjectGenerationExecutor(
          useCase: useCase as GenerateProjectUseCase,
        );
    }
  }
}

/// Helper class to hold mode components during construction.
class _ModeComponents {
  _ModeComponents({
    required this.mode,
    required this.useCase,
    required this.strategy,
    required this.profile,
  });

  final GenerationMode mode;
  final dynamic useCase;
  final GenerationExecutor<GenerationRequestDto> strategy;
  final GenerationModeProfile profile;
}

/// Strategy used only during construction to break circular dependency.
///
/// This strategy is never executed - it exists only to satisfy type requirements
/// when creating profiles during the initialization process. Once the real strategies
/// are created, this is replaced and discarded.
///
/// Note: This is the minimal necessary workaround to break the circular dependency
/// between profiles, use cases, and strategies. It is only used during factory
/// initialization and is never exposed or executed in production code.
class _GenerationExecutor
    implements GenerationExecutor<GenerationRequestDto> {
  _GenerationExecutor(this._mode);

  final GenerationMode _mode;

  @override
  GenerationMode get mode => _mode;

  @override
  Future<GenerationResultDto> execute(GenerationRequestDto request) {
    throw StateError(
      'Construction strategy should never be executed. '
      'This indicates a bug in factory initialization.',
    );
  }

  @override
  List<NextStep> getNextSteps(GenerationResultDto result) {
    throw StateError(
      'Construction strategy should never be executed. '
      'This indicates a bug in factory initialization.',
    );
  }
}
