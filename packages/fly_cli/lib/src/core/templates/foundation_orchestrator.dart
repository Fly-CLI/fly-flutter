import 'dart:io';

import 'package:mason/mason.dart' hide Logger, GeneratedFile;
import 'package:fly_foundation_planning/fly_foundation_planning.dart';
import 'package:path/path.dart' as path;

import 'template_manager.dart';
import 'brick_info.dart';
import 'package:mason_logger/mason_logger.dart';

/// Orchestrator for Fly foundation generation using multi-brick approach.
///
/// This orchestrator:
/// 1. Uses the planning library to determine which bricks to run
/// 2. Executes each brick with the appropriate variables and target directories
/// 3. Supports phase-based ordering and prepares for optional parallel execution
class FoundationOrchestrator {
  final TemplateManager _templateManager;
  final Logger _logger;
  final FoundationPlanner _planner;

  FoundationOrchestrator({
    required TemplateManager templateManager,
    required Logger logger,
    FoundationPlanner? planner,
  })  : _templateManager = templateManager,
        _logger = logger,
        _planner = planner ?? FoundationPlanner(
          logger: _MasonLoggerAdapter(logger),
        );

  /// Plans and executes foundation generation using bricks.
  ///
  /// Returns a result indicating success or failure with details.
  Future<FoundationGenerationResult> generateFoundation({
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
      final allGeneratedFiles = <GeneratedFile>[];
      var totalFiles = 0;

      final sortedPhases = invocationsByPhase.keys.toList()..sort();
      for (final phase in sortedPhases) {
        final phaseInvocations = invocationsByPhase[phase]!;
        _logger.info('Executing phase $phase (${phaseInvocations.length} invocation(s))');

        // Execute invocations in this phase sequentially
        // TODO: In the future, these could be executed in parallel if safe
        for (final invocation in phaseInvocations) {
          _logger.info('Generating: ${invocation.displayName}');

          // Get brick info
          final brick = await _templateManager.getBrick(invocation.brickId);
          if (brick == null) {
            return FoundationGenerationResult.failure(
              'Brick "${invocation.brickId}" not found. '
              'Make sure the bricks are available.',
            );
          }

          // Resolve target directory
          final targetDir = _resolveTargetDirectory(
            outputDirectory,
            invocation.targetDir,
          );

          // Generate using the brick
          final result = await _generateBrick(
            brick: brick,
            vars: invocation.vars,
            targetDirectory: targetDir,
          );

          if (!result.success) {
            return FoundationGenerationResult.failure(
              'Failed to generate ${invocation.displayName}: ${result.error}',
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

      return FoundationGenerationResult.success(
        files: allGeneratedFiles,
        targetDirectory: outputDirectory,
      );
    } catch (e, stackTrace) {
      _logger.err('Foundation generation failed: $e');
      _logger.warn('Stack trace: $stackTrace');
      return FoundationGenerationResult.failure('Generation failed: $e');
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

  /// Generates a single brick using its definition.
  Future<_ModuleGenerationResult> _generateBrick({
    required BrickInfo brick,
    required Map<String, dynamic> vars,
    required String targetDirectory,
  }) async {
    try {
      // Create Brick instance from brick directory
      final brickInstance = Brick.path(brick.path);

      // Create MasonGenerator from brick
      final generator = await MasonGenerator.fromBrick(brickInstance);

      // Create target directory
      final targetDir = Directory(targetDirectory);
      await targetDir.create(recursive: true);

      // Create DirectoryGeneratorTarget
      final target = DirectoryGeneratorTarget(targetDir);

      // Generate files (returns Mason's GeneratedFile list)
      // Note: Mason's generate method expects a specific Logger type, but we use
      // the CLI's Logger. Passing null and letting Mason use its default logger.
      final masonFiles = await generator.generate(
        target,
        vars: vars,
        fileConflictResolution: FileConflictResolution.overwrite,
      );

      // Convert Mason's GeneratedFile to CLI's GeneratedFile
      final cliFiles = masonFiles
          .map((masonFile) => GeneratedFile(masonFile.path))
          .toList();

      return _ModuleGenerationResult.success(files: cliFiles);
    } catch (e) {
      return _ModuleGenerationResult.failure(error: e.toString());
    }
  }
}

/// Result of foundation generation.
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

/// Internal result for module generation.
class _ModuleGenerationResult {
  const _ModuleGenerationResult._({
    required this.success,
    this.files,
    this.error,
  });

  factory _ModuleGenerationResult.success({required List<GeneratedFile> files}) {
    return _ModuleGenerationResult._(success: true, files: files);
  }

  factory _ModuleGenerationResult.failure({required String error}) {
    return _ModuleGenerationResult._(success: false, error: error);
  }

  final bool success;
  final List<GeneratedFile>? files;
  final String? error;
}

/// Adapter to convert CLI Logger to PlanningLogger.
class _MasonLoggerAdapter implements PlanningLogger {
  final Logger _logger;

  _MasonLoggerAdapter(this._logger);

  @override
  void info(String message) => _logger.info(message);

  @override
  void warn(String message) => _logger.warn(message);

  @override
  void err(String message) => _logger.err(message);

  @override
  void detail(String message) => _logger.warn(message);
}

