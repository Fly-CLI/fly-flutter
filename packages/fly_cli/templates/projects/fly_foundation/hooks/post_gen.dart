import 'dart:io';

import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

import 'plugins/mason_variable_keys.dart';
import 'plugins/foundation_model.dart';
import 'plugins/composition_planner.dart';

/// Post-generation hook that reorganizes files based on active modules.
///
/// This hook:
/// 1. Moves files from `modes/{module}/` to the output root (for project mode)
/// 2. Moves files to appropriate locations (for feature/service modes)
/// 3. Removes files from inactive modules
/// 4. Cleans up the `modes/` directory structure
void run(HookContext context) {
  final rawVars = Map<String, dynamic>.from(context.vars);
  final base = BaseTemplateVariables.fromVars(rawVars);
  
  // Get active modules from context (set by pre_gen)
  final activeModuleNames = <String>{};
  final moduleTemplatePaths = rawVars['module_template_paths'] as List<dynamic>?;
  
  if (moduleTemplatePaths != null) {
    // Extract module names from paths (e.g., 'modes/project/' -> 'project')
    for (final path in moduleTemplatePaths) {
      final pathStr = path.toString();
      if (pathStr.startsWith('modes/')) {
        final parts = pathStr.split('/');
        if (parts.length >= 2) {
          activeModuleNames.add(parts[1]);
        }
      }
    }
  } else {
    // Fallback: determine from generation mode
    final compositionPlanner = CompositionPlanner();
    final derived = DerivedTemplateVariables.empty();
    final activeModules = compositionPlanner.getActiveModules(base, derived);
    activeModuleNames.addAll(activeModules.map((m) => m.name));
  }

  // Get the output directory
  final outputDirPath = context.vars['__output_directory__'] as String? ?? '.';
  final outputDir = Directory(outputDirPath);
  if (!outputDir.existsSync()) {
    context.logger.warn('Output directory does not exist: ${outputDir.path}');
    return;
  }

  final modesDir = Directory(path.join(outputDir.path, 'modes'));
  if (!modesDir.existsSync()) {
    // No modes directory, nothing to reorganize
    return;
  }

  // Process each module directory
  for (final entity in modesDir.listSync()) {
    if (entity is! Directory) continue;
    
    final moduleName = path.basename(entity.path);
    final moduleDir = entity;

    if (!activeModuleNames.contains(moduleName)) {
      // Inactive module - remove it
      context.logger.detail('Removing inactive module: $moduleName');
      moduleDir.deleteSync(recursive: true);
      continue;
    }

    // Active module - move files to appropriate location
    context.logger.detail('Processing active module: $moduleName');
    
    switch (moduleName) {
      case 'project':
        // Project files should be moved to root
        _moveDirectoryContents(moduleDir, outputDir, context.logger);
        break;
      case 'feature':
      case 'service':
      case 'provider':
        // Feature/service/provider files should be merged into existing structure
        // e.g., modes/feature/lib/features/ -> lib/features/
        _mergeDirectoryContents(moduleDir, outputDir, context.logger);
        break;
    }
  }

  // Clean up the modes directory if empty
  try {
    if (modesDir.existsSync() && modesDir.listSync().isEmpty) {
      modesDir.deleteSync(recursive: true);
    }
  } catch (e) {
    context.logger.warn('Could not remove modes directory: $e');
  }

  // Clean up any common/ directories that were copied to output
  // These are template partials, not output files
  _removeCommonDirectories(outputDir, context.logger);

  // Clean up partials/ directory that was copied to output
  // These are template partials, not output files
  _removePartialsDirectory(outputDir, context.logger);

  context.logger.info('✅ File reorganization complete. Active modules: ${activeModuleNames.join(", ")}');
}

/// Remove common/ directories from output (these are template partials, not output files)
void _removeCommonDirectories(Directory root, Logger logger) {
  if (!root.existsSync()) return;

  try {
    for (final entity in root.listSync(recursive: true)) {
      if (entity is Directory && path.basename(entity.path) == 'common') {
        logger.detail('Removing common directory: ${entity.path}');
        entity.deleteSync(recursive: true);
      }
    }
  } catch (e) {
    logger.warn('Error removing common directories: $e');
  }
}

/// Remove partials/ directory from output (these are template partials, not output files)
void _removePartialsDirectory(Directory root, Logger logger) {
  if (!root.existsSync()) return;

  try {
    for (final entity in root.listSync(recursive: true)) {
      if (entity is Directory && path.basename(entity.path) == 'partials') {
        logger.detail('Removing partials directory: ${entity.path}');
        entity.deleteSync(recursive: true);
      }
    }
  } catch (e) {
    logger.warn('Error removing partials directory: $e');
  }
}

/// Move all contents from source to destination root
void _moveDirectoryContents(Directory source, Directory destination, Logger logger) {
  if (!source.existsSync()) return;

  for (final entity in source.listSync(recursive: false)) {
    final name = path.basename(entity.path);
    final destPath = path.join(destination.path, name);
    
    if (entity is File) {
      final destFile = File(destPath);
      if (destFile.existsSync()) {
        logger.detail('Overwriting file: $name');
        destFile.deleteSync();
      }
      entity.renameSync(destPath);
    } else if (entity is Directory) {
      final destDir = Directory(destPath);
      if (destDir.existsSync()) {
        logger.detail('Merging directory: $name');
        _mergeDirectoryContents(entity, destDir, logger);
        entity.deleteSync(recursive: true);
      } else {
        entity.renameSync(destPath);
      }
    }
  }
}

/// Merge directory contents, handling conflicts by merging subdirectories
void _mergeDirectoryContents(Directory source, Directory destination, Logger logger) {
  if (!source.existsSync()) return;

  for (final entity in source.listSync(recursive: false)) {
    final name = path.basename(entity.path);
    final destPath = path.join(destination.path, name);
    
    if (entity is File) {
      final destFile = File(destPath);
      if (destFile.existsSync()) {
        logger.detail('Overwriting file: $name');
        destFile.deleteSync();
      }
      entity.renameSync(destPath);
    } else if (entity is Directory) {
      final destDir = Directory(destPath);
      if (!destDir.existsSync()) {
        destDir.createSync(recursive: true);
      }
      _mergeDirectoryContents(entity, destDir, logger);
      // Try to remove source directory if empty
      try {
        if (entity.listSync().isEmpty) {
          entity.deleteSync(recursive: true);
        }
      } catch (e) {
        // Ignore errors when removing non-empty directories
      }
    }
  }
}

