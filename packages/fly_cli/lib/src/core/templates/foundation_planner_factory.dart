import 'package:fly_foundation_planning/fly_foundation_planning.dart';
import 'package:fly_cli/src/core/templates/variable_derivers/foundation_pipeline.dart';

/// Factory for creating foundation-specific planners and orchestrators.
///
/// This factory provides configured instances of FoundationPlanner and
/// FoundationOrchestrator using the Fly foundation variable derivation pipeline.
class FoundationPlannerFactory {
  /// Creates a FoundationPlanner configured with the foundation variable pipeline.
  ///
  /// [logger] is used for logging during planning.
  /// [brickRegistry] and [workflowRegistry] are optional; defaults will be used if not provided.
  static FoundationPlanner createPlanner({
    PlanningLogger? logger,
    BrickRegistry? brickRegistry,
    WorkflowRegistry? workflowRegistry,
  }) {
    final registry = brickRegistry ?? BrickRegistry.defaultRegistry();
    return FoundationPlanner(
      variablePipeline: createFoundationPipeline(),
      logger: logger,
      brickRegistry: registry,
      workflowRegistry: workflowRegistry ?? WorkflowRegistry.defaultRegistry(registry),
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

