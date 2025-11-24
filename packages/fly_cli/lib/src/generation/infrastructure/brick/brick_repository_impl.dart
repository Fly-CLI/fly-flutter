import 'package:fly_cli/src/generation/brick/brick_metadata.dart';
import 'package:fly_cli/src/generation/brick/brick_registry.dart';
import 'package:fly_cli/src/generation/domain/entities/brick.dart';
import 'package:fly_cli/src/generation/domain/repositories/ibrick_repository.dart';
import 'package:mason_logger/mason_logger.dart';

/// Implementation of IBrickRepository using BrickRegistry.
///
/// This is a direct implementation that uses BrickRegistry,
/// which now returns Brick entities directly.
class BrickRepositoryImpl implements IBrickRepository {
  BrickRepositoryImpl({
    required BrickRegistry brickRegistry,
  }) : _brickRegistry = brickRegistry;

  final BrickRegistry _brickRegistry;

  @override
  Future<Brick?> getBrick(String name) async {
    return await _brickRegistry.getBrick(name);
  }

  @override
  Future<List<Brick>> discoverBricks({bool forceRefresh = false}) async {
    return await _brickRegistry.discoverBricks(forceRefresh: forceRefresh);
  }

  @override
  Future<bool> brickExists(String name) async {
    final brick = await getBrick(name);
    return brick != null;
  }

  @override
  Future<BrickValidationResult> validateBrick(Brick brick) async {
    return await _brickRegistry.validateBrick(brick);
  }

  @override
  Future<List<Brick>> getBricksByType(BrickType type) async {
    return await _brickRegistry.getBricksByType(type);
  }

  @override
  Future<void> clearCache() async {
    _brickRegistry.clearCache();
  }
}

