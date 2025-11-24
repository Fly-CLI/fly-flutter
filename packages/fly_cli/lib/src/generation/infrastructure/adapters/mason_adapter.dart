import 'dart:io';

import 'package:mason/mason.dart';
import 'package:mason_logger/mason_logger.dart';

import 'package:fly_cli/src/generation/infrastructure/adapters/imason_adapter.dart';

/// Implementation of IMasonAdapter using Mason package.
class MasonAdapter implements IMasonAdapter {
  const MasonAdapter();

  @override
  Future<List<GeneratedFile>> generate({
    required Brick brick,
    required String target,
    required Map<String, dynamic> vars,
    Logger? logger,
  }) async {
    final generator = await MasonGenerator.fromBrick(brick);
    final targetDir = Directory(target);
    final target_ = DirectoryGeneratorTarget(targetDir);
    
    // Generate and return the list of generated files
    final files = await generator.generate(
      target_,
      vars: vars,
      fileConflictResolution: FileConflictResolution.overwrite,
    );
    
    return files;
  }

  @override
  Future<Brick> createBrick(String path) async {
    return Brick.path(path);
  }

  @override
  Future<bool> isValidBrickPath(String path) async {
    try {
      final brick = Brick.path(path);
      // Try to access brick to validate
      await brick.name;
      return true;
    } catch (_) {
      return false;
    }
  }
}

