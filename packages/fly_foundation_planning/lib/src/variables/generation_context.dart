import 'package:fly_foundation_planning/src/foundation_model.dart';
import 'package:fly_foundation_planning/src/workflow_definition.dart';

/// Context representing normalized input for a planning run.
///
/// This class encapsulates all input information needed for variable derivation,
/// keeping it minimal and domain-agnostic. Domain-specific interpretation happens
/// in derivation strategies, not in the core context model.
class GenerationContext {
  const GenerationContext({
    required this.rawVars,
    required this.mode,
    this.workflowId,
  });

  /// Raw input variables as provided by the user.
  final Map<String, dynamic> rawVars;

  /// Generation mode (project, feature, service, or user-defined).
  final GenerationMode mode;

  /// Optional workflow identifier.
  final WorkflowId? workflowId;

  /// Creates a generation context from raw variables.
  ///
  /// Infers the generation mode from rawVars if not explicitly provided.
  factory GenerationContext.fromVars(
    Map<String, dynamic> rawVars, {
    GenerationMode? mode,
    WorkflowId? workflowId,
  }) {
    final inferredMode = mode ?? GenerationMode.fromVars(rawVars);
    return GenerationContext(
      rawVars: rawVars,
      mode: inferredMode,
      workflowId: workflowId,
    );
  }
}

