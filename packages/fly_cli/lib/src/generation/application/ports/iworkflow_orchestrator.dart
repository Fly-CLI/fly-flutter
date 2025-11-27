import 'package:fly_cli/src/generation/application/modes/generation_mode_profile.dart';
import 'package:fly_cli/src/generation/generators/generation_result.dart';

/// Interface for workflow orchestration.
///
/// Handles complex multi-step generation workflows, particularly
/// for foundation project generation.
///
/// All mode-specific dependencies (brick ID, variable processor) are obtained
/// directly from the provided [GenerationModeProfile], making this orchestrator
/// mode-agnostic at construction time and profile-driven at execution time.
abstract class IWorkflowOrchestrator {
  /// Execute a generation workflow.
  ///
  /// [profile] provides all mode-specific configuration and dependencies
  /// (brick ID, variable processor, etc.) for this generation.
  /// [variables] are the input variables.
  /// [outputDirectory] is where files should be generated.
  /// [dryRun] if true, generates a preview instead of actual files.
  ///
  /// Returns a [GenerationResult] with success status.
  Future<GenerationResult> executeWorkflow({
    required GenerationModeProfile profile,
    required Map<String, dynamic> variables,
    required String outputDirectory,
    bool dryRun = false,
  });
}
