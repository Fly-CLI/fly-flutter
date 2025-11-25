import 'package:fly_cli/src/generation/brick/brick_metadata.dart';
import 'package:fly_cli/src/generation/domain/entities/brick.dart';

/// Repository interface for brick discovery and access.
///
/// Provides abstraction over brick storage and retrieval, allowing
/// different implementations (local file system, remote registry, etc.).
abstract class IBrickRepository {
  /// Get a brick by name.
  ///
  /// Returns the brick if found, null otherwise.
  Future<Brick?> getBrick(String name);

  /// Discover all available bricks.
  ///
  /// [forceRefresh] if true, bypasses cache and re-discovers bricks.
  Future<List<Brick>> discoverBricks({bool forceRefresh = false});

  /// Check if a brick exists.
  Future<bool> brickExists(String name);

  /// Validate a brick.
  ///
  /// Returns validation result with errors and warnings.
  Future<BrickValidationResult> validateBrick(Brick brick);

  /// Get all bricks of a specific type.
  Future<List<Brick>> getBricksByType(BrickType type);

  /// Clear the brick cache.
  Future<void> clearCache();
}
