import 'package:path/path.dart' as path;

import 'package:fly_foundation_planning/src/foundation_planner.dart';
import 'package:fly_foundation_planning/src/logger.dart';
import 'package:fly_foundation_planning/src/module_invocation.dart';
import 'package:fly_foundation_planning/src/orchestration/brick_executor.dart';
import 'package:fly_foundation_planning/src/orchestration/orchestration_result.dart';

/// Orchestrator for Fly foundation generation using multi-brick approach.
///
/// This orchestrator:
/// 1. Uses the planning library to determine which bricks to run
/// 2. Executes each brick with the appropriate variables and target directories
/// 3. Supports phase-based ordering and prepares for optional parallel execution
///
/// The type parameter `TFile` allows different hosts (CLI, tests, etc.) to use
/// their own file representations.
class FoundationOrchestrator<TFile> {
  final BrickExecutor<TFile> _executor;
  final PlanningLogger _logger;
  final FoundationPlanner _planner;

  /// Creates a foundation orchestrator with the given dependencies.
  ///
  /// [executor] is responsible for actually executing brick generation.
  /// [logger] is used for logging orchestration progress.
  /// [planner] is used to plan the brick invocations from raw input.
  FoundationOrchestrator({
    required BrickExecutor<TFile> executor,
    required PlanningLogger logger,
    FoundationPlanner? planner,
  })  : _executor = executor,
        _logger = logger,
        _planner = planner ??
            FoundationPlanner.withDefaultPipeline(
              logger: logger,
            );

  /// Plans and executes foundation generation using bricks.
  ///
  /// [rawVars] is the raw input variables from the user (e.g., from CLI flags).
  /// [outputDirectory] is the root directory where files should be generated.
  ///
  /// Returns a result indicating success or failure with details.
  Future<OrchestrationResult<TFile>> generateFoundation({
    required Map<String, dynamic> rawVars,
    required String outputDirectory,
  }) async {
    try {
      _logger.info('Planning foundation generation...');

      // Step 1: Plan generation using the planning library
      final planningResult = _planner.planFoundationGeneration(rawVars);

      // Use brickInvocations (new model) if available, fall back to moduleInvocations
      final invocations = planningResult.brickInvocations.isNotEmpty
          ? planningResult.brickInvocations
          : planningResult.moduleInvocations
              .map((inv) => inv.toBrickInvocation())
              .toList();

      _logger.info(
        'Planned ${invocations.length} brick invocation(s) to generate',
      );

      // Step 2: Group invocations by phase for potential parallel execution
      final invocationsByPhase = <int, List<BrickInvocation>>{};
      for (final invocation in invocations) {
        invocationsByPhase.putIfAbsent(invocation.phase, () => []).add(invocation);
      }

      // Step 3: Execute invocations phase by phase (sequentially for now)
      final allGeneratedFiles = <TFile>[];
      var totalFiles = 0;

      final sortedPhases = invocationsByPhase.keys.toList()..sort();
      for (final phase in sortedPhases) {
        final phaseInvocations = invocationsByPhase[phase]!;
        _logger.info('Executing phase $phase (${phaseInvocations.length} invocation(s))');

        // Execute invocations in this phase sequentially
        // TODO: In the future, these could be executed in parallel if safe
        for (final invocation in phaseInvocations) {
          _logger.info('Generating: ${invocation.displayName}');

          // Resolve target directory
          final targetDir = _resolveTargetDirectory(
            outputDirectory,
            invocation.targetDir,
          );

          // Execute the brick using the executor
          final result = await _executor.executeBrick(
            brickId: invocation.brickId,
            vars: invocation.vars,
            targetDirectory: targetDir,
          );

          if (!result.success) {
            return OrchestrationResult<TFile>.failure(
              error: 'Failed to generate ${invocation.displayName}: ${result.error}',
            );
          }

          if (result.files != null) {
            allGeneratedFiles.addAll(result.files!);
            totalFiles += result.files!.length;
            _logger.info(
              '✓ ${invocation.displayName} generated (${result.files!.length} files)',
            );
          }
        }
      }

      _logger.info('✓ Foundation generation complete ($totalFiles total files)');

      return OrchestrationResult<TFile>.success(
        files: allGeneratedFiles,
        targetDirectory: outputDirectory,
      );
    } catch (e, stackTrace) {
      _logger.err('Foundation generation failed: $e');
      _logger.warn('Stack trace: $stackTrace');
      return OrchestrationResult<TFile>.failure(
        error: 'Generation failed: $e',
      );
    }
  }

  /// Resolves the target directory for a brick invocation.
  ///
  /// If the invocation has a targetDir, it's combined with the root output directory.
  /// Otherwise, the root output directory is used.
  String _resolveTargetDirectory(String rootOutputDir, String? invocationTargetDir) {
    if (invocationTargetDir == null || invocationTargetDir.isEmpty) {
      return rootOutputDir;
    }
    return path.join(rootOutputDir, invocationTargetDir);
  }
}

