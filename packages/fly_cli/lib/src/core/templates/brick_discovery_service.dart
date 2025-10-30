import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:fly_cli/src/core/templates/models/brick_metadata.dart';

/// Responsible ONLY for finding and loading brick metadata
/// 
/// This service is decoupled from path resolution, validation, and generation.
/// It focuses solely on discovering bricks and loading their metadata.
class BrickDiscoveryService {
  BrickDiscoveryService({
    required this.logger,
  });

  final Logger logger;

  /// Discover all available bricks in the templates directory
  /// 
  /// Searches in the standardized directory structure:
  /// - templates/projects/
  /// - templates/components/
  /// - templates/addons/
  Future<List<BrickMetadata>> discoverBricks(String templatesPath) async {
    logger.info('Discovering bricks in: $templatesPath');
    final bricks = <BrickMetadata>[];

    try {
      final templatesDir = Directory(templatesPath);
      if (!await templatesDir.exists()) {
        logger.warn('Templates directory does not exist: $templatesPath');
        return bricks;
      }

      // Search in each category directory
      final categories = ['projects', 'components', 'addons'];
      for (final category in categories) {
        final categoryPath = path.join(templatesPath, category);
        final categoryDir = Directory(categoryPath);
        
        if (await categoryDir.exists()) {
          final categoryBricks = await _discoverBricksInCategory(categoryPath, category);
          bricks.addAll(categoryBricks);
        } else {
          logger.detail('Category directory does not exist: $categoryPath');
        }
      }

      logger.info('Discovered ${bricks.length} bricks');
      return bricks;
    } catch (e) {
      logger.err('Error discovering bricks: $e');
      return bricks;
    }
  }

  /// Discover bricks in a specific category directory
  Future<List<BrickMetadata>> _discoverBricksInCategory(
    String categoryPath,
    String category,
  ) async {
    final bricks = <BrickMetadata>[];
    
    try {
      await for (final entity in Directory(categoryPath).list()) {
        if (entity is Directory) {
          final brickMetadata = await loadBrickMetadata(entity.path);
          if (brickMetadata != null) {
            // Validate category consistency
            if (brickMetadata.category.name == category) {
              bricks.add(brickMetadata);
            } else {
              logger.warn(
                'Brick ${brickMetadata.name} has category ${brickMetadata.category.name} '
                'but is located in $category directory'
              );
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
  Future<BrickMetadata?> loadBrickMetadata(String brickPath) async {
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

      // Parse YAML file
      final yamlContent = await yamlFile.readAsString();
      final yaml = loadYaml(yamlContent) as Map<dynamic, dynamic>;

      // Create metadata from YAML
      final metadata = BrickMetadata.fromYaml(yaml, brickPath);
      
      if (!metadata.isValid) {
        logger.warn('Invalid brick metadata for ${metadata.name}: ${metadata.validationErrors.join(', ')}');
      }

      return metadata;
    } catch (e) {
      logger.warn('Error loading brick metadata from $brickPath: $e');
      return null;
    }
  }

  /// Get brick by name and optional version
  Future<BrickMetadata?> getBrick(String name, {String? version}) async {
    // This would typically use a cached registry
    // For now, we'll implement a simple search
    throw UnimplementedError('getBrick will be implemented with BrickRegistry');
  }

  /// Get all bricks of a specific type
  Future<List<BrickMetadata>> getBricksByType(BrickType type) async {
    // This would typically use a cached registry
    // For now, we'll implement a simple search
    throw UnimplementedError('getBricksByType will be implemented with BrickRegistry');
  }

  /// Get all bricks of a specific category
  Future<List<BrickMetadata>> getBricksByCategory(BrickCategory category) async {
    // This would typically use a cached registry
    // For now, we'll implement a simple search
    throw UnimplementedError('getBricksByCategory will be implemented with BrickRegistry');
  }

  /// Check if a brick exists
  Future<bool> brickExists(String name) async {
    // This would typically use a cached registry
    // For now, we'll implement a simple search
    throw UnimplementedError('brickExists will be implemented with BrickRegistry');
  }

  /// Get all available brick names
  Future<List<String>> getAvailableBrickNames() async {
    // This would typically use a cached registry
    // For now, we'll implement a simple search
    throw UnimplementedError('getAvailableBrickNames will be implemented with BrickRegistry');
  }
}
