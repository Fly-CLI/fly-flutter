import 'package:mason/mason.dart';

import 'plugins/planner.dart';
import 'plugins/preset_mode.dart';
import 'plugins/project_mode.dart';
import 'plugins/feature_mode.dart';
import 'plugins/service_mode.dart';

void run(HookContext context) {
  final vars = Map<String, dynamic>.from(context.vars);
  final planner = CompositePlanner([
    // Core planners that derive internal vars from public schema
    PresetPlanner(),
    CoreVarsPlanner(),
    // Mode-specific planners that depend on derived vars
    ProjectModePlanner(),
    FeatureModePlanner(),
    ServiceModePlanner(),
  ]);
  final derived = planner.run(vars, context.logger);
  context.vars.addAll(derived);
}


