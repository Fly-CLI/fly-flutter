import 'dart:io';

import 'package:fly_brick_composer/src/orchestration/brick_executor.dart';
import 'package:fly_cli/src/generation/template/template_manager.dart';
import 'package:mason/mason.dart' as mason show Brick;
import 'package:mason/mason.dart' hide Logger;

/// CLI implementation of [BrickExecutor] that uses [TemplateManager] and Mason.
///
/// This executor handles the concrete implementation of brick execution
/// in the CLI context, using Mason for actual file generation.
class TemplateManagerBrickExecutor implements BrickExecutor<GeneratedFile> {
  final TemplateManager _templateManager;

  /// Creates an executor that uses the given [TemplateManager] to find and execute bricks.
  TemplateManagerBrickExecutor({
    required TemplateManager templateManager,
  }) : _templateManager = templateManager;

  @override
  Future<BrickExecutionResult<GeneratedFile>> executeBrick({
    required String brickId,
    required Map<String, dynamic> vars,
    required String targetDirectory,
    bool dryRun = false,
  }) async {
    try {
      // Get brick info from template manager
      final brick = await _templateManager.getBrick(brickId);
      if (brick == null) {
        return BrickExecutionResult<GeneratedFile>.failure(
          error:
              'Brick "$brickId" not found. '
              'Make sure the bricks are available.',
        );
      }

      // Create Brick instance from brick directory
      final brickInstance = mason.Brick.path(brick.path);

      // Create MasonGenerator from brick
      final generator = await MasonGenerator.fromBrick(brickInstance);

      // When running in dry-run mode, we must not write any files to disk.
      // We rely on the BrickComposer planning phase for structure; here we
      // simply short-circuit execution and report an empty file list while
      // marking the result as dry-run.
      if (dryRun) {
        return BrickExecutionResult<GeneratedFile>.success(
          files: const [],
          dryRun: true,
        );
      }

      // Normal mode: create target directory on disk and generate files.
      final targetDir = Directory(targetDirectory);
      await targetDir.create(recursive: true);

      // Create DirectoryGeneratorTarget
      final target = DirectoryGeneratorTarget(targetDir);

      // Generate files (returns Mason's GeneratedFile list)
      final files = await generator.generate(
        target,
        vars: vars,
        fileConflictResolution: FileConflictResolution.overwrite,
      );

      return BrickExecutionResult<GeneratedFile>.success(files: files);
    } catch (e, stackTrace) {
      return BrickExecutionResult<GeneratedFile>.failure(
        error: e.toString(),
      );
    }
  }
}
