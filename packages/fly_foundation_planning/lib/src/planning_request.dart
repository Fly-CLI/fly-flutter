import 'package:fly_foundation_planning/src/foundation_model.dart';
import 'package:fly_foundation_planning/src/workflow_definition.dart';

/// A normalized planning request that represents user input.
///
/// This is a domain-agnostic request. Domain-specific workflow inference
/// (e.g., mapping GenerationMode to WorkflowId) should be handled by
/// higher-level packages (e.g., fly_cli).
class PlanningRequest {
  PlanningRequest({
    required this.workflowId,
    required this.raw,
    GenerationMode? generationMode,
  }) : generationMode = generationMode ?? GenerationMode.fromVars(raw);

  /// Workflow identifier indicating which workflow to execute.
  ///
  /// This must be provided explicitly. Domain-specific inference should be
  /// done by the caller (e.g., in fly_cli).
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

  /// Creates a planning request from raw variables with an explicit workflow ID.
  ///
  /// The [workflowId] is required. Domain-specific inference logic should be
  /// provided by higher-level packages.
  factory PlanningRequest.fromVars(
    Map<String, dynamic> rawVars, {
    required WorkflowId workflowId,
    GenerationMode? generationMode,
  }) {
    return PlanningRequest(
      workflowId: workflowId,
      raw: rawVars,
      generationMode: generationMode,
    );
  }
}
