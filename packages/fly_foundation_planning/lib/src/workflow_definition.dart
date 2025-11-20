import 'package:fly_foundation_planning/src/brick_registry.dart';
import 'package:fly_foundation_planning/src/planning_exception.dart';

/// Identifier for a workflow.
enum WorkflowId {
  /// Foundation project workflow (project + optional features + optional services).
  foundationProject('foundation_project'),

  /// Feature-only workflow (single feature generation).
  featureOnly('feature_only'),

  /// Service-only workflow (single service generation).
  serviceOnly('service_only');

  const WorkflowId(this.value);

  final String value;

  @override
  String toString() => value;
}

/// A single step in a workflow definition.
class WorkflowStep {
  const WorkflowStep({
    required this.id,
    required this.brickId,
    required this.defaultPhase,
    this.repeatable = false,
    this.selectionKey,
  });

  /// Unique identifier for this step within the workflow.
  final String id;

  /// Brick ID to use for this step.
  final String brickId;

  /// Default phase/ordering (lower numbers run first).
  final int defaultPhase;

  /// Whether this step can be repeated multiple times.
  final bool repeatable;

  /// Key in the raw input to look up for repeatable steps (e.g., 'features', 'services').
  ///
  /// If null and repeatable is true, the step will be skipped.
  final String? selectionKey;
}

/// Definition of a workflow that describes how to compose bricks.
class WorkflowDefinition {
  const WorkflowDefinition({
    required this.id,
    required this.steps,
  });

  /// Workflow identifier.
  final WorkflowId id;

  /// Ordered list of workflow steps.
  final List<WorkflowStep> steps;

  /// Gets a step by its ID.
  WorkflowStep? getStepById(String stepId) {
    try {
      return steps.firstWhere((step) => step.id == stepId);
    } catch (_) {
      return null;
    }
  }

  /// Validates that all referenced brick IDs are valid.
  void validateBrickIds(BrickRegistry registry) {
    for (final step in steps) {
      registry.validateBrickId(step.brickId);
    }
  }
}

/// Registry of workflow definitions.
class WorkflowRegistry {

  /// Creates an empty registry.
  WorkflowRegistry();

  /// Creates a registry with default workflows registered.
  factory WorkflowRegistry.defaultRegistry(BrickRegistry brickRegistry) {
    final registry = WorkflowRegistry()
    .._registerDefaultWorkflows();
    // Validate all workflows against the brick registry
    for (final workflow in registry._workflows.values) {
      workflow.validateBrickIds(brickRegistry);
    }
    return registry;
  }
  final Map<WorkflowId, WorkflowDefinition> _workflows = {};

  /// Registers a workflow definition.
  void register(WorkflowDefinition workflow) {
    _workflows[workflow.id] = workflow;
  }

  /// Gets a workflow by its ID.
  WorkflowDefinition? getById(WorkflowId id) => _workflows[id];

  /// Validates that a workflow ID exists.
  void validateWorkflowId(WorkflowId workflowId) {
    if (!_workflows.containsKey(workflowId)) {
      throw PlanningException(
        'Unknown workflow ID: "${workflowId.value}". '
        'Available workflows: ${_workflows.keys.map((id) => id.value).join(", ")}.',
      );
    }
  }

  /// Registers default workflows.
  void _registerDefaultWorkflows() {
    // Foundation project workflow: project + optional features + optional services
    register(const WorkflowDefinition(
      id: WorkflowId.foundationProject,
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
    ));

    // Feature-only workflow
    register(const WorkflowDefinition(
      id: WorkflowId.featureOnly,
      steps: [
        WorkflowStep(
          id: 'feature',
          brickId: 'fly_foundation_feature',
          defaultPhase: 0,
          repeatable: false,
        ),
      ],
    ));

    // Service-only workflow
    register(const WorkflowDefinition(
      id: WorkflowId.serviceOnly,
      steps: [
        WorkflowStep(
          id: 'service',
          brickId: 'fly_foundation_service',
          defaultPhase: 0,
          repeatable: false,
        ),
      ],
    ));
  }
}

