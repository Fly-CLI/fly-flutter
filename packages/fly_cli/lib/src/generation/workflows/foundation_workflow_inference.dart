import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/generation/workflows/foundation_workflows.dart';

/// Helper for inferring foundation workflow IDs from raw variables.
///
/// Maps GenerationMode to the appropriate WorkflowId for Fly foundation.
class FoundationWorkflowInference {
  FoundationWorkflowInference._();

  /// Infers the foundation workflow ID from raw variables.
  ///
  /// Uses the `generation_mode` in [rawVars] to determine which workflow
  /// should be used:
  /// - `project` → foundation_project workflow
  /// - `feature` → feature_only workflow
  /// - `service` → service_only workflow
  ///
  /// Throws [ComposerException] if the generation mode is invalid or cannot
  /// be inferred.
  static WorkflowId inferFromVars(Map<String, dynamic> rawVars) {
    final generationMode = GenerationMode.fromVars(rawVars);
    return inferFromMode(generationMode);
  }

  /// Infers the foundation workflow ID from a generation mode.
  ///
  /// Maps:
  /// - [GenerationMode.project] → foundation_project workflow
  /// - [GenerationMode.feature] → feature_only workflow
  /// - [GenerationMode.service] → service_only workflow
  static WorkflowId inferFromMode(GenerationMode mode) {
    switch (mode) {
      case GenerationMode.project:
        return FoundationWorkflowIds.foundationProject;
      case GenerationMode.feature:
        return FoundationWorkflowIds.featureOnly;
      case GenerationMode.service:
        return FoundationWorkflowIds.serviceOnly;
    }
  }
}
