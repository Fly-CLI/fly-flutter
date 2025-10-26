import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

import 'package:fly_cli/src/core/cache/brick_cache_manager.dart';
import 'models/brick_info.dart';

/// Preview of what will be generated during dry-run
class GenerationPreview {
  const GenerationPreview({
    required this.brickName,
    required this.brickType,
    required this.targetDirectory,
    required this.variables,
    required this.filesToGenerate,
    required this.directoriesToCreate,
    required this.estimatedDuration,
    required this.warnings,
  });

  final String brickName;
  final BrickType brickType;
  final String targetDirectory;
  final Map<String, dynamic> variables;
  final List<String> filesToGenerate;
  final List<String> directoriesToCreate;
  final Duration estimatedDuration;
  final List<String> warnings;

  /// Display the preview in a user-friendly format
  void display(Logger logger) {
    logger.info('📋 Generation Preview');
    logger.info('Brick: $brickName (${brickType.name})');
    logger.info('Target: $targetDirectory');
    logger.info('Estimated Duration: ${estimatedDuration.inMilliseconds}ms');

    if (variables.isNotEmpty) {
      logger.info('\n🔧 Variables:');
      for (final entry in variables.entries) {
        final value = entry.value is List
            ? (entry.value as List).join(', ')
            : entry.value.toString();
        logger.info('  ${entry.key}: $value');
      }
    }

    if (directoriesToCreate.isNotEmpty) {
      logger.info('\n📁 Directories to create:');
      for (final dir in directoriesToCreate) {
        logger.info('  $dir');
      }
    }

    if (filesToGenerate.isNotEmpty) {
      logger.info('\n📄 Files to generate:');
      for (final file in filesToGenerate) {
        logger.info('  $file');
      }
    }

    if (warnings.isNotEmpty) {
      logger.warn('\n⚠️  Warnings:');
      for (final warning in warnings) {
        logger.warn('  $warning');
      }
    }
  }

  /// Convert to JSON for caching
  Map<String, dynamic> toJson() => {
        'brick_name': brickName,
        'brick_type': brickType.name,
        'target_directory': targetDirectory,
        'variables': variables,
        'files_to_generate': filesToGenerate,
        'directories_to_create': directoriesToCreate,
        'estimated_duration_ms': estimatedDuration.inMilliseconds,
        'warnings': warnings,
      };

  /// Create from JSON
  factory GenerationPreview.fromJson(Map<String, dynamic> json) =>
      GenerationPreview(
        brickName: json['brick_name'] as String,
        brickType: BrickType.values.firstWhere(
          (e) => e.name == json['brick_type'],
          orElse: () => BrickType.custom,
        ),
        targetDirectory: json['target_directory'] as String,
        variables: Map<String, dynamic>.from(json['variables'] as Map),
        filesToGenerate:
            (json['files_to_generate'] as List<dynamic>).cast<String>(),
        directoriesToCreate:
            (json['directories_to_create'] as List<dynamic>).cast<String>(),
        estimatedDuration:
            Duration(milliseconds: json['estimated_duration_ms'] as int),
        warnings: (json['warnings'] as List<dynamic>).cast<String>(),
      );
}

/// Enhanced dry-run functionality for Mason generation
class GenerationPreviewService {
  GenerationPreviewService({
    required this.logger,
    BrickCacheManager? cacheManager,
  }) : _cacheManager = cacheManager ?? BrickCacheManager(logger: logger);

  final Logger logger;
  final BrickCacheManager _cacheManager;

  /// Generate preview for brick generation
  Future<GenerationPreview> generatePreview({
    required String brickName,
    required BrickType brickType,
    required String outputDirectory,
    required Map<String, dynamic> variables,
    String? projectName,
  }) async {
    logger.detail('Generating preview for brick: $brickName');

    // Check cache first
    final cachedPlan =
        await _cacheManager.loadGenerationPlan(brickName, brickType);
    if (cachedPlan != null) {
      logger.detail('Using cached generation plan');
      return _createPreviewFromPlan(cachedPlan, variables);
    }

    // Generate new preview
    final preview = await _generateNewPreview(
      brickName: brickName,
      brickType: brickType,
      outputDirectory: outputDirectory,
      variables: variables,
      projectName: projectName,
    );

    // Cache the generation plan
    final plan = GenerationPlan(
      brickName: brickName,
      brickType: brickType,
      targetDirectory: preview.targetDirectory,
      variables: variables,
      filesToGenerate: preview.filesToGenerate,
      estimatedDuration: preview.estimatedDuration,
    );

    await _cacheManager.cacheGenerationPlan(plan);

    return preview;
  }

