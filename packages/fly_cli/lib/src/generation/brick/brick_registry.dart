import 'dart:io';

import 'package:fly_cli/src/generation/brick/brick_metadata.dart';
import 'package:fly_cli/src/generation/domain/entities/brick.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Unified registry for managing all Mason bricks
class BrickRegistry {
  BrickRegistry({
    required this.logger,
    List<String>? customBrickPaths,
  }) : _customBrickPaths = customBrickPaths ?? [];

  final Logger logger;
  final List<String> _customBrickPaths;

  /// Cache for discovered bricks
  final Map<String, Brick> _brickCache = {};

  /// Cache for validation results
  final Map<String, BrickValidationResult> _validationCache = {};

  /// Find bricks directory (workspace root/bricks)
  ///
  /// Returns the absolute path to the bricks directory if it exists.
  static String? findBricksDirectory() {
    final currentDir = Directory.current.path;

    // Try workspace root/bricks
    final bricksPath = path.join(currentDir, 'bricks');
    if (Directory(bricksPath).existsSync()) {
      return path.normalize(bricksPath);
    }

    // Try from packages/fly_cli location (monorepo)
    final monorepoBricksPath = path.join(currentDir, '..', '..', 'bricks');
    final normalizedMonorepoPath = path.normalize(monorepoBricksPath);
    if (Directory(normalizedMonorepoPath).existsSync()) {
      return normalizedMonorepoPath;
    }

    return null;
  }

  /// Discover all available bricks
  ///
  /// Searches in the bricks directory:
  /// - {workspaceRoot}/bricks/
  Future<List<Brick>> discoverBricks({bool forceRefresh = false}) async {
    if (!forceRefresh && _brickCache.isNotEmpty) {
      return _brickCache.values.toList();
    }

    logger.info('Discovering Mason bricks...');
    final bricks = <Brick>[];

    // Search in bricks/ workspace directory
    final bricksDirectory = findBricksDirectory();
    if (bricksDirectory != null) {
      logger.detail('Searching for bricks in: $bricksDirectory');
      final workspaceBricks = await _discoverBricksInPath(bricksDirectory);
      bricks.addAll(workspaceBricks);
    } else {
      logger.warn(
        'Bricks directory not found. Expected at workspace root/bricks/',
      );
    }

    // Search in custom paths if provided
    for (final customPath in _customBrickPaths) {
      final customBricks = await _discoverBricksInPath(customPath);
      bricks.addAll(customBricks);
    }

    // Cache discovered bricks
    _brickCache.clear();
    for (final brick in bricks) {
      _brickCache[brick.name] = brick;
      logger.detail('Cached brick: ${brick.name} (${brick.type.name})');
    }

    logger.info('Discovered ${bricks.length} bricks');
    return bricks;
  }

  /// Discover bricks in a specific path
  Future<List<Brick>> _discoverBricksInPath(String searchPath) async {
    final bricks = <Brick>[];

    try {
      final dir = Directory(searchPath);
      if (!await dir.exists()) {
        logger.detail('Brick path does not exist: $searchPath');
        return bricks;
      }

      await for (final entity in dir.list()) {
        if (entity is Directory) {
          final brickInfo = await _loadBrickFromDirectory(entity.path);
          if (brickInfo != null) {
            bricks.add(brickInfo);
            logger.detail(
              'Found brick: ${brickInfo.name} (${brickInfo.type.name})',
            );
          }
        }
      }
    } catch (e) {
      logger.warn('Error discovering bricks in $searchPath: $e');
    }

    return bricks;
  }

