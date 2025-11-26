import 'package:fly_brick_composer/src/registry/workflow_definition.dart';

import 'composer_model.dart';

/// A normalized composer request that represents user input.
///
/// This is a domain-agnostic request. Domain-specific workflow inference
/// (e.g., mapping GenerationMode to WorkflowId) should be handled by
/// higher-level packages (e.g., fly_cli).
class ComposerRequest {
  /// Creates a new composer request.
  ///
  /// [workflowId] is required.
  ComposerRequest({
    required this.workflowId,
    required this.raw,
  }) ;

  /// Creates a composer request from raw variables with an explicit workflow ID.
  ///
  /// The [workflowId] is required. Domain-specific inference logic should be
  /// provided by higher-level packages.
  factory ComposerRequest.fromVars(
    Map<String, dynamic> rawVars, {
    required WorkflowId workflowId,
  }) {
    return ComposerRequest(
      workflowId: workflowId,
      raw: rawVars,
    );
  }

  /// Workflow identifier indicating which workflow to execute.
  ///
  /// This must be provided explicitly. Domain-specific inference should be
  /// done by the caller (e.g., in fly_cli).
  final WorkflowId workflowId;

  /// Raw input variables from CLI, manifest, or interactive prompts.
  ///
  /// This should contain:
  /// - Project-level fields: name, organization, description, platforms, preset, etc.
  /// - For repeatable steps: arrays like `features: [...]` and `services: [...]`
  ///   where each entry is a map with `name` and `params`.
  final Map<String, dynamic> raw;
}
