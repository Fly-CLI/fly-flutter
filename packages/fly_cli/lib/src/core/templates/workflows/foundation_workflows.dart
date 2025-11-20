import 'package:fly_foundation_planning/fly_foundation_planning.dart';

/// Foundation-specific workflow identifiers.
class FoundationWorkflowIds {
  FoundationWorkflowIds._();

  /// Foundation project workflow (project + optional features + optional services).
  static const foundationProject = WorkflowId('foundation_project');

  /// Feature-only workflow (single feature generation).
  static const featureOnly = WorkflowId('feature_only');

  /// Service-only workflow (single service generation).
  static const serviceOnly = WorkflowId('service_only');
}

/// Foundation project workflow definition.
///
/// This workflow includes:
/// - Phase 0: Project template brick
/// - Phase 1: Feature bricks (repeatable, selected from 'features' key)
/// - Phase 2: Service bricks (repeatable, selected from 'services' key)
const foundationProjectWorkflow = WorkflowDefinition(
  id: FoundationWorkflowIds.foundationProject,
  steps: [
    WorkflowStep(
      id: 'project',
      brickId: 'fly_foundation_project',
      defaultPhase: 0,
      repeatable: false,
    ),
    WorkflowStep(
      id: 'features',
      brickId: 'fly_foundation_feature',
      defaultPhase: 1,
      repeatable: true,
      selectionKey: 'features',
    ),
    WorkflowStep(
      id: 'services',
      brickId: 'fly_foundation_service',
      defaultPhase: 2,
      repeatable: true,
      selectionKey: 'services',
    ),
  ],
);

/// Feature-only workflow definition.
///
/// This workflow includes:
/// - Phase 0: Single feature brick
const featureOnlyWorkflow = WorkflowDefinition(
  id: FoundationWorkflowIds.featureOnly,
  steps: [
    WorkflowStep(
      id: 'feature',
      brickId: 'fly_foundation_feature',
      defaultPhase: 0,
      repeatable: false,
    ),
  ],
);

/// Service-only workflow definition.
///
/// This workflow includes:
/// - Phase 0: Single service brick
const serviceOnlyWorkflow = WorkflowDefinition(
  id: FoundationWorkflowIds.serviceOnly,
  steps: [
    WorkflowStep(
      id: 'service',
      brickId: 'fly_foundation_service',
      defaultPhase: 0,
      repeatable: false,
    ),
  ],
);

