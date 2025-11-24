import 'dart:io';

import 'package:fly_cli/src/generation/brick/brick_metadata.dart';
import 'package:fly_cli/src/generation/brick/brick_registry.dart';
import 'package:fly_cli/src/generation/domain/entities/brick.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Responsible ONLY for finding and loading brick metadata
///
/// This service is decoupled from path resolution, validation, and generation.
/// It focuses solely on discovering bricks and loading their metadata.
class BrickDiscoveryService {
  BrickDiscoveryService({
    required this.logger,
    BrickRegistry? brickRegistry,
  })  : _brickRegistry = brickRegistry ?? BrickRegistry(logger: logger);

  final Logger logger;
  final BrickRegistry _brickRegistry;

  /// Discover bricks in a specific category directory
  Future<List<Brick>> _discoverBricksInCategory(
    String categoryPath,
    String category,
  ) async {
    final bricks = <Brick>[];

    try {
      await for (final entity in Directory(categoryPath).list()) {
        if (entity is Directory) {
          final brick = await loadBrickMetadata(entity.path);
          if (brick != null) {
            // Validate category consistency
            if (brick.category.name == category) {
              bricks.add(brick);
            } else {
              logger.warn(
                  'Brick ${brick.name} has category ${brick.category.name} '
                  'but is located in $category directory');
            }
          }
        }
      }
    } catch (e) {
      logger.warn('Error discovering bricks in $categoryPath: $e');
    }

    return bricks;
  }

  /// Load brick metadata from a directory
  ///
  /// Looks for brick.yaml or template.yaml in the brick directory
  /// Returns a Brick entity directly
  Future<Brick?> loadBrickMetadata(String brickPath) async {
    try {
      // Check for brick.yaml first, then template.yaml
      final brickYamlFile = File(path.join(brickPath, 'brick.yaml'));
      final templateYamlFile = File(path.join(brickPath, 'template.yaml'));

      File? yamlFile;
      if (await brickYamlFile.exists()) {
        yamlFile = brickYamlFile;
      } else if (await templateYamlFile.exists()) {
        yamlFile = templateYamlFile;
      } else {
        logger.detail('No brick.yaml or template.yaml found in: $brickPath');
        return null;
      }

      // Check if __brick__ directory exists
      final brickContentDir = Directory(path.join(brickPath, '__brick__'));
      if (!await brickContentDir.exists()) {
        logger.warn('Brick content directory missing: ${brickContentDir.path}');
        return null;
      }

      // Check for separate fly_metadata.yaml file for type (Mason doesn't allow custom keys in brick.yaml)
      final flyMetadataFile = File(path.join(brickPath, 'fly_metadata.yaml'));
      Map<dynamic, dynamic>? flyMetadata;
      if (await flyMetadataFile.exists()) {
        try {
          final metadataContent = await flyMetadataFile.readAsString();
          flyMetadata = loadYaml(metadataContent) as Map<dynamic, dynamic>?;
          logger.detail('Loaded fly_metadata.yaml for brick $brickPath: $flyMetadata');
        } catch (e) {
          logger.warn('Failed to parse fly_metadata.yaml for brick $brickPath: $e');
        }
      }

      // Parse YAML file
      final yamlContent = await yamlFile.readAsString();
      final yaml = loadYaml(yamlContent) as Map<dynamic, dynamic>;

      // Merge metadata into yaml if available (metadata takes precedence)
      final mergedYaml = Map<dynamic, dynamic>.from(yaml);
      if (flyMetadata != null) {
        mergedYaml.addAll(flyMetadata);
        logger.detail('Merged metadata into YAML for brick $brickPath. Type: ${mergedYaml['type']}');
      }

      // Create Brick directly from YAML
      final brick = Brick.fromYaml(mergedYaml, brickPath);

      if (!brick.isValid) {
        logger.warn(
            'Invalid brick for ${brick.name}: ${brick.validationErrors.join(', ')}');
      }

      return brick;
    } catch (e) {
      logger.warn('Error loading brick from $brickPath: $e');
      return null;
    }
  }

  /// Get brick by name and optional version
  ///
  /// [version] is currently ignored as BrickRegistry doesn't support version filtering yet.
  Future<Brick?> getBrick(String name, {String? version}) async {
    return await _brickRegistry.getBrick(name);
  }

  /// Get all bricks of a specific type
  Future<List<Brick>> getBricksByType(BrickType type) async {
    return await _brickRegistry.getBricksByType(type);
  }

  /// Get all bricks of a specific category
  Future<List<Brick>> getBricksByCategory(BrickCategory category) async {
    // Discover all bricks first
    final allBricks = await _brickRegistry.discoverBricks();
    return allBricks.where((brick) => brick.category == category).toList();
  }

  /// Check if a brick exists
  Future<bool> brickExists(String name) async {
    final brick = await _brickRegistry.getBrick(name);
    return brick != null;
  }

  /// Get all available brick names
  Future<List<String>> getAvailableBrickNames() async {
    final bricks = await _brickRegistry.discoverBricks();
    return bricks.map((brick) => brick.name).toList();
  }
}
