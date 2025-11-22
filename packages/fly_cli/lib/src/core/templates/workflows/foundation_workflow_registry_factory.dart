import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/core/templates/bricks/foundation_brick_registry_factory.dart';
import 'package:fly_cli/src/core/templates/workflows/foundation_workflows.dart';

/// Factory for creating a WorkflowRegistry configured with Fly foundation workflows.
class FoundationWorkflowRegistryFactory {
  /// Creates a WorkflowRegistry with all foundation workflows registered.
  ///
  /// Registers:
  /// - Foundation project workflow
  /// - Feature-only workflow
  /// - Service-only workflow
  ///
  /// [brickRegistry] is used to validate that all brick IDs referenced in
  /// workflows exist. If not provided, uses FoundationBrickRegistryFactory.create().
  static WorkflowRegistry create(BrickRegistry? brickRegistry) {
    final registry = brickRegistry ?? FoundationBrickRegistryFactory.create();
    final workflowRegistry = WorkflowRegistry();

    // Register all foundation workflows
    workflowRegistry.register(foundationProjectWorkflow);
    workflowRegistry.register(featureOnlyWorkflow);
    workflowRegistry.register(serviceOnlyWorkflow);

    // Validate all workflows against brick registry
    workflowRegistry.validateAll(registry);

    return workflowRegistry;
  }
}

