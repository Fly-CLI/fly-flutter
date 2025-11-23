import 'package:fly_cli/src/core/generation/application/ports/igeneration_engine.dart';
import 'package:fly_cli/src/core/generation/domain/entities/brick.dart' as domain;
import 'package:fly_cli/src/core/generation/generation/generation_preview.dart';
import 'package:fly_cli/src/core/generation/generators/generation_result.dart';
import 'package:fly_cli/src/core/generation/infrastructure/adapters/imason_adapter.dart';
import 'package:mason/mason.dart' as mason;
import 'package:mason_logger/mason_logger.dart';

/// Implementation of IGenerationEngine using Mason.
class MasonGenerationEngine implements IGenerationEngine {
  MasonGenerationEngine({
    required IMasonAdapter masonAdapter,
    Logger? logger,
  })  : _masonAdapter = masonAdapter,
        _logger = logger;

  final IMasonAdapter _masonAdapter;
  final Logger? _logger;

  @override
  Future<GenerationResult> generate({
    required domain.Brick brick,
    required Map<String, dynamic> variables,
    required String outputDirectory,
    bool dryRun = false,
  }) async {
    try {
      if (dryRun) {
        return await preview(
          brick: brick,
          variables: variables,
          outputDirectory: outputDirectory,
        );
      }

      // Create brick instance
      final masonBrick = await _masonAdapter.createBrick(brick.path);

      // Generate using adapter
      final files = await _masonAdapter.generate(
        brick: masonBrick,
        target: outputDirectory,
        vars: variables,
        logger: _logger,
      );

      return GenerationResult.success(
        files: files,
        targetDirectory: outputDirectory,
      );
    } catch (e) {
      return GenerationResult.failure(
        error: 'Generation failed: $e',
        data: {'brick_name': brick.name},
      );
    }
  }

  @override
  Future<GenerationResult> preview({
    required domain.Brick brick,
    required Map<String, dynamic> variables,
    required String outputDirectory,
  }) async {
    try {
      // Create a preview
      final preview = GenerationPreview(
        brickName: brick.name,
        brickType: brick.type,
        targetDirectory: outputDirectory,
        variables: variables,
        filesToGenerate: [],
        directoriesToCreate: [],
        estimatedDuration: const Duration(milliseconds: 100),
        warnings: [],
      );

      return GenerationResult.dryRun(
        preview: preview,
      );
    } catch (e) {
      return GenerationResult.failure(
        error: 'Preview generation failed: $e',
        data: {'brick_name': brick.name},
      );
    }
  }
}

