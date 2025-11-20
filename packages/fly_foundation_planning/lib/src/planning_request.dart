import 'package:fly_foundation_planning/src/foundation_model.dart';
import 'package:fly_foundation_planning/src/workflow_definition.dart';

/// A normalized planning request that represents user input.
class PlanningRequest {
  PlanningRequest({
    required this.workflowId,
    required this.raw,
    GenerationMode? generationMode,
  }) : generationMode = generationMode ?? GenerationMode.fromVars(raw);

  /// Workflow identifier indicating which workflow to execute.
  final WorkflowId workflowId;

  /// Generation mode (project, feature, service).
  final GenerationMode generationMode;

  /// Raw input variables from CLI, manifest, or interactive prompts.
  ///
  /// This should contain:
  /// - Project-level fields: name, organization, description, platforms, preset, etc.
  /// - For repeatable steps: arrays like `features: [...]` and `services: [...]`
  ///   where each entry is a map with `name` and `params`.
  final Map<String, dynamic> raw;

  /// Creates a planning request from raw variables.
  ///
  /// Attempts to infer the workflow ID from the raw variables if not explicitly provided.
  factory PlanningRequest.fromVars(
    Map<String, dynamic> rawVars, {
    WorkflowId? workflowId,
  }) {
    final inferredWorkflowId = workflowId ?? _inferWorkflowId(rawVars);
    return PlanningRequest(
      workflowId: inferredWorkflowId,
      raw: rawVars,
    );
  }

  /// Infers the workflow ID from raw variables.
  static WorkflowId _inferWorkflowId(Map<String, dynamic> rawVars) {
    final generationMode = GenerationMode.fromVars(rawVars);
    switch (generationMode) {
      case GenerationMode.project:
        return WorkflowId.foundationProject;
      case GenerationMode.feature:
        return WorkflowId.featureOnly;
      case GenerationMode.service:
        return WorkflowId.serviceOnly;
    }
  }
}
