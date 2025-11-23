import 'package:mason/mason.dart' hide Logger;
import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:mason_logger/mason_logger.dart';

import 'package:fly_cli/src/core/scaffolding/foundation/foundation_brick_executor.dart';
import 'package:fly_cli/src/core/scaffolding/foundation/foundation_planner_factory.dart';
import 'package:fly_cli/src/core/scaffolding/generators/generation_result.dart';
import 'package:fly_cli/src/core/scaffolding/utils/planning_logger_adapter.dart';
import 'package:fly_cli/src/core/scaffolding/template/template_manager.dart';
import 'package:fly_cli/src/core/scaffolding/workflows/foundation_workflow_inference.dart';

/// CLI wrapper for Fly foundation generation orchestration.
///
/// This is a thin wrapper that adapts CLI-specific types to the composer
/// library's generic orchestrator. The actual orchestration logic lives
/// in the `fly_brick_composer` package.
class TemplateGenerationOrchestrator {
  final TemplateManager _templateManager;
  final Logger _logger;
  final BrickComposer? _composer;

  /// Creates a foundation orchestrator with CLI-specific dependencies.
  ///
  /// [templateManager] is used to find and execute bricks.
  /// [logger] is used for logging orchestration progress.
  /// [composer] is optional; if not provided, a default composer will be created.
  TemplateGenerationOrchestrator({
    required TemplateManager templateManager,
    required Logger logger,
    BrickComposer? composer,
  })  : _templateManager = templateManager,
        _logger = logger,
        _composer = composer;

  /// Plans and executes foundation generation using bricks.
  ///
  /// [rawVars] is the raw input variables from the user (e.g., from CLI flags).
  /// [outputDirectory] is the root directory where files should be generated.
  ///
  /// Returns a result indicating success or failure with details.
  Future<GenerationResult> generate({
    required Map<String, dynamic> rawVars,
    required String outputDirectory,
  }) async {
    // Create the adapter for composer logger
    final composerLogger = ComposerLoggerAdapter(_logger);

    // Create the executor that uses TemplateManager
    final executor = TemplateManagerBrickExecutor(
      templateManager: _templateManager,
    );

    // Create the composer if not provided using the foundation factory
    final composer = _composer ?? BrickComposerFactory.createComposer(
      logger: composerLogger,
    );

    // Create the orchestrator from the composer package
    final orchestrator = BrickOrchestrator<GeneratedFile>(
      executor: executor,
      logger: composerLogger,
      composer: composer,
    );

    // Infer workflow ID from raw vars
    final workflowId = FoundationWorkflowInference.inferFromVars(rawVars);

    // Execute orchestration
    final result = await orchestrator.generate(
      rawVars: rawVars,
      workflowId: workflowId,
      outputDirectory: outputDirectory,
    );

    // Convert to unified GenerationResult
    if (result.success) {
      return GenerationResult.success(
        files: result.files ?? [],
        targetDirectory: result.targetDirectory ?? outputDirectory,
      );
    } else {
      return GenerationResult.failure(
        error: result.error ?? 'Generation failed',
        data: {'workflow_id': workflowId},
      );
    }
  }
}


