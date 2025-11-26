import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/generation/application/ports/iworkflow_orchestrator.dart';
import 'package:fly_cli/src/generation/foundation/foundation_orchestrator.dart';
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
  WorkflowOrchestratorImpl({
    required TemplateManager templateManager,
    required Logger logger,
  }) : _templateManager = templateManager,
       _logger = logger;

  final TemplateManager _templateManager;
  final Logger _logger;

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

    // Delegate to the foundation TemplateGenerationOrchestrator which
    // encapsulates BrickComposer- and BrickOrchestrator-based workflows
    // and fully respects the dryRun flag for all modes.
    final orchestrator = TemplateGenerationOrchestrator(
      templateManager: _templateManager,
      logger: _logger,
    );

    return orchestrator.generate(
      rawVars: rawVars,
      outputDirectory: outputDirectory,
      dryRun: dryRun,
    );
  }
}
