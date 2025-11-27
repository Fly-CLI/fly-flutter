import 'package:fly_cli/src/generation/application/ports/ivariable_processor_factory.dart';
import 'package:fly_cli/src/generation/application/ports/iworkflow_orchestrator.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_mode_registry.dart';
import 'package:fly_cli/src/generation/domain/generation_error_mapper.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
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
class WorkflowOrchestratorImpl implements IWorkflowOrchestrator {
  /// Creates a new [WorkflowOrchestratorImpl] instance.
  ///
  /// [modeRegistry] is required to access mode profiles for brick ID resolution.
  /// This ensures consistency with the single source of truth for mode configuration.
  WorkflowOrchestratorImpl({
    required TemplateManager templateManager,
    required IVariableProcessorFactory variableProcessorFactory,
    required Logger logger,
    required GenerationModeRegistry modeRegistry,
  }) : _templateManager = templateManager,
       _variableProcessorFactory = variableProcessorFactory,
       _logger = logger,
       _modeRegistry = modeRegistry;

  final TemplateManager _templateManager;
  final IVariableProcessorFactory _variableProcessorFactory;
  final Logger _logger;
  final GenerationModeRegistry _modeRegistry;

  @override
  Future<GenerationResult> executeWorkflow({
    required GenerationMode mode,
    required Map<String, dynamic> variables,
    required String outputDirectory,
    bool dryRun = false,
  }) async {
    // Ensure generation_mode is aligned with the requested mode so that
    // the composer and workflow inference see a consistent view.
    final rawVars = <String, dynamic>{
      ...variables,
      'generation_mode': mode.key,
    };

    // 1. Get brick for variable processing and validation
    // Use mode registry to get brick ID from profile (single source of truth)
    final brickId = _getBrickIdFromMode(mode);
    final brick = await _templateManager.getBrick(brickId);
    if (brick == null) {
      final errorData = {'brick_id': brickId, 'mode': mode.key};
      return GenerationResult.failure(
        error: 'Brick "$brickId" not found for mode ${mode.key}',
        errorType: GenerationErrorMapper.fromData(errorData),
        data: errorData,
      );
    }

    // 2. Get the appropriate processor for the mode and process variables
    final processor = _variableProcessorFactory.getProcessor(mode);
    final processed = await processor.process(
      rawVars: rawVars,
      mode: mode,
      brick: brick,
    );

    // 3. Validate variables - fail early if validation fails
    if (!processed.validationResult.isValid) {
      final errorData = {
        'validation_errors': processed.validationResult.errors,
        'brick_id': brickId,
        'mode': mode.key,
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

  /// Maps a [GenerationMode] to its corresponding brick ID.
  ///
  /// Returns the brick ID that should be used for variable processing
  /// and validation for the given generation mode.
  ///
  /// Uses the mode registry to get the brick ID from the mode profile,
  /// ensuring consistency with the single source of truth.
  ///
  /// Throws [StateError] if the mode is not registered or has no brick ID.
  String _getBrickIdFromMode(GenerationMode mode) {
    final brickId = _modeRegistry.getBrickId(mode);
    if (brickId == null) {
      throw StateError(
        'No brick ID found for generation mode: ${mode.key}. '
        'Mode must be registered with a profile containing a brick ID.',
      );
    }
    return brickId.key;
  }
}