  /// Load brick information from a directory
  Future<Brick?> _loadBrickFromDirectory(String brickPath) async {
    try {
      // Check if brick.yaml or template.yaml exists
      final brickYamlFile = File(path.join(brickPath, 'brick.yaml'));
      final templateYamlFile = File(path.join(brickPath, 'template.yaml'));

      File? yamlFile;
      if (await brickYamlFile.exists()) {
        yamlFile = brickYamlFile;
      } else if (await templateYamlFile.exists()) {
        yamlFile = templateYamlFile;
      } else {
        return null;
      }

      // Check if __brick__ directory exists
      final brickContentDir = Directory(path.join(brickPath, '__brick__'));
      if (!await brickContentDir.exists()) {
        logger.warn('Brick $brickPath missing __brick__ directory');
        return null;
      }

      // Parse yaml file
      final yamlContent = await yamlFile.readAsString();
      final yaml = loadYaml(yamlContent) as Map<dynamic, dynamic>;

      // Check for separate fly_metadata.yaml file for type (Mason doesn't allow custom keys in brick.yaml)
      final flyMetadataFile = File(path.join(brickPath, 'fly_metadata.yaml'));
      Map<dynamic, dynamic>? flyMetadata;
      if (await flyMetadataFile.exists()) {
        try {
          final metadataContent = await flyMetadataFile.readAsString();
          flyMetadata = loadYaml(metadataContent) as Map<dynamic, dynamic>?;
          logger.detail(
            'Loaded fly_metadata.yaml for brick $brickPath: $flyMetadata',
          );
        } catch (e) {
          logger.warn(
            'Failed to parse fly_metadata.yaml for brick $brickPath: $e',
          );
        }
      } else {
        logger.warn(
          'Brick $brickPath missing fly_metadata.yaml file. '
          'Type information is required for brick discovery.',
        );
      }

      // Merge metadata into yaml if available (metadata takes precedence)
      final mergedYaml = Map<dynamic, dynamic>.from(yaml);
      if (flyMetadata != null) {
        mergedYaml.addAll(flyMetadata);
        logger.detail(
          'Merged metadata into YAML for brick $brickPath. Type: ${mergedYaml['type']}',
        );
      } else {
        // Type is required - throw a clear error if fly_metadata.yaml is missing
        throw ArgumentError(
          'Brick $brickPath is missing fly_metadata.yaml file with type information. '
          'Create fly_metadata.yaml with: type: <project|feature|service|component|custom>',
        );
      }

      // Verify type is present before creating Brick
      if (mergedYaml['type'] == null) {
        throw ArgumentError(
          'Brick $brickPath: type field is missing in fly_metadata.yaml. '
          'Add "type: <project|feature|service|component|custom>" to fly_metadata.yaml',
        );
      }

      // Create Brick directly from YAML
      final brick = Brick.fromYaml(mergedYaml, brickPath);

      // Validate brick
      final validationResult = await validateBrick(brick);
      if (!validationResult.isValid) {
        logger.warn(
          'Brick ${brick.name} failed validation: ${validationResult.errors.join(', ')}',
        );
        return Brick(
          name: brick.name,
          version: brick.version,
          description: brick.description,
          path: brick.path,
          type: brick.type,
          category: brick.category,
          variables: brick.variables,
          features: brick.features,
          packages: brick.packages,
          minFlutterSdk: brick.minFlutterSdk,
          minDartSdk: brick.minDartSdk,
          isValid: false,
          validationErrors: validationResult.errors,
        );
      }

      return brick;
    } catch (e, stackTrace) {
      logger.warn('Error loading brick from $brickPath: $e');
      logger.detail('Stack trace: $stackTrace');
      // If it's an ArgumentError about missing type, provide helpful message
      if (e is ArgumentError) {
        final message = e.message;
        if (message != null && message.toString().contains('type')) {
          logger.err(
            'Brick $brickPath is missing type information. '
            'Ensure fly_metadata.yaml exists with a "type" field.',
          );
        }
      }
      return null;
    }
  }

  /// Get brick by name
  Future<Brick?> getBrick(String name) async {
    // Ensure bricks are discovered
    await discoverBricks();
    final brick = _brickCache[name];
    logger.detail('Looking for brick: $name');
    if (brick != null) {
      logger.detail('Found brick: ${brick.name} (${brick.type.name})');
    } else {
      logger.detail('Brick not found: $name');
      logger.detail('Available bricks: ${_brickCache.keys.toList()}');
    }
    return brick;
  }

  /// Get bricks by type
  Future<List<Brick>> getBricksByType(BrickType type) async {
    await discoverBricks();
    return _brickCache.values.where((brick) => brick.type == type).toList();
  }

  /// Get all project bricks
  Future<List<Brick>> getProjectBricks() async {
    return getBricksByType(BrickType.project);
  }

  /// Get all screen bricks
  Future<List<Brick>> getScreenBricks() async {
    return getBricksByType(BrickType.feature);
  }

  /// Get all service bricks
  Future<List<Brick>> getServiceBricks() async {
    return getBricksByType(BrickType.service);
  }

  /// Get all component bricks
  Future<List<Brick>> getComponentBricks() async {
    return getBricksByType(BrickType.component);
  }

