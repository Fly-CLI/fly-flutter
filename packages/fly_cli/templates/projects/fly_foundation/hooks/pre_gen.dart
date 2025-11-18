import 'package:mason/mason.dart';

import 'plugins/foundation_model.dart';
import 'plugins/planner.dart';
import 'plugins/planners/preset_planner.dart';
import 'plugins/composition.dart';
import 'plugins/variables/feature_variables.dart';
import 'plugins/variables/service_variables.dart';

void run(HookContext context) {
  final rawVars = Map<String, dynamic>.from(context.vars);

  // Create base template variables from raw Mason vars
  var base = BaseTemplateVariables.fromVars(rawVars);

  // Apply preset if specified (consolidated in PresetPlanner)
  base = PresetPlanner.applyPresetToBase(base, context.logger);

  // Run planners to derive variables
  final planner = CompositePlanner();
  final composed = planner.run(base, context.logger);

  // Add derived variables back to Mason context
  context.vars.addAll(composed.toMasonVars());

  // Add module composition information to context
  // Determine active modules based on generation mode
  final activeModules = <TemplateModule>[];
  switch (base.generationMode) {
    case GenerationMode.project:
      activeModules.add(ProjectModule());
      break;
    case GenerationMode.feature:
      activeModules.add(FeatureModule(
        feature: composed.modeSpecific is FeatureVariables
            ? (composed.modeSpecific as FeatureVariables).feature
            : null,
      ));
      break;
    case GenerationMode.service:
      activeModules.add(ServiceModule(
        serviceName: composed.modeSpecific is ServiceVariables
            ? (composed.modeSpecific as ServiceVariables).componentName
            : null,
      ));
      break;
  }

  // Add module metadata
  final moduleVars = <String, dynamic>{
    'active_modules': activeModules.map((m) => m.name).toList(),
    'module_template_paths': activeModules
        .expand((m) => m.templatePaths)
        .toSet()
        .toList(),
  };

  // Add module-specific variables
  final modeVars = composed.toMasonVars();
  for (final module in activeModules) {
    try {
      moduleVars.addAll(module.getModuleVars(modeVars));
    } catch (e) {
      // If module vars fail, continue without them
      context.logger.detail('Could not get vars from module ${module.name}: $e');
    }
  }

  context.vars.addAll(moduleVars);
}
