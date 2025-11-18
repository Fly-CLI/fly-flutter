import 'package:mason/mason.dart';

import 'foundation_model.dart';
import 'variables/shared_derived_variables.dart';
import 'variables/composed_derived_variables.dart';
import 'planners/planner_factory.dart';
import 'planners/mode_specific_planner.dart';
import 'planners/cross_cutting_planner.dart';

/// Composite planner that orchestrates variable derivation.
///
/// This planner:
/// 1. Runs all applicable cross-cutting planners to build SharedDerivedVariables
/// 2. Selects and runs the appropriate mode-specific planner
/// 3. Composes SharedDerivedVariables + ModeSpecificVariables into ComposedDerivedVariables
class CompositePlanner {
  final PlannerFactory _factory;

  /// Creates a composite planner with default factory.
  CompositePlanner() : _factory = PlannerFactory();

  /// Creates a composite planner with custom factory.
  CompositePlanner.custom(PlannerFactory factory) : _factory = factory;

  /// Runs the planner system to derive composed variables.
  ComposedDerivedVariables run(
    BaseTemplateVariables base,
    Logger logger,
  ) {
    // Step 1: Run cross-cutting planners to build shared variables
    var shared = SharedDerivedVariables.empty().copyWith(
      activeMode: base.generationMode,
    );

    for (final planner in _factory.getCrossCuttingPlanners()) {
      if (planner.canHandle(base)) {
        shared = planner.derive(base, shared, logger);
      }
    }

    // Step 2: Run mode-specific planner
    final modePlanner = _factory.getModePlanner(base.generationMode);
    if (modePlanner == null) {
      throw Exception(
        'No planner found for generation mode: ${base.generationMode.key}',
      );
    }

    final modeSpecific = modePlanner.derive(base, logger);

    // Step 3: Compose and return
    return ComposedDerivedVariables(
      shared: shared,
      modeSpecific: modeSpecific,
    );
  }
}

