import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/core/templates/brick/foundation_brick_registry_factory.dart';
import 'package:fly_cli/src/core/templates/variables/variable_derivers/foundation_pipeline.dart';
import 'package:fly_cli/src/core/templates/workflows/foundation_workflow_registry_factory.dart';

/// Factory for creating foundation-specific composers and orchestrators.
///
/// This factory provides configured instances of BrickComposer and
/// BrickOrchestrator using the Fly foundation variable derivation pipeline,
/// workflow definitions, and brick definitions.
class BrickComposerFactory {
  /// Creates a BrickComposer configured with the foundation variable pipeline,
  /// workflow registry, and brick registry.
  ///
  /// [logger] is used for logging during composition.
  /// [brickRegistry] and [workflowRegistry] are optional; defaults will be used if not provided.
  static BrickComposer createComposer({
    ComposerLogger? logger,
    BrickRegistry? brickRegistry,
    WorkflowRegistry? workflowRegistry,
  }) {
    final registry = brickRegistry ?? FoundationBrickRegistryFactory.create();
    final finalWorkflowRegistry = workflowRegistry ??
        FoundationWorkflowRegistryFactory.create(registry);
    return BrickComposer(
      variablePipeline: createFoundationPipeline(),
      workflowRegistry: finalWorkflowRegistry,
      logger: logger,
      brickRegistry: registry,
    );
  }

  /// Creates a BrickOrchestrator configured with the foundation variable pipeline.
  ///
  /// [executor] is responsible for executing brick generation.
  /// [logger] is used for logging orchestration progress.
  /// [composer] is optional; a default composer with foundation pipeline will be created if not provided.
  static BrickOrchestrator<TFile> createOrchestrator<TFile>({
    required BrickExecutor<TFile> executor,
    ComposerLogger? logger,
    BrickComposer? composer,
  }) {
    final finalComposer = composer ?? createComposer(logger: logger);
    return BrickOrchestrator<TFile>(
      executor: executor,
      logger: logger ?? const NoOpLogger(),
      composer: finalComposer,
    );
  }
}

