import 'package:fly_cli/src/generation/application/modes/generation_mode_profile.dart';
import 'package:fly_cli/src/generation/application/ports/iworkflow_orchestrator.dart';
import 'package:fly_cli/src/generation/domain/generation_error_mapper.dart';
import 'package:fly_cli/src/generation/foundation/generation_orchestrator.dart';
import 'package:fly_cli/src/generation/generators/generation_result.dart';
import 'package:fly_cli/src/generation/template/template_manager.dart';
import 'package:mason_logger/mason_logger.dart';

/// Implementation of [IWorkflowOrchestrator] backed by the BrickComposer-based
/// foundation orchestration pipeline.
///
/// All generation modes (project, feature, service) are executed through the
/// same BrickComposer/BrickOrchestrator workflow. This keeps single and
/// composite generation paths consistent and easy to extend.
///
/// This orchestrator is mode-agnostic at construction time and profile-driven
/// at execution time. All mode-specific dependencies (brick ID, variable processor)
/// are obtained directly from the provided [GenerationModeProfile].
class WorkflowOrchestratorImpl implements IWorkflowOrchestrator {
  /// Creates a new [WorkflowOrchestratorImpl] instance.
  ///
  /// [templateManager] is used to resolve bricks for generation.
  /// [logger] is used for logging generation operations.
  ///
  /// Note: Mode-specific configuration is provided via [GenerationModeProfile]
  /// at execution time, not at construction time.
  WorkflowOrchestratorImpl({
    required TemplateManager templateManager,
    required Logger logger,
  }) : _templateManager = templateManager,
       _logger = logger;

  final TemplateManager _templateManager;
  final Logger _logger;

  @override
  Future<GenerationResult> executeWorkflow({
    required GenerationModeProfile profile,
    required Map<String, dynamic> variables,
    required String outputDirectory,
    bool dryRun = false,
  }) async {
    // Ensure generation_mode is aligned with the requested mode so that
    // the composer and workflow inference see a consistent view.
    final rawVars = <String, dynamic>{
      ...variables,
      'generation_mode': profile.mode.key,
    };

    // 1. Get brick for variable processing and validation
    // Get brick ID directly from the profile (single source of truth)
    final brickId = profile.brickId.key;
    final brick = await _templateManager.getBrick(brickId);
    if (brick == null) {
      final errorData = {'brick_id': brickId, 'mode': profile.mode.key};
      return GenerationResult.failure(
        error: 'Brick "$brickId" not found for mode ${profile.mode.key}',
        errorType: GenerationErrorMapper.fromData(errorData),
        data: errorData,
      );
    }

    // 2. Get the appropriate processor for the mode and process variables
    // Get processor directly from the profile (single source of truth)
    final processor = profile.variableProcessor;
    final processed = await processor.process(
      rawVars: rawVars,
      mode: profile.mode,
      brick: brick,
    );

    // 3. Validate variables - fail early if validation fails
    if (!processed.validationResult.isValid) {
      final errorData = {
        'validation_errors': processed.validationResult.errors,
        'brick_id': brickId,
        'mode': profile.mode.key,
      };
      return GenerationResult.failure(
        error:
            'Variable validation failed: ${processed.validationResult.errors.join(', ')}',
        errorType: GenerationErrorMapper.fromData(errorData),
        data: errorData,
      );
    }

    // 4. Delegate to the foundation GenerationOrchestrator which
    // encapsulates BrickComposer- and BrickOrchestrator-based workflows
    // and fully respects the dryRun flag for all modes.
    // Use processed variables (which include derived variables and validated values)
    final orchestrator = GenerationOrchestrator(
      templateManager: _templateManager,
      logger: _logger,
    );

    return orchestrator.generate(
      rawVars: processed.values,
      outputDirectory: outputDirectory,
      dryRun: dryRun,
    );
  }
}
