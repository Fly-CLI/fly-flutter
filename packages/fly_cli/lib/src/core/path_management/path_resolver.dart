import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:mason_logger/mason_logger.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/path_management/models/resolved_path.dart';

/// Single source of truth for all path resolution in Fly CLI
/// 
/// This service centralizes all path computation, resolution, and validation.
/// All commands and services must use this resolver instead of manually
/// constructing paths or using scattered path utilities.
class PathResolver {
  PathResolver({
    required this.logger,
    required this.isDevelopment,
  });

  final Logger logger;
  final bool isDevelopment;

  /// Resolve working directory from context with fallbacks
  /// 
  /// Priority order:
  /// 1. FLY_OUTPUT_DIR environment variable
  /// 2. PWD environment variable  
  /// 3. context.workingDirectory
  /// 4. Directory.current.path
  Future<PathResolutionResult> resolveWorkingDirectory(CommandContext context) async {
    try {
      String workingDir;
      
      // Check environment variables first
      final flyOutputDir = Platform.environment['FLY_OUTPUT_DIR'];
      if (flyOutputDir != null && flyOutputDir.isNotEmpty) {
        workingDir = path.normalize(flyOutputDir);
        logger.detail('Using FLY_OUTPUT_DIR: $workingDir');
      } else {
        final pwd = Platform.environment['PWD'];
        if (pwd != null && pwd.isNotEmpty) {
          workingDir = path.normalize(pwd);
          logger.detail('Using PWD: $workingDir');
        } else {
          workingDir = context.workingDirectory;
          logger.detail('Using context.workingDirectory: $workingDir');
        }
      }

      // Validate the working directory
      final dir = Directory(workingDir);
      final exists = await dir.exists();
      final writable = await _isWritable(workingDir);

      final validationErrors = <String>[];
      if (!exists) {
        validationErrors.add('Working directory does not exist: $workingDir');
      }
      if (!writable) {
        validationErrors.add('Working directory is not writable: $workingDir');
      }

      final resolvedPath = WorkingDirectoryPath(
        absolute: workingDir,
        exists: exists,
        writable: writable,
        validationErrors: validationErrors,
      );

      return PathResolutionResult.success(resolvedPath);
    } catch (e) {
      return PathResolutionResult.failure(['Failed to resolve working directory: $e']);
    }
  }

  /// Resolve output directory with validation
  /// 
  /// Uses the provided outputDir or falls back to working directory
  Future<PathResolutionResult> resolveOutputDirectory(
    CommandContext context,
    String? outputDir,
  ) async {
    try {
      final workingDirResult = await resolveWorkingDirectory(context);
      if (!workingDirResult.success) {
        return workingDirResult;
      }

      final workingDir = workingDirResult.path as WorkingDirectoryPath;
      final targetDir = outputDir ?? workingDir.absolute;

      // Validate the output directory
      final dir = Directory(targetDir);
      final exists = await dir.exists();
      final writable = await _isWritable(targetDir);

      final validationErrors = <String>[];
      if (!exists) {
        validationErrors.add('Output directory does not exist: $targetDir');
      }
      if (!writable) {
        validationErrors.add('Output directory is not writable: $targetDir');
      }

      final resolvedPath = WorkingDirectoryPath(
        absolute: targetDir,
        exists: exists,
        writable: writable,
        validationErrors: validationErrors,
      );

      return PathResolutionResult.success(resolvedPath);
    } catch (e) {
      return PathResolutionResult.failure(['Failed to resolve output directory: $e']);
    }
  }

  /// Resolve template directory (replaces TemplateManager.findTemplatesDirectory)
  /// 
  /// Uses environment-based resolution with single strategy per mode
  Future<PathResolutionResult> resolveTemplatesDirectory() async {
    try {
      String templatesDir;
      
      if (isDevelopment) {
        templatesDir = _resolveDevTemplatesPath();
      } else {
        templatesDir = _resolveProdTemplatesPath();
      }

      // Validate the templates directory
      final dir = Directory(templatesDir);
      final exists = await dir.exists();
      final writable = await _isWritable(templatesDir);

      final validationErrors = <String>[];
      if (!exists) {
        validationErrors.add('Templates directory does not exist: $templatesDir');
      }
      if (!writable) {
        validationErrors.add('Templates directory is not writable: $templatesDir');
      }

      final resolvedPath = TemplatePath(
        absolute: templatesDir,
        exists: exists,
        writable: writable,
        validationErrors: validationErrors,
      );

      return PathResolutionResult.success(resolvedPath);
    } catch (e) {
      return PathResolutionResult.failure(['Failed to resolve templates directory: $e']);
    }
  }

