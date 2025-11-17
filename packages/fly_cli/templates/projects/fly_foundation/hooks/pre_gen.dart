import 'package:mason/mason.dart';

import 'plugins/mason_variable_keys.dart';
import 'plugins/foundation_model.dart';
import 'plugins/planner.dart';
import 'plugins/preset_mode.dart';
import 'plugins/presets.dart';
import 'plugins/composition_planner.dart';

void run(HookContext context) {
  final rawVars = Map<String, dynamic>.from(context.vars);

  // Create base template variables from raw Mason vars
  var base = BaseTemplateVariables.fromVars(rawVars);

  // Apply preset if specified
  if (base.preset != null) {
    try {
      final preset =
          FoundationPreset.fromVars({MasonVarKey.preset.key: base.preset});
      base = preset.applyTo(base);
    } catch (e) {
      context.logger.err('Failed to apply preset: $e');
      // Continue with original base if preset fails
    }
  }

  // Run planners to derive variables
  final planner = CompositePlanner([
    // Core planners that derive internal vars from public schema
    PresetPlanner(),
    CoreVarsPlanner(),
    // Composition planner replaces mode-specific planners
    // It handles module composition and maintains backward compatibility
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
