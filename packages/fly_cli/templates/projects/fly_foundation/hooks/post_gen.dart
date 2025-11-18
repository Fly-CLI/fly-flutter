import 'dart:io';

import 'package:mason/mason.dart';

import 'plugins/foundation_model.dart';
import 'plugins/hook_orchestrator.dart';
import 'plugins/hook_exception.dart';

/// Post-generation hook that reorganizes files based on active modules.
///
/// This hook:
/// 1. Moves files from `modes/{module}/` to the output root (for project mode)
/// 2. Moves files to appropriate locations (for feature/service modes)
/// 3. Removes files from inactive modules
/// 4. Cleans up the `modes/` directory structure
void run(HookContext context) {
  try {
    final rawVars = Map<String, dynamic>.from(context.vars);

    // Get active modules from context (set by pre_gen)
    final activeModuleNames = <String>[];
    final activeModulesRaw = rawVars['active_modules'] as List<dynamic>?;

    if (activeModulesRaw != null) {
      activeModuleNames.addAll(
        activeModulesRaw.map((name) => name.toString()),
      );
    } else {
      // Fallback: determine from generation mode
      final base = BaseTemplateVariables.fromVars(rawVars);
      switch (base.generationMode) {
        case GenerationMode.project:
          activeModuleNames.add('project');
          break;
        case GenerationMode.feature:
          activeModuleNames.add('feature');
          break;
        case GenerationMode.service:
          activeModuleNames.add('service');
          break;
      }
    }

    // Get the output directory
    final outputDirPath = context.vars['__output_directory__'] as String? ?? '.';
    final outputDir = Directory(outputDirPath);

    // Reorganize files based on active modules
    HookOrchestrator.reorganizeFiles(
      outputDir,
      activeModuleNames,
      context.logger,
    );
  } on HookException catch (e) {
    context.logger.err(e.toString());
    rethrow;
  } catch (e) {
    context.logger.err('Unexpected error in post_gen hook: $e');
    rethrow;
  }
}