  /// Resolve project path (outputDir + projectName)
  Future<PathResolutionResult> resolveProjectPath(
    CommandContext context,
    String projectName,
    String? outputDir,
  ) async {
    try {
      final outputDirResult = await resolveOutputDirectory(context, outputDir);
      if (!outputDirResult.success) {
        return outputDirResult;
      }

      final outputDirPath = outputDirResult.path as WorkingDirectoryPath;
      final projectPath = path.join(outputDirPath.absolute, projectName);

      // Validate the project directory
      final dir = Directory(projectPath);
      final exists = await dir.exists();
      final writable = await _isWritable(projectPath);

      final validationErrors = <String>[];
      if (!writable) {
        validationErrors.add('Project directory is not writable: $projectPath');
      }

      // Check if project already exists (warning, not error)
      if (exists) {
        logger.warn('Project directory already exists: $projectPath');
      }

      final resolvedPath = ProjectPath(
        absolute: projectPath,
        projectName: projectName,
        exists: exists,
        writable: writable,
        validationErrors: validationErrors,
      );

      return PathResolutionResult.success(resolvedPath);
    } catch (e) {
      return PathResolutionResult.failure(['Failed to resolve project path: $e']);
    }
  }

  /// Resolve component path (projectPath + feature structure)
  Future<PathResolutionResult> resolveComponentPath(
    CommandContext context,
    String componentName,
    String componentType,
    String feature,
    String? outputDir,
  ) async {
    try {
      // First resolve the project directory
      final projectDirResult = await _resolveProjectDirectory(context, outputDir);
      if (!projectDirResult.success) {
        return projectDirResult;
      }

      final projectDir = projectDirResult.path as WorkingDirectoryPath;
      
      // Build component path based on type and feature
      final componentPath = _buildComponentPath(
        projectDir.absolute,
        componentName,
        componentType,
        feature,
      );

      // Validate the component directory
      final dir = Directory(componentPath);
      final exists = await dir.exists();
      final writable = await _isWritable(componentPath);

      final validationErrors = <String>[];
      if (!writable) {
        validationErrors.add('Component directory is not writable: $componentPath');
      }

      final resolvedPath = ComponentPath(
        absolute: componentPath,
        componentName: componentName,
        componentType: componentType,
        feature: feature,
        exists: exists,
        writable: writable,
        validationErrors: validationErrors,
      );

      return PathResolutionResult.success(resolvedPath);
    } catch (e) {
      return PathResolutionResult.failure(['Failed to resolve component path: $e']);
    }
  }

  /// Resolve project directory for component operations
  Future<PathResolutionResult> _resolveProjectDirectory(
    CommandContext context,
    String? outputDir,
  ) async {
    // If outputDir is provided, use it directly
    if (outputDir != null) {
      return await resolveOutputDirectory(context, outputDir);
    }

    // Otherwise, try to find Flutter project from current working directory
    final workingDirResult = await resolveWorkingDirectory(context);
    if (!workingDirResult.success) {
      return workingDirResult;
    }

    final workingDir = workingDirResult.path as WorkingDirectoryPath;
    
    // Check if current directory is a Flutter project
    final pubspecFile = File(path.join(workingDir.absolute, 'pubspec.yaml'));
    if (await pubspecFile.exists()) {
      return PathResolutionResult.success(workingDir);
    }

    // Look for Flutter project in parent directories
    String currentDir = workingDir.absolute;
    for (int i = 0; i < 5; i++) { // Limit search depth
      final parentDir = path.dirname(currentDir);
      if (parentDir == currentDir) break; // Reached root
      
      final pubspecFile = File(path.join(parentDir, 'pubspec.yaml'));
      if (await pubspecFile.exists()) {
        final dir = Directory(parentDir);
        final exists = await dir.exists();
        final writable = await _isWritable(parentDir);
        
        final resolvedPath = WorkingDirectoryPath(
          absolute: parentDir,
          exists: exists,
          writable: writable,
        );
        
        return PathResolutionResult.success(resolvedPath);
      }
      
      currentDir = parentDir;
    }

    return PathResolutionResult.failure([
      'Not in a Flutter project directory',
      'Run this command from a Flutter project root directory or specify --output-dir',
    ]);
  }

  /// Build component path based on type and feature
  String _buildComponentPath(
    String projectDir,
    String componentName,
    String componentType,
    String feature,
  ) {
    switch (componentType) {
      case 'screen':
        return path.join(
          projectDir,
          'lib',
          'features',
          feature,
          'presentation',
          '${componentName}_screen.dart',
        );
      case 'service':
        return path.join(
          projectDir,
          'lib',
          'features',
          feature,
          'services',
          '${componentName}_service.dart',
        );
      case 'widget':
        return path.join(
          projectDir,
          'lib',
          'features',
          feature,
          'widgets',
          '${componentName}_widget.dart',
        );
      default:
        return path.join(
          projectDir,
          'lib',
          'features',
          feature,
          componentType,
          '${componentName}_$componentType.dart',
        );
    }
  }

  /// Resolve development templates path
  String _resolveDevTemplatesPath() {
    final currentDir = Directory.current.path;
    final devTemplatesPath = path.join(currentDir, 'packages', 'fly_cli', 'templates');
    return path.normalize(devTemplatesPath);
  }

  /// Resolve production templates path
  String _resolveProdTemplatesPath() {
    final executablePath = Platform.resolvedExecutable;
    final executableDir = path.dirname(executablePath);
    return path.normalize(path.join(executableDir, '..', 'templates'));
  }

  /// Check if a directory is writable
  Future<bool> _isWritable(String dirPath) async {
    try {
      final tempFile = File(path.join(dirPath, '.fly_temp_${DateTime.now().millisecondsSinceEpoch}'));
      await tempFile.create();
      await tempFile.delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}
