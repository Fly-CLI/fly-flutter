import 'dart:io';

import 'package:mason/mason.dart' hide Logger;
import 'package:fly_brick_composer/src/orchestration/brick_executor.dart';
import 'package:fly_cli/src/core/templates/brick/brick_info.dart';
import 'package:fly_cli/src/core/templates/template/template_manager.dart';

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
  }) async {
    try {
      // Get brick info from template manager
      final brick = await _templateManager.getBrick(brickId);
      if (brick == null) {
        return BrickExecutionResult<GeneratedFile>.failure(
          error: 'Brick "$brickId" not found. '
              'Make sure the bricks are available.',
        );
      }

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
      final files = await generator.generate(
        target,
        vars: vars,
        fileConflictResolution: FileConflictResolution.overwrite,
      );

      return BrickExecutionResult<GeneratedFile>.success(files: files);
    } catch (e) {
      return BrickExecutionResult<GeneratedFile>.failure(
        error: e.toString(),
      );
    }
  }
}

