import 'package:mason/mason.dart' hide Logger, GeneratedFile;
import 'package:fly_foundation_planning/fly_foundation_planning.dart';
import 'package:mason_logger/mason_logger.dart';

import 'foundation_brick_executor.dart';
import 'foundation_planner_factory.dart';
import 'planning_logger_adapter.dart';
import 'template_manager.dart';
import 'workflows/foundation_workflow_inference.dart';

/// CLI wrapper for Fly foundation generation orchestration.
///
/// This is a thin wrapper that adapts CLI-specific types to the planning
/// library's generic orchestrator. The actual orchestration logic lives
/// in the `fly_foundation_planning` package.
class TemplateGenerationOrchestrator {
  final TemplateManager _templateManager;
  final Logger _logger;
  final FoundationPlanner? _planner;

  /// Creates a foundation orchestrator with CLI-specific dependencies.
  ///
  /// [templateManager] is used to find and execute bricks.
  /// [logger] is used for logging orchestration progress.
  /// [planner] is optional; if not provided, a default planner will be created.
  TemplateGenerationOrchestrator({
    required TemplateManager templateManager,
    required Logger logger,
    FoundationPlanner? planner,
  })  : _templateManager = templateManager,
        _logger = logger,
        _planner = planner;

  /// Plans and executes foundation generation using bricks.
  ///
  /// [rawVars] is the raw input variables from the user (e.g., from CLI flags).
  /// [outputDirectory] is the root directory where files should be generated.
  ///
  /// Returns a result indicating success or failure with details.
  Future<FoundationGenerationResult> generateFoundation({
    required Map<String, dynamic> rawVars,
    required String outputDirectory,
  }) async {
    // Create the adapter for planning logger
    final planningLogger = PlanningLoggerAdapter(_logger);

    // Create the executor that uses TemplateManager
    final executor = TemplateManagerBrickExecutor(
      templateManager: _templateManager,
    );

    // Create the planner if not provided using the foundation factory
    final planner = _planner ?? FoundationPlannerFactory.createPlanner(
      logger: planningLogger,
    );

    // Create the orchestrator from the planning package
    final orchestrator = FoundationOrchestrator<GeneratedFile>(
      executor: executor,
      logger: planningLogger,
      planner: planner,
    );

    // Infer workflow ID from raw vars
    final workflowId = FoundationWorkflowInference.inferFromVars(rawVars);

    // Execute orchestration
    final result = await orchestrator.generateFoundation(
      rawVars: rawVars,
      workflowId: workflowId,
      outputDirectory: outputDirectory,
    );

    // Adapt the result to CLI-specific type
    if (result.success) {
      return FoundationGenerationResult.success(
        files: result.files ?? [],
        targetDirectory: result.targetDirectory ?? outputDirectory,
      );
    } else {
      return FoundationGenerationResult.failure(
        result.error ?? 'Generation failed',
      );
    }
  }
}

/// Result of foundation generation (CLI-specific type).
///
/// This is kept for backward compatibility with existing CLI code.
class FoundationGenerationResult {
  const FoundationGenerationResult._({
    required this.success,
    this.files,
    this.targetDirectory,
    this.error,
  });

  factory FoundationGenerationResult.success({
    required List<GeneratedFile> files,
    required String targetDirectory,
  }) {
    return FoundationGenerationResult._(
      success: true,
      files: files,
      targetDirectory: targetDirectory,
    );
  }

  factory FoundationGenerationResult.failure(String error) {
    return FoundationGenerationResult._(
      success: false,
      error: error,
    );
  }

  final bool success;
  final List<GeneratedFile>? files;
  final String? targetDirectory;
  final String? error;
}

