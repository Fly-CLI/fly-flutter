import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'models/brick_info.dart';

/// Validation result for brick validation
class BrickValidationResult {
  const BrickValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  /// Create a successful validation result
  factory BrickValidationResult.success() => const BrickValidationResult(
        isValid: true,
        errors: [],
        warnings: [],
      );

  /// Create a failed validation result
  factory BrickValidationResult.failure(List<String> errors,
          [List<String>? warnings]) =>
      BrickValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings ?? [],
      );

  @override
  String toString() =>
      'BrickValidationResult(isValid: $isValid, errors: ${errors.length}, warnings: ${warnings.length})';
}

/// Unified registry for managing all Mason bricks
class BrickRegistry {
  BrickRegistry({
    required this.logger,
    List<String>? customBrickPaths,
  }) : _customBrickPaths = customBrickPaths ?? [];

  final Logger logger;
  final List<String> _customBrickPaths;

  /// Cache for discovered bricks
  final Map<String, BrickInfo> _brickCache = {};

  /// Cache for validation results
  final Map<String, BrickValidationResult> _validationCache = {};

  /// Default brick search paths
  static const List<String> _defaultBrickPaths = [
    'templates',
    'packages/fly_cli/templates',
  ];

  /// Discover all available bricks
  Future<List<BrickInfo>> discoverBricks({bool forceRefresh = false}) async {
    if (!forceRefresh && _brickCache.isNotEmpty) {
      return _brickCache.values.toList();
    }

    logger.info('Discovering Mason bricks...');
    final bricks = <BrickInfo>[];

    // Search in default paths
    for (final searchPath in _defaultBrickPaths) {
      final bricksInPath = await _discoverBricksInPath(searchPath);
      bricks.addAll(bricksInPath);
    }

    // Search in custom paths
    for (final customPath in _customBrickPaths) {
      final bricksInPath = await _discoverBricksInPath(customPath);
      bricks.addAll(bricksInPath);
    }

    // Cache discovered bricks
    _brickCache.clear();
    for (final brick in bricks) {
      _brickCache[brick.name] = brick;
    }

    logger.info('Discovered ${bricks.length} bricks');
    return bricks;
  }

  /// Discover bricks in a specific path
  Future<List<BrickInfo>> _discoverBricksInPath(String searchPath) async {
    final bricks = <BrickInfo>[];

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
                'Found brick: ${brickInfo.name} (${brickInfo.type.name})');
          }
        }
      }
    } catch (e) {
      logger.warn('Error discovering bricks in $searchPath: $e');
    }

    return bricks;
  }

  /// Load brick information from a directory
  Future<BrickInfo?> _loadBrickFromDirectory(String brickPath) async {
    try {
      // Check if brick.yaml exists
      final brickYamlFile = File(path.join(brickPath, 'brick.yaml'));
      if (!await brickYamlFile.exists()) {
        return null;
      }

      // Check if __brick__ directory exists
      final brickContentDir = Directory(path.join(brickPath, '__brick__'));
      if (!await brickContentDir.exists()) {
        logger.warn('Brick $brickPath missing __brick__ directory');
        return null;
      }

      // Parse brick.yaml
      final yamlContent = await brickYamlFile.readAsString();
      final yaml = loadYaml(yamlContent) as Map<dynamic, dynamic>;

      // Determine brick type based on path
      final brickType = _determineBrickType(brickPath);

      // Create BrickInfo
      final brickInfo = BrickInfo.fromYaml(yaml, brickPath, brickType);

      // Validate brick
      final validationResult = await validateBrick(brickInfo);
      if (!validationResult.isValid) {
        logger.warn(
            'Brick ${brickInfo.name} failed validation: ${validationResult.errors.join(', ')}');
        return BrickInfo(
          name: brickInfo.name,
          version: brickInfo.version,
          description: brickInfo.description,
          path: brickInfo.path,
          type: brickInfo.type,
          variables: brickInfo.variables,
          features: brickInfo.features,
          packages: brickInfo.packages,
          minFlutterSdk: brickInfo.minFlutterSdk,
          minDartSdk: brickInfo.minDartSdk,
          isValid: false,
          validationErrors: validationResult.errors,
        );
      }

      return brickInfo;
    } catch (e) {
      logger.warn('Error loading brick from $brickPath: $e');
      return null;
    }
  }

  /// Determine brick type based on path
  BrickType _determineBrickType(String brickPath) {
    final pathSegments = path.split(brickPath);

    // Check if it's in the main templates directory (project templates)
    if (pathSegments.contains('templates') &&
        !pathSegments.contains('fly_cli')) {
      return BrickType.project;
    }

    // Check if it's in fly_cli templates (component templates)
    if (pathSegments.contains('fly_cli') &&
        pathSegments.contains('templates')) {
      final brickName = pathSegments.last;
      switch (brickName) {
        case 'screen':
          return BrickType.screen;
        case 'service':
          return BrickType.service;
        default:
          return BrickType.component;
      }
    }

    return BrickType.custom;
  }

  /// Get brick by name
  Future<BrickInfo?> getBrick(String name) async {
    // Ensure bricks are discovered
    await discoverBricks();
    return _brickCache[name];
  }

  /// Get bricks by type
  Future<List<BrickInfo>> getBricksByType(BrickType type) async {
    await discoverBricks();
    return _brickCache.values.where((brick) => brick.type == type).toList();
  }

  /// Get all project bricks
  Future<List<BrickInfo>> getProjectBricks() async {
    return getBricksByType(BrickType.project);
  }

  /// Get all screen bricks
  Future<List<BrickInfo>> getScreenBricks() async {
    return getBricksByType(BrickType.screen);
  }

  /// Get all service bricks
  Future<List<BrickInfo>> getServiceBricks() async {
    return getBricksByType(BrickType.service);
  }

  /// Get all component bricks
  Future<List<BrickInfo>> getComponentBricks() async {
    return getBricksByType(BrickType.component);
  }

  /// Search bricks by name or description
  Future<List<BrickInfo>> searchBricks(String query) async {
    await discoverBricks();
    final lowercaseQuery = query.toLowerCase();

    return _brickCache.values.where((brick) {
      return brick.name.toLowerCase().contains(lowercaseQuery) ||
          brick.description.toLowerCase().contains(lowercaseQuery) ||
          brick.features
              .any((feature) => feature.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  /// Validate a brick
  Future<BrickValidationResult> validateBrick(BrickInfo brick) async {
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
            'Brick content directory does not exist: ${brick.brickContentPath}');
      }

      // Check if brick.yaml exists and is valid
      final brickYamlFile = File(path.join(brick.path, 'brick.yaml'));
      if (!await brickYamlFile.exists()) {
        errors.add('brick.yaml file does not exist');
      } else {
        try {
          final yamlContent = await brickYamlFile.readAsString();
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
          errors.add('Invalid brick.yaml format: $e');
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
        final hasFiles =
            await brickContentDir.list().any((entity) => entity is File);
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
