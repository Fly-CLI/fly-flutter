import 'dart:io';

import 'package:mason/mason.dart';

import 'foundation_model.dart';
import 'planner.dart';
import 'planners/preset_planner.dart';
import 'variables/composed_derived_variables.dart';
import 'variables/feature_variables.dart';
import 'variables/service_variables.dart';
import 'composition.dart';
import 'module_registry.dart';
import 'hook_exception.dart';

/// Result of module selection containing active modules and their metadata.
class ModuleSelectionResult {
  const ModuleSelectionResult({
    required this.activeModules,
    required this.moduleVars,
  });

  /// List of active template modules.
  final List<TemplateModule> activeModules;

  /// Module-specific variables to add to Mason context.
  final Map<String, dynamic> moduleVars;

  /// Gets the list of active module names.
  List<String> get activeModuleNames =>
      activeModules.map((m) => m.name).toList();

  /// Gets the list of template paths from all active modules.
  List<String> get moduleTemplatePaths =>
      activeModules.expand((m) => m.templatePaths).toSet().toList();
}

/// Core hook orchestration API.
///
/// This class provides pure functions for planning, module selection, and
/// file reorganization that can be easily tested and reused.
class HookOrchestrator {
  /// Plans variable derivation using the composite planner system.
  ///
  /// This function:
  /// 1. Applies preset configuration to base variables
  /// 2. Runs cross-cutting planners to build shared variables
  /// 3. Runs the appropriate mode-specific planner
  /// 4. Composes results into ComposedDerivedVariables
  ///
  /// Returns the composed derived variables ready for template rendering.
  static ComposedDerivedVariables plan(
    BaseTemplateVariables base,
    Logger logger,
  ) {
    // Apply preset if specified
    final baseWithPreset = PresetPlanner.applyPresetToBase(base, logger);

    // Run planners to derive variables
    final planner = CompositePlanner();
    return planner.run(baseWithPreset, logger);
  }

  /// Selects active modules based on generation mode and derived variables.
  ///
  /// This function determines which template modules should be active
  /// for the given generation mode and variables, and computes module-specific
  /// variables.
  ///
  /// Returns a ModuleSelectionResult containing active modules and their vars.
  static ModuleSelectionResult selectModules(
    BaseTemplateVariables base,
    ComposedDerivedVariables derived,
  ) {
    return selectModulesWithRegistry(
      base,
      derived,
      ModuleRegistry(),
    );
  }

  /// Selects active modules using a custom registry.
  ///
  /// This is useful for testing or when custom module configurations are needed.
  static ModuleSelectionResult selectModulesWithRegistry(
    BaseTemplateVariables base,
    ComposedDerivedVariables derived,
    ModuleRegistry registry,
  ) {
    final modeVars = derived.toMasonVars();

    // Resolve active modules using the registry
    final moduleConfigs = registry.resolveModules(base.generationMode, modeVars);

    // Create module instances with proper initialization
    final activeModules = <TemplateModule>[];
    for (final config in moduleConfigs) {
      final module = config.module;
      if (module is FeatureModule) {
        activeModules.add(FeatureModule(
          feature: derived.modeSpecific is FeatureVariables
              ? (derived.modeSpecific as FeatureVariables).feature
              : null,
        ));
      } else if (module is ServiceModule) {
        activeModules.add(ServiceModule(
          serviceName: derived.modeSpecific is ServiceVariables
              ? (derived.modeSpecific as ServiceVariables).componentName
              : null,
        ));
      } else {
        activeModules.add(module);
      }
    }

    // Compute module-specific variables
    final moduleVars = <String, dynamic>{
      'active_modules': activeModules.map((m) => m.name).toList(),
      'module_template_paths': activeModules
          .expand((m) => m.templatePaths)
          .toSet()
          .toList(),
    };

    // Add module-specific variables from each active module
    for (final module in activeModules) {
      try {
        moduleVars.addAll(module.getModuleVars(modeVars));
      } catch (e) {
        // If module vars fail, continue without them
        // This is logged at a higher level if needed
        throw HookException(
          'Failed to get vars from module ${module.name}: $e',
        );
      }
    }

    return ModuleSelectionResult(
      activeModules: activeModules,
      moduleVars: moduleVars,
    );
  }

