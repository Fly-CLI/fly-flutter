import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/generation/application/ports/igeneration_engine.dart';
import 'package:fly_cli/src/generation/application/ports/ivariable_processor.dart';
import 'package:fly_cli/src/generation/application/ports/iworkflow_orchestrator.dart';
import 'package:fly_cli/src/generation/domain/repositories/ibrick_repository.dart';
import 'package:fly_cli/src/generation/foundation/foundation_orchestrator.dart';
import 'package:fly_cli/src/generation/generators/generation_result.dart';
import 'package:fly_cli/src/generation/template/template_manager.dart';
import 'package:fly_cli/src/generation/variables/validation/variable_validation_service.dart';
import 'package:mason_logger/mason_logger.dart';

/// Implementation of IWorkflowOrchestrator using TemplateGenerationOrchestrator.
///
/// This adapter wraps the existing TemplateGenerationOrchestrator to implement
/// the new workflow orchestrator interface, maintaining backward compatibility.
class WorkflowOrchestratorImpl implements IWorkflowOrchestrator {
  /// Creates a new [WorkflowOrchestratorImpl] instance.
  WorkflowOrchestratorImpl({
    required TemplateManager templateManager,
    required IBrickRepository brickRepository,
    required IVariableProcessor variableProcessor,
    required IGenerationEngine generationEngine,
    required Logger logger,
  }) : _templateManager = templateManager,
       _brickRepository = brickRepository,
       _variableProcessor = variableProcessor,
       _generationEngine = generationEngine,
       _logger = logger;

  final TemplateManager _templateManager;
  final IBrickRepository _brickRepository;
  final IVariableProcessor _variableProcessor;
  final IGenerationEngine _generationEngine;
  final Logger _logger;

  @override
  Future<GenerationResult> executeWorkflow({
    required GenerationMode mode,
    required Map<String, dynamic> variables,
    required String outputDirectory,
    bool dryRun = false,
  }) async {
    switch (mode) {
      case GenerationMode.project:
        // Preserve existing complex multi-step project workflow
        final orchestrator = TemplateGenerationOrchestrator(
          templateManager: _templateManager,
          logger: _logger,
        );

        // TemplateGenerationOrchestrator already encapsulates variable
        // processing and validation for project workflows.
        return orchestrator.generate(
          rawVars: variables,
          outputDirectory: outputDirectory,
        );

      case GenerationMode.feature:
      case GenerationMode.service:
        // Simple single-brick workflows reused from the original feature/service
        // use cases: brick discovery → variable processing → validation →
        // generation via IGenerationEngine.
        return _executeSingleBrickWorkflow(
          mode: mode,
          variables: variables,
          outputDirectory: outputDirectory,
          dryRun: dryRun,
        );
    }
  }

  Future<GenerationResult> _executeSingleBrickWorkflow({
    required GenerationMode mode,
    required Map<String, dynamic> variables,
    required String outputDirectory,
    required bool dryRun,
  }) async {
    // Resolve brick name by mode
    final brickName = switch (mode) {
      GenerationMode.feature => 'feature',
      GenerationMode.service => 'service',
      // Project mode is handled separately above and should never reach here.
      GenerationMode.project => throw ArgumentError(
        'Project mode is not supported by _executeSingleBrickWorkflow',
      ),
    };

    // 1. Get brick
    final brick = await _brickRepository.getBrick(brickName);
    if (brick == null) {
      return GenerationResult.failure(
        error: 'Brick "$brickName" not found',
        data: {'brick_name': brickName},
      );
    }

    // 2. Process variables
    final processed = await _variableProcessor.process(
      rawVars: variables,
      mode: mode,
      brick: brick,
    );

    // 3. Validate variables (in addition to pipeline-level validation)
    if (!processed.validationResult.isValid) {
      return GenerationResult.failure(
        error:
            'Variable validation failed: ${processed.validationResult.errors.join(', ')}',
        data: {
          'validation_errors': processed.validationResult.errors,
          'brick_name': brickName,
        },
      );
    }

    // Extra schema-based validation to mirror documented behavior
    final schemaErrors = VariableValidationService.validateAll(
      brick: brick,
      mode: mode,
      variables: processed.values,
    );
    if (schemaErrors.isNotEmpty) {
      return GenerationResult.failure(
        error: 'Variable schema validation failed: ${schemaErrors.join(', ')}',
        data: {
          'validation_errors': schemaErrors,
          'brick_name': brickName,
        },
      );
    }

    // 4. Generate using the configured engine
    return _generationEngine.generate(
      brick: brick,
      variables: processed.values,
      outputDirectory: outputDirectory,
      dryRun: dryRun,
    );
  }
}