  /// Search bricks by name or description
  Future<List<Brick>> searchBricks(String query) async {
    await discoverBricks();
    final lowercaseQuery = query.toLowerCase();

    return _brickCache.values.where((brick) {
      return brick.name.toLowerCase().contains(lowercaseQuery) ||
          brick.description.toLowerCase().contains(lowercaseQuery) ||
          brick.features.any(
            (feature) => feature.toLowerCase().contains(lowercaseQuery),
          );
    }).toList();
  }

  /// Validate a brick
  Future<BrickValidationResult> validateBrick(Brick brick) async {
    // Check cache first
    if (_validationCache.containsKey(brick.name)) {
      return _validationCache[brick.name]!;
    }

    final errors = <String>[];
    final warnings = <String>[];

    try {
      // Check if brick directory exists
      final brickDir = Directory(brick.path);
      if (!await brickDir.exists()) {
        errors.add('Brick directory does not exist: ${brick.path}');
      }

      // Check if __brick__ directory exists
      final brickContentDir = Directory(brick.brickContentPath);
      if (!await brickContentDir.exists()) {
        errors.add(
          'Brick content directory does not exist: ${brick.brickContentPath}',
        );
      }

      // Check if brick.yaml or template.yaml exists and is valid
      final brickYamlFile = File(path.join(brick.path, 'brick.yaml'));
      final templateYamlFile = File(path.join(brick.path, 'template.yaml'));

      File? yamlFile;
      if (await brickYamlFile.exists()) {
        yamlFile = brickYamlFile;
      } else if (await templateYamlFile.exists()) {
        yamlFile = templateYamlFile;
      } else {
        errors.add('brick.yaml or template.yaml file does not exist');
      }

      if (yamlFile != null && await yamlFile.exists()) {
        try {
          final yamlContent = await yamlFile.readAsString();
          final yaml = loadYaml(yamlContent) as Map<dynamic, dynamic>;

          // Validate required fields
          if (yaml['name'] == null || (yaml['name'] as String).isEmpty) {
            errors.add('Brick name is required');
          }

          if (yaml['description'] == null ||
              (yaml['description'] as String).isEmpty) {
            warnings.add('Brick description is missing');
          }
        } catch (e) {
          errors.add('Invalid yaml format: $e');
        }
      }

      // Check for required variables
      for (final variable in brick.requiredVariables) {
        if (variable.name.isEmpty) {
          errors.add('Variable name cannot be empty');
        }

        if (variable.type.isEmpty) {
          errors.add('Variable type is required for ${variable.name}');
        }
      }

      // Check for duplicate variable names
      final variableNames = brick.variables.keys.toList();
      final uniqueNames = variableNames.toSet();
      if (variableNames.length != uniqueNames.length) {
        errors.add('Duplicate variable names found');
      }

      // Check brick content structure
      if (await brickContentDir.exists()) {
        final hasFiles = await brickContentDir.list().any(
          (entity) => entity is File,
        );
        if (!hasFiles) {
          warnings.add('Brick content directory is empty');
        }
      }
    } catch (e) {
      errors.add('Validation error: $e');
    }

    final result = errors.isEmpty
        ? BrickValidationResult.success()
        : BrickValidationResult.failure(errors, warnings);

    // Cache validation result
    _validationCache[brick.name] = result;

    return result;
  }

  /// Validate brick by name
  Future<BrickValidationResult> validateBrickByName(String brickName) async {
    final brick = await getBrick(brickName);
    if (brick == null) {
      return BrickValidationResult.failure(['Brick not found: $brickName']);
    }

    return validateBrick(brick);
  }

  /// Clear all caches
  void clearCache() {
    _brickCache.clear();
    _validationCache.clear();
    logger.info('Brick registry cache cleared');
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() => {
    'bricks': _brickCache.length,
    'validations': _validationCache.length,
  };

  /// Add custom brick path
  void addCustomBrickPath(String path) {
    if (!_customBrickPaths.contains(path)) {
      _customBrickPaths.add(path);
      logger.info('Added custom brick path: $path');
    }
  }

  /// Remove custom brick path
  void removeCustomBrickPath(String path) {
    if (_customBrickPaths.remove(path)) {
      logger.info('Removed custom brick path: $path');
    }
  }

  /// Get all custom brick paths
  List<String> get customBrickPaths => List.unmodifiable(_customBrickPaths);
}
