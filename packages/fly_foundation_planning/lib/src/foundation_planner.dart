import 'package:fly_foundation_planning/src/foundation_model.dart';
import 'package:fly_foundation_planning/src/logger.dart';
import 'package:fly_foundation_planning/src/module_invocation.dart';
import 'package:fly_foundation_planning/src/planner.dart';
import 'package:fly_foundation_planning/src/variables/composed_derived_variables.dart';

/// Main entry point for planning Fly foundation generation.
///
/// This class provides a clean API for the CLI to:
/// 1. Plan variable derivation from raw user input
/// 2. Determine which module bricks should be executed
/// 3. Get the variables to pass to each brick
class FoundationPlanner {
  final CompositePlanner _planner;
  final PlanningLogger _logger;

  /// Creates a foundation planner with default configuration.
  FoundationPlanner({
    CompositePlanner? planner,
    PlanningLogger? logger,
  })  : _planner = planner ?? CompositePlanner(),
        _logger = logger ?? const NoOpLogger();

  /// Plans foundation generation from raw user input variables.
  ///
  /// Returns a [PlanningResult] containing:
  /// - Derived variables ready for template rendering
  /// - List of module invocations that should be executed
  PlanningResult planFoundationGeneration(Map<String, dynamic> rawVars) {
    // Convert raw vars to base template variables
    final base = BaseTemplateVariables.fromVars(rawVars);

    // Run the planner to derive composed variables
    final composed = _planner.run(base, _logger);

    // Determine which modules should be active
    final moduleInvocations = _determineModuleInvocations(base, composed);

    return PlanningResult(
      derivedVars: composed.toMasonVars(),
      moduleInvocations: moduleInvocations,
    );
  }

  /// Determines which module bricks should be executed based on generation mode.
  List<ModuleInvocation> _determineModuleInvocations(
    BaseTemplateVariables base,
    ComposedDerivedVariables composed,
  ) {
    final invocations = <ModuleInvocation>[];

    // Map generation mode to module brick
    final brickId = getBrickIdForMode(base.generationMode);
    final moduleName = base.generationMode.key;

    // Create the variables map for this module
    final vars = composed.toMasonVars();
    // Add base variables that might not be in derived vars
    vars['name'] = base.name;
    vars['organization'] = base.organization;
    vars['description'] = base.description;
    vars['generation_mode'] = base.generationMode.key;

    invocations.add(ModuleInvocation(
      moduleName: moduleName,
      brickId: brickId,
      vars: vars,
    ));

    return invocations;
  }
}

/// Result of planning foundation generation.
class PlanningResult {
  const PlanningResult({
    required this.derivedVars,
    required this.moduleInvocations,
  });

  /// Derived variables ready for template rendering.
  final Map<String, dynamic> derivedVars;

  /// List of module invocations that should be executed.
  final List<ModuleInvocation> moduleInvocations;
}

