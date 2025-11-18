import 'package:mason/mason.dart';

import 'plugins/foundation_model.dart';
import 'plugins/planner.dart';
import 'plugins/naming_planner.dart';
import 'plugins/preset_planner.dart';
import 'plugins/composition_planner.dart';

void run(HookContext context) {
  final rawVars = Map<String, dynamic>.from(context.vars);

  // Create base template variables from raw Mason vars
  var base = BaseTemplateVariables.fromVars(rawVars);

  // Apply preset if specified (consolidated in PresetPlanner)
  base = PresetPlanner.applyPresetToBase(base, context.logger);

  // Run planners to derive variables
  final planner = CompositePlanner([
    // NamingPlanner handles mode-based naming logic
    NamingPlanner(),
    // PresetPlanner handles preset-based configuration (e.g., fly packages)
    PresetPlanner(),
    // CompositionPlanner handles module composition and mode flags
    CompositionPlanner(),
  ]);

  final derived = planner.run(base, context.logger);

  // Add derived variables back to Mason context
  context.vars.addAll(derived.toMasonVars());

  // Add module composition information to context
  final compositionPlanner = CompositionPlanner();
  final moduleVars = compositionPlanner.getModuleVariables(base, derived);
  context.vars.addAll(moduleVars);
}
