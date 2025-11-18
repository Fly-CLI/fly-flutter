import '../foundation_model.dart';
import 'mode_specific_planner.dart';
import 'cross_cutting_planner.dart';
import 'project_planner.dart';
import 'feature_planner.dart';
import 'service_planner.dart';
import 'naming_planner.dart';
import 'preset_planner.dart';
import 'platform_planner.dart';

/// Factory for creating and managing planners.
///
/// This factory maintains registries of mode-specific and cross-cutting planners,
/// and provides methods to retrieve the appropriate planner for a given mode.
class PlannerFactory {
  /// Registry of mode-specific planners.
  final Map<GenerationMode, ModeSpecificPlanner> _modePlanners;

  /// Registry of cross-cutting planners.
  final List<CrossCuttingPlanner> _crossCuttingPlanners;

  /// Creates a factory with default planners.
  PlannerFactory()
      : _modePlanners = {
          GenerationMode.project: ProjectPlanner(),
          GenerationMode.feature: FeaturePlanner(),
          GenerationMode.service: ServicePlanner(),
        },
        _crossCuttingPlanners = [
          NamingPlanner(),
          PresetPlanner(),
          PlatformPlanner(),
        ];

  /// Creates a factory with custom planners.
  PlannerFactory.custom({
    required Map<GenerationMode, ModeSpecificPlanner> modePlanners,
    required List<CrossCuttingPlanner> crossCuttingPlanners,
  })  : _modePlanners = modePlanners,
        _crossCuttingPlanners = crossCuttingPlanners;

  /// Gets the mode-specific planner for the given mode.
  ModeSpecificPlanner? getModePlanner(GenerationMode mode) {
    return _modePlanners[mode];
  }

  /// Gets all cross-cutting planners.
  List<CrossCuttingPlanner> getCrossCuttingPlanners() {
    return List.unmodifiable(_crossCuttingPlanners);
  }
}

