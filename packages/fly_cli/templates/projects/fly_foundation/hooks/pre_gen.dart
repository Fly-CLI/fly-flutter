import 'package:mason/mason.dart';

import 'plugins/foundation_model.dart';
import 'plugins/hook_orchestrator.dart';
import 'plugins/hook_exception.dart';

void run(HookContext context) {
  try {
    final rawVars = Map<String, dynamic>.from(context.vars);

    // Create base template variables from raw Mason vars
    final base = BaseTemplateVariables.fromVars(rawVars);

    // Plan variable derivation
    final composed = HookOrchestrator.plan(base, context.logger);

    // Add derived variables back to Mason context
    context.vars.addAll(composed.toMasonVars());

    // Select active modules and compute module-specific variables
    final moduleSelection = HookOrchestrator.selectModules(base, composed);

    // Add module metadata and module-specific variables to context
    context.vars.addAll(moduleSelection.moduleVars);
  } on HookException catch (e) {
    context.logger.err(e.toString());
    rethrow;
  } catch (e) {
    context.logger.err('Unexpected error in pre_gen hook: $e');
    rethrow;
  }
}
