import 'package:fly_brick_composer/fly_brick_composer.dart';

/// Test workflow identifiers for use in planning package tests.
class TestWorkflowIds {
  TestWorkflowIds._();

  /// Simple test workflow.
  static const testWorkflow = WorkflowId('test_workflow');
  
  /// Project test workflow.
  static const projectWorkflow = WorkflowId('test_project_workflow');
  
  /// Feature test workflow.
  static const featureWorkflow = WorkflowId('test_feature_workflow');
  
  /// Service test workflow.
  static const serviceWorkflow = WorkflowId('test_service_workflow');
}

/// Simple test workflow definition for use in planning package tests.
///
/// This workflow contains a single step that uses a test brick.
const testWorkflow = WorkflowDefinition(
  id: TestWorkflowIds.testWorkflow,
  steps: [
    WorkflowStep(
      id: 'test_step',
      brickId: 'test_brick',
      defaultPhase: 0,
      repeatable: false,
    ),
  ],
);

/// Test workflow for project generation.
///
/// Uses project brick to test project-specific behavior.
const testProjectWorkflow = WorkflowDefinition(
  id: TestWorkflowIds.projectWorkflow,
  steps: [
    WorkflowStep(
      id: 'project_step',
      brickId: 'project',
      defaultPhase: 0,
      repeatable: false,
    ),
  ],
);

/// Test workflow for feature generation.
///
/// Uses feature brick to test feature-specific behavior.
const testFeatureWorkflow = WorkflowDefinition(
  id: TestWorkflowIds.featureWorkflow,
  steps: [
    WorkflowStep(
      id: 'feature_step',
      brickId: 'feature',
      defaultPhase: 0,
      repeatable: false,
    ),
  ],
);

/// Test workflow for service generation.
///
/// Uses service brick to test service-specific behavior.
const testServiceWorkflow = WorkflowDefinition(
  id: TestWorkflowIds.serviceWorkflow,
  steps: [
    WorkflowStep(
      id: 'service_step',
      brickId: 'service',
      defaultPhase: 0,
      repeatable: false,
    ),
  ],
);

/// Creates a test workflow registry for use in planning package tests.
///
/// Registers test workflows that use bricks (registered in test brick registry)
/// to test the behavior while keeping the core infrastructure domain-agnostic.
WorkflowRegistry createTestWorkflowRegistry(BrickRegistry brickRegistry) {
  final registry = WorkflowRegistry()
  ..register(testWorkflow)
  ..register(testProjectWorkflow)
  ..register(testFeatureWorkflow)
  ..register(testServiceWorkflow)
  ..validateAll(brickRegistry);
  return registry;
}

