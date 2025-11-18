import 'dart:io';

import 'package:mason/mason.dart';
import 'package:fly_foundation_planning/fly_foundation_planning.dart';

import '../logging/logger.dart';
import 'template_manager.dart';
import 'brick_info.dart';

/// Orchestrator for Fly foundation generation using multi-brick approach.
///
/// This orchestrator:
/// 1. Uses the planning library to determine which module bricks to run
/// 2. Executes each brick with the appropriate variables
/// 3. Eliminates the need for post-generation file cleanup
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

  /// Plans and executes foundation generation using module bricks.
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

      _logger.info(
        'Planned ${planningResult.moduleInvocations.length} module(s) to generate',
      );

      // Step 2: Execute each module brick
      final allGeneratedFiles = <GeneratedFile>[];
      var totalFiles = 0;

      for (final invocation in planningResult.moduleInvocations) {
        _logger.info('Generating module: ${invocation.moduleName}');

        // Get brick info
        final brick = await _templateManager.getBrick(invocation.brickId);
        if (brick == null) {
          return FoundationGenerationResult.failure(
            'Brick "${invocation.brickId}" not found. '
            'Make sure the module bricks are available.',
          );
        }

        // Generate using the brick
        final result = await _generateModule(
          brick: brick,
          vars: invocation.vars,
          outputDirectory: outputDirectory,
        );

        if (!result.success) {
          return FoundationGenerationResult.failure(
            'Failed to generate module ${invocation.moduleName}: ${result.error}',
          );
        }

        allGeneratedFiles.addAll(result.files);
        totalFiles += result.files.length;

        _logger.info(
          '✓ Module "${invocation.moduleName}" generated (${result.files.length} files)',
        );
      }

      _logger.info('✓ Foundation generation complete ($totalFiles total files)');

      return FoundationGenerationResult.success(
        files: allGeneratedFiles,
        targetDirectory: outputDirectory,
      );
    } catch (e, stackTrace) {
      _logger.err('Foundation generation failed: $e');
      _logger.detail('Stack trace: $stackTrace');
      return FoundationGenerationResult.failure('Generation failed: $e');
    }
  }

  /// Generates a single module using its brick.
  Future<_ModuleGenerationResult> _generateModule({
    required BrickInfo brick,
    required Map<String, dynamic> vars,
    required String outputDirectory,
  }) async {
    try {
      // Create Brick instance from brick directory
      final brickInstance = Brick.path(brick.path);

      // Create MasonGenerator from brick
      final generator = await MasonGenerator.fromBrick(brickInstance);

      // Create target directory
      final targetDir = Directory(outputDirectory);
      await targetDir.create(recursive: true);

      // Create DirectoryGeneratorTarget
      final target = DirectoryGeneratorTarget(targetDir);

      // Generate files
      final files = await generator.generate(
        target,
        vars: vars,
        logger: _logger,
        fileConflictResolution: FileConflictResolution.overwrite,
      );

      return _ModuleGenerationResult.success(files: files);
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
  void detail(String message) => _logger.detail(message);
}

