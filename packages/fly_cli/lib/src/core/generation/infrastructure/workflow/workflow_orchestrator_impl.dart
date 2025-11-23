import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/core/generation/application/ports/iworkflow_orchestrator.dart';
import 'package:fly_cli/src/core/generation/foundation/foundation_orchestrator.dart';
import 'package:fly_cli/src/core/generation/generators/generation_result.dart';
import 'package:fly_cli/src/core/generation/template/template_manager.dart';
import 'package:fly_cli/src/core/generation/workflows/foundation_workflow_inference.dart';
import 'package:mason_logger/mason_logger.dart';

/// Implementation of IWorkflowOrchestrator using TemplateGenerationOrchestrator.
///
/// This adapter wraps the existing TemplateGenerationOrchestrator to implement
/// the new workflow orchestrator interface, maintaining backward compatibility.
class WorkflowOrchestratorImpl implements IWorkflowOrchestrator {
  WorkflowOrchestratorImpl({
    required TemplateManager templateManager,
    required Logger logger,
  })  : _templateManager = templateManager,
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
    final orchestrator = TemplateGenerationOrchestrator(
      templateManager: _templateManager,
      logger: _logger,
    );

    return orchestrator.generate(
      rawVars: variables,
      outputDirectory: outputDirectory,
    );
  }

  @override
  Future<WorkflowId> inferWorkflow(GenerationMode mode) async {
    // Create a minimal variable set for inference
    final vars = <String, dynamic>{
      'generation_mode': mode.name,
    };
    return FoundationWorkflowInference.inferFromVars(vars);
  }
}
