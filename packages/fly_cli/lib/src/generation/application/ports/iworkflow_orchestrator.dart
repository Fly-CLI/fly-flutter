import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/generation/generators/generation_result.dart';

/// Interface for workflow orchestration.
///
/// Handles complex multi-step generation workflows, particularly
/// for foundation project generation.
abstract class IWorkflowOrchestrator {
  /// Execute a generation workflow.
  ///
  /// [mode] is the generation mode.
  /// [variables] are the input variables.
  /// [outputDirectory] is where files should be generated.
  /// [dryRun] if true, generates a preview instead of actual files.
  ///
  /// Returns a [GenerationResult] with success status.
  Future<GenerationResult> executeWorkflow({
    required GenerationMode mode,
    required Map<String, dynamic> variables,
    required String outputDirectory,
    bool dryRun = false,
  });

  /// Infer the workflow for a given mode.
  ///
  /// Returns the workflow ID that should be used.
  Future<WorkflowId> inferWorkflow(GenerationMode mode);
}
