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
/// This class provides methods for planning, module selection, and
/// file reorganization that can be easily tested and reused.
class HookOrchestrator {
  /// Creates a hook orchestrator with default registry and planner.
  HookOrchestrator({
    ModuleRegistry? registry,
    CompositePlanner? planner,
  })  : _registry = registry ?? ModuleRegistry(),
        _planner = planner ?? CompositePlanner();

  final ModuleRegistry _registry;
  final CompositePlanner _planner;

  /// Plans variable derivation using the composite planner system.
  ///
  /// This method:
  /// 1. Applies preset configuration to base variables
  /// 2. Runs cross-cutting planners to build shared variables
  /// 3. Runs the appropriate mode-specific planner
  /// 4. Composes results into ComposedDerivedVariables
  ///
  /// Returns the composed derived variables ready for template rendering.
  ComposedDerivedVariables plan(
    BaseTemplateVariables base,
    Logger logger,
  ) {
    // Apply preset if specified
    final baseWithPreset = PresetPlanner.applyPresetToBase(base, logger);

    // Run planners to derive variables
    return _planner.run(baseWithPreset, logger);
  }

  /// Selects active modules based on generation mode and derived variables.
  ///
  /// This method determines which template modules should be active
  /// for the given generation mode and variables, and computes module-specific
  /// variables.
  ///
  /// Returns a ModuleSelectionResult containing active modules and their vars.
  ModuleSelectionResult selectModules(
    BaseTemplateVariables base,
    ComposedDerivedVariables derived,
  ) {
    final modeVars = derived.toMasonVars();
    final moduleConfigs = _registry.resolveModules(base.generationMode, modeVars);
    final activeModules = _createModuleInstances(moduleConfigs, derived);
    final moduleVars = _computeModuleVars(activeModules, modeVars);

    return ModuleSelectionResult(
      activeModules: activeModules,
      moduleVars: moduleVars,
    );
  }

  /// Creates module instances with proper initialization from configs.
  List<TemplateModule> _createModuleInstances(
    List<ModuleConfig> configs,
    ComposedDerivedVariables derived,
  ) {
    return configs.map((config) {
      final module = config.module;
      if (module is FeatureModule) {
        final feature = derived.modeSpecific is FeatureVariables
            ? (derived.modeSpecific as FeatureVariables).feature
            : null;
        return FeatureModule(feature: feature);
      } else if (module is ServiceModule) {
        final serviceName = derived.modeSpecific is ServiceVariables
            ? (derived.modeSpecific as ServiceVariables).componentName
            : null;
        return ServiceModule(serviceName: serviceName);
      }
      return module;
    }).toList();
  }

  /// Computes module-specific variables from active modules.
  Map<String, dynamic> _computeModuleVars(
    List<TemplateModule> activeModules,
    Map<String, dynamic> modeVars,
  ) {
    final moduleVars = <String, dynamic>{
      'active_modules': activeModules.map((m) => m.name).toList(),
      'module_template_paths': activeModules
          .expand((m) => m.templatePaths)
          .toSet()
          .toList(),
    };

    for (final module in activeModules) {
      try {
        moduleVars.addAll(module.getModuleVars(modeVars));
      } catch (e) {
        throw HookException(
          'Failed to get vars from module ${module.name}: $e',
        );
      }
    }

    return moduleVars;
  }

  /// Reorganizes generated files based on active modules.
  ///
  /// This method:
  /// 1. Moves files from `modes/{module}/` to appropriate locations
  /// 2. Removes files from inactive modules
  /// 3. Cleans up the `modes/` directory structure
  ///
  /// The [activeModuleNames] should be a list of module names (e.g., ['project']).
  /// The [outputDir] is the target output directory.
  void reorganizeFiles(
    Directory outputDir,
    List<String> activeModuleNames,
    Logger logger,
  ) {

    if (!outputDir.existsSync()) {
      logger.warn('Output directory does not exist: ${outputDir.path}');
      return;
    }

    final modesDir = Directory(
      outputDir.path.replaceAll(RegExp(r'[/\\]$'), '') + '/modes',
    );
    if (!modesDir.existsSync()) {
      return;
    }

    for (final entity in modesDir.listSync()) {
      if (entity is! Directory) continue;

      final moduleName = entity.path.split(Platform.pathSeparator).last;
      if (!activeModuleNames.contains(moduleName)) {
        logger.detail('Removing inactive module: $moduleName');
        entity.deleteSync(recursive: true);
        continue;
      }

      logger.detail('Processing active module: $moduleName');
      _processActiveModule(entity, outputDir, moduleName, logger);
    }

    _cleanupModesDirectory(modesDir, logger);
    _removeCommonDirectories(outputDir, logger);

    logger.info(
      '✅ File reorganization complete. Active modules: ${activeModuleNames.join(", ")}',
    );
  }

  /// Processes an active module directory based on its disposition.
  void _processActiveModule(
    Directory moduleDir,
    Directory outputDir,
    String moduleName,
    Logger logger,
  ) {
    final disposition = _registry.getDisposition(moduleName);
    if (disposition == null) {
      logger.warn(
        'Unknown module disposition for $moduleName, using mergeIntoExisting',
      );
      _mergeDirectoryContents(moduleDir, outputDir, logger);
      return;
    }

    switch (disposition) {
      case ModuleDisposition.moveToRoot:
        _moveDirectoryContents(moduleDir, outputDir, logger);
        break;
      case ModuleDisposition.mergeIntoExisting:
        _mergeDirectoryContents(moduleDir, outputDir, logger);
        break;
      case ModuleDisposition.removeIfInactive:
        logger.warn(
          'Module $moduleName marked as removeIfInactive but is active',
        );
        break;
    }
  }

  /// Cleans up the modes directory if empty.
  void _cleanupModesDirectory(Directory modesDir, Logger logger) {
    try {
      if (modesDir.existsSync() && modesDir.listSync().isEmpty) {
        modesDir.deleteSync(recursive: true);
      }
    } catch (e) {
      logger.warn('Could not remove modes directory: $e');
    }
  }

  /// Remove common/ directories from output (these are template partials, not output files).
  void _removeCommonDirectories(Directory root, Logger logger) {
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
  void _moveDirectoryContents(
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
  void _mergeDirectoryContents(
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

