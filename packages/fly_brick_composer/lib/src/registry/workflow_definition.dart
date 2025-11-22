import 'package:fly_brick_composer/src/exceptions/composer_exception.dart';

import 'brick_registry.dart';

/// Identifier for a workflow.
///
/// This is a domain-agnostic value object. Domain-specific workflow IDs
/// (e.g., for Fly CLI) should be defined in higher-level packages.
class WorkflowId {
  const WorkflowId(this.value);

  /// The string identifier for this workflow.
  final String value;

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkflowId && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;
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
///
/// This is a domain-agnostic registry that stores and validates workflows.
/// Domain-specific workflows (e.g., for Fly CLI) should be registered
/// by higher-level packages (e.g., fly_cli).
class WorkflowRegistry {
  final Map<WorkflowId, WorkflowDefinition> _workflows = {};

  /// Creates an empty registry.
  WorkflowRegistry();

  /// Registers a workflow definition.
  void register(WorkflowDefinition workflow) {
    _workflows[workflow.id] = workflow;
  }

  /// Gets a workflow by its ID.
  WorkflowDefinition? getById(WorkflowId id) => _workflows[id];

  /// Validates that a workflow ID exists.
  void validateWorkflowId(WorkflowId workflowId) {
    if (!_workflows.containsKey(workflowId)) {
      throw ComposerException(
        'Unknown workflow ID: "${workflowId.value}". '
        'Available workflows: ${_workflows.keys.map((id) => id.value).join(", ")}.',
      );
    }
  }

  /// Validates all registered workflows against a brick registry.
  ///
  /// This ensures that all brick IDs referenced in workflow steps exist
  /// in the given brick registry.
  void validateAll(BrickRegistry brickRegistry) {
    for (final workflow in _workflows.values) {
      workflow.validateBrickIds(brickRegistry);
    }
  }
}