  /// Generate new preview by analyzing brick content
  Future<GenerationPreview> _generateNewPreview({
    required String brickName,
    required BrickType brickType,
    required String outputDirectory,
    required Map<String, dynamic> variables,
    String? projectName,
  }) async {
    final warnings = <String>[];
    final filesToGenerate = <String>[];
    final directoriesToCreate = <String>[];

    // Determine target directory
    final targetDir = projectName != null
        ? path.join(outputDirectory, projectName)
        : outputDirectory;

    // Analyze brick content
    final brickPath = _getBrickPath(brickName, brickType);
    if (brickPath == null) {
      warnings.add('Brick path not found: $brickName');
      return GenerationPreview(
        brickName: brickName,
        brickType: brickType,
        targetDirectory: targetDir,
        variables: variables,
        filesToGenerate: filesToGenerate,
        directoriesToCreate: directoriesToCreate,
        estimatedDuration: const Duration(milliseconds: 0),
        warnings: warnings,
      );
    }

    final brickContentDir = Directory(path.join(brickPath, '__brick__'));
    if (!await brickContentDir.exists()) {
      warnings
          .add('Brick content directory not found: ${brickContentDir.path}');
      return GenerationPreview(
        brickName: brickName,
        brickType: brickType,
        targetDirectory: targetDir,
        variables: variables,
        filesToGenerate: filesToGenerate,
        directoriesToCreate: directoriesToCreate,
        estimatedDuration: const Duration(milliseconds: 0),
        warnings: warnings,
      );
    }

    // Analyze files and directories
    await _analyzeBrickContent(
      brickContentDir,
      targetDir,
      filesToGenerate,
      directoriesToCreate,
      variables,
    );

    // Estimate duration based on file count and complexity
    final estimatedDuration =
        _estimateDuration(filesToGenerate.length, variables);

    return GenerationPreview(
      brickName: brickName,
      brickType: brickType,
      targetDirectory: targetDir,
      variables: variables,
      filesToGenerate: filesToGenerate,
      directoriesToCreate: directoriesToCreate,
      estimatedDuration: estimatedDuration,
      warnings: warnings,
    );
  }

  /// Analyze brick content to determine what will be generated
  Future<void> _analyzeBrickContent(
    Directory brickContentDir,
    String targetDir,
    List<String> filesToGenerate,
    List<String> directoriesToCreate,
    Map<String, dynamic> variables,
  ) async {
    await for (final entity in brickContentDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath =
            path.relative(entity.path, from: brickContentDir.path);
        final processedPath = _processTemplatePath(relativePath, variables);
        final fullPath = path.join(targetDir, processedPath);

        filesToGenerate.add(fullPath);

        // Add parent directories
        final parentDir = path.dirname(fullPath);
        if (parentDir != targetDir &&
            !directoriesToCreate.contains(parentDir)) {
          directoriesToCreate.add(parentDir);
        }
      }
    }
  }

  /// Process template path with variable substitution
  String _processTemplatePath(
      String templatePath, Map<String, dynamic> variables) {
    var result = templatePath;

    for (final entry in variables.entries) {
      final placeholder = '{{${entry.key}}}';
      if (entry.value is List) {
        result =
            result.replaceAll(placeholder, (entry.value as List).join(', '));
      } else {
        result = result.replaceAll(placeholder, entry.value.toString());
      }
    }

    return result;
  }

  /// Estimate generation duration
  Duration _estimateDuration(int fileCount, Map<String, dynamic> variables) {
    // Base time per file (in milliseconds)
    const baseTimePerFile = 50;

    // Additional time for complex variables
    var complexityMultiplier = 1.0;
    for (final value in variables.values) {
      if (value is List && (value as List).length > 5) {
        complexityMultiplier += 0.1;
      }
      if (value is String && (value as String).length > 100) {
        complexityMultiplier += 0.05;
      }
    }

    final estimatedMs =
        (fileCount * baseTimePerFile * complexityMultiplier).round();
    return Duration(
        milliseconds: estimatedMs.clamp(100, 10000)); // Min 100ms, max 10s
  }

  /// Get brick path based on name and type
  String? _getBrickPath(String brickName, BrickType brickType) {
    switch (brickType) {
      case BrickType.project:
        return 'templates/$brickName';
      case BrickType.screen:
      case BrickType.service:
      case BrickType.component:
        return 'packages/fly_cli/templates/$brickName';
      case BrickType.custom:
        return null; // Custom paths would need to be provided
    }
  }

  /// Create preview from cached generation plan
  GenerationPreview _createPreviewFromPlan(
      GenerationPlan plan, Map<String, dynamic> variables) {
    return GenerationPreview(
      brickName: plan.brickName,
      brickType: plan.brickType,
      targetDirectory: plan.targetDirectory,
      variables: variables,
      filesToGenerate: plan.filesToGenerate,
      directoriesToCreate: <String>[],
      // Would need to be calculated
      estimatedDuration: plan.estimatedDuration,
      warnings: <String>[],
    );
  }

  /// Validate variables against brick requirements
  Future<List<String>> validateVariables(
    String brickName,
    BrickType brickType,
    Map<String, dynamic> variables,
  ) async {
    final errors = <String>[];

    // This would need to load the actual brick info to validate
    // For now, return empty list
    return errors;
  }

  /// Get preview statistics
  Map<String, dynamic> getPreviewStats(GenerationPreview preview) => {
        'brick_name': preview.brickName,
        'brick_type': preview.brickType.name,
        'files_count': preview.filesToGenerate.length,
        'directories_count': preview.directoriesToCreate.length,
        'estimated_duration_ms': preview.estimatedDuration.inMilliseconds,
        'warnings_count': preview.warnings.length,
        'variables_count': preview.variables.length,
      };
}
