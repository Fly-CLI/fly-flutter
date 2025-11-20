import 'package:fly_foundation_planning/fly_foundation_planning.dart';
import 'package:fly_cli/src/core/templates/bricks/foundation_brick_registry_factory.dart';
import 'package:fly_cli/src/core/templates/variable_derivers/foundation_pipeline.dart';
import 'package:fly_cli/src/core/templates/workflows/foundation_workflow_registry_factory.dart';

/// Factory for creating foundation-specific planners and orchestrators.
///
/// This factory provides configured instances of FoundationPlanner and
/// FoundationOrchestrator using the Fly foundation variable derivation pipeline,
/// workflow definitions, and brick definitions.
class FoundationPlannerFactory {
  /// Creates a FoundationPlanner configured with the foundation variable pipeline,
  /// workflow registry, and brick registry.
  ///
  /// [logger] is used for logging during planning.
  /// [brickRegistry] and [workflowRegistry] are optional; defaults will be used if not provided.
  static FoundationPlanner createPlanner({
    PlanningLogger? logger,
    BrickRegistry? brickRegistry,
    WorkflowRegistry? workflowRegistry,
  }) {
    final registry = brickRegistry ?? FoundationBrickRegistryFactory.create();
    final finalWorkflowRegistry = workflowRegistry ??
        FoundationWorkflowRegistryFactory.create(registry);
    return FoundationPlanner(
      variablePipeline: createFoundationPipeline(),
      workflowRegistry: finalWorkflowRegistry,
      logger: logger,
      brickRegistry: registry,
    );
  }

  /// Creates a FoundationOrchestrator configured with the foundation variable pipeline.
  ///
  /// [executor] is responsible for executing brick generation.
  /// [logger] is used for logging orchestration progress.
  /// [planner] is optional; a default planner with foundation pipeline will be created if not provided.
  static FoundationOrchestrator<TFile> createOrchestrator<TFile>({
    required BrickExecutor<TFile> executor,
    PlanningLogger? logger,
    FoundationPlanner? planner,
  }) {
    final finalPlanner = planner ?? createPlanner(logger: logger);
    return FoundationOrchestrator<TFile>(
      executor: executor,
      logger: logger ?? const NoOpLogger(),
      planner: finalPlanner,
    );
  }
}

