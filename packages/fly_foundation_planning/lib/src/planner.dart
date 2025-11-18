import 'package:fly_foundation_planning/src/foundation_model.dart';
import 'package:fly_foundation_planning/src/logger.dart';
import 'package:fly_foundation_planning/src/planners/planner_factory.dart';
import 'package:fly_foundation_planning/src/planners/preset_planner.dart';
import 'package:fly_foundation_planning/src/planning_exception.dart';
import 'package:fly_foundation_planning/src/variables/composed_derived_variables.dart';
import 'package:fly_foundation_planning/src/variables/shared_derived_variables.dart';

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
  ///
  /// Throws [PlanningException] if no planner is found for the generation mode
  /// or if any planner encounters a validation error.
  ComposedDerivedVariables run(
    BaseTemplateVariables base,
    PlanningLogger logger,
  ) {
    // Step 1: Apply preset if specified
    final baseWithPreset = PresetPlanner.applyPresetToBase(base, logger);

    // Step 2: Run cross-cutting planners to build shared variables
    var shared = SharedDerivedVariables.empty().copyWith(
      activeMode: baseWithPreset.generationMode,
    );

    for (final planner in _factory.getCrossCuttingPlanners()) {
      if (planner.canHandle(baseWithPreset)) {
        shared = planner.derive(baseWithPreset, shared, logger);
      }
    }

    // Step 3: Run mode-specific planner
    final modePlanner = _factory.getModePlanner(baseWithPreset.generationMode);
    if (modePlanner == null) {
      throw PlanningException(
        'No planner found for generation mode: ${baseWithPreset.generationMode.key}. '
        'Supported modes: ${GenerationMode.values.map((m) => m.key).join(", ")}.',
      );
    }

    final modeSpecific = modePlanner.derive(baseWithPreset, logger);

    // Step 4: Compose and return
    return ComposedDerivedVariables(
      shared: shared,
      modeSpecific: modeSpecific,
    );
  }
}