  /// Reorganizes generated files based on active modules.
  ///
  /// This function:
  /// 1. Moves files from `modes/{module}/` to appropriate locations
  /// 2. Removes files from inactive modules
  /// 3. Cleans up the `modes/` directory structure
  ///
  /// The [activeModuleNames] should be a list of module names (e.g., ['project']).
  /// The [outputDir] is the target output directory.
  static void reorganizeFiles(
    Directory outputDir,
    List<String> activeModuleNames,
    Logger logger,
  ) {
    reorganizeFilesWithRegistry(outputDir, activeModuleNames, logger, ModuleRegistry());
  }

  /// Reorganizes generated files using a custom registry.
  ///
  /// This is useful for testing or when custom module configurations are needed.
  static void reorganizeFilesWithRegistry(
    Directory outputDir,
    List<String> activeModuleNames,
    Logger logger,
    ModuleRegistry registry,
  ) {
    if (!outputDir.existsSync()) {
      logger.warn('Output directory does not exist: ${outputDir.path}');
      return;
    }

    final modesDir = Directory(
      outputDir.path.replaceAll(RegExp(r'[/\\]$'), '') + '/modes',
    );
    if (!modesDir.existsSync()) {
      // No modes directory, nothing to reorganize
      return;
    }

    // Process each module directory
    for (final entity in modesDir.listSync()) {
      if (entity is! Directory) continue;

      final moduleName = entity.path.split(Platform.pathSeparator).last;
      final moduleDir = entity;

      if (!activeModuleNames.contains(moduleName)) {
        // Inactive module - remove it
        logger.detail('Removing inactive module: $moduleName');
        moduleDir.deleteSync(recursive: true);
        continue;
      }

      // Active module - move files to appropriate location
      logger.detail('Processing active module: $moduleName');

      // Get disposition from registry
      final disposition = registry.getDisposition(moduleName);
      if (disposition == null) {
        logger.warn(
          'Unknown module disposition for $moduleName, using mergeIntoExisting',
        );
        _mergeDirectoryContents(moduleDir, outputDir, logger);
        continue;
      }

      switch (disposition) {
        case ModuleDisposition.moveToRoot:
          // Project files should be moved to root
          _moveDirectoryContents(moduleDir, outputDir, logger);
          break;
        case ModuleDisposition.mergeIntoExisting:
          // Feature/service/provider files should be merged into existing structure
          // e.g., modes/feature/lib/features/ -> lib/features/
          _mergeDirectoryContents(moduleDir, outputDir, logger);
          break;
        case ModuleDisposition.removeIfInactive:
          // Should not reach here as inactive modules are removed above
          logger.warn(
            'Module $moduleName marked as removeIfInactive but is active',
          );
          break;
      }
    }

    // Clean up the modes directory if empty
    try {
      if (modesDir.existsSync() && modesDir.listSync().isEmpty) {
        modesDir.deleteSync(recursive: true);
      }
    } catch (e) {
      logger.warn('Could not remove modes directory: $e');
    }

    // Clean up any common/ directories that were copied to output
    // These are template partials, not output files
    _removeCommonDirectories(outputDir, logger);

    logger.info(
      '✅ File reorganization complete. Active modules: ${activeModuleNames.join(", ")}',
    );
  }

  /// Remove common/ directories from output (these are template partials, not output files).
  static void _removeCommonDirectories(Directory root, Logger logger) {
    if (!root.existsSync()) return;

    try {
      for (final entity in root.listSync(recursive: true)) {
        if (entity is Directory &&
            entity.path.split(Platform.pathSeparator).last == 'common') {
          logger.detail('Removing common directory: ${entity.path}');
          entity.deleteSync(recursive: true);
        }
      }
    } catch (e) {
      logger.warn('Error removing common directories: $e');
    }
  }

  /// Move all contents from source to destination root.
  static void _moveDirectoryContents(
    Directory source,
    Directory destination,
    Logger logger,
  ) {
    if (!source.existsSync()) return;

    for (final entity in source.listSync(recursive: false)) {
      final name = entity.path.split(Platform.pathSeparator).last;
      final destPath = '${destination.path}${Platform.pathSeparator}$name';

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

  /// Merge directory contents, handling conflicts by merging subdirectories.
  static void _mergeDirectoryContents(
    Directory source,
    Directory destination,
    Logger logger,
  ) {
    if (!source.existsSync()) return;

    for (final entity in source.listSync(recursive: false)) {
      final name = entity.path.split(Platform.pathSeparator).last;
      final destPath = '${destination.path}${Platform.pathSeparator}$name';

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
}

