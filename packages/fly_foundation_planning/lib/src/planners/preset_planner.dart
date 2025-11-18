import '../mason_variable_keys.dart';
import '../foundation_model.dart';
import '../presets.dart';
import '../variables/shared_derived_variables.dart';
import '../logger.dart';
import 'cross_cutting_planner.dart';

/// Planner that handles all preset-related logic.
///
/// This planner consolidates preset application and configuration:
/// - Applies preset configuration to base variables (via static method)
/// - Applies preset-based configuration to derived variables (via derive method)
///
/// This separates preset-based configuration from mode-based logic.
class PresetPlanner implements CrossCuttingPlanner {
  /// Applies preset configuration to base template variables.
  ///
  /// If a preset is specified in [base], it will be applied.
  /// If preset application fails, returns the original [base] unchanged.
  ///
  /// Returns the base variables with preset configuration applied.
  static BaseTemplateVariables applyPresetToBase(
    BaseTemplateVariables base,
    PlanningLogger logger,
  ) {
    if (base.preset == null || base.preset!.isEmpty) {
      return base;
    }

    try {
      final preset = FoundationPreset.fromVars(
        {MasonVarKey.preset.key: base.preset},
      );
      return preset.applyTo(base);
    } catch (e) {
      logger.err('Failed to apply preset: $e');
      // Continue with original base if preset fails
      return base;
    }
  }

  @override
  bool canHandle(BaseTemplateVariables base) {
    // Preset configuration is global, so this planner always handles
    return true;
  }

  @override
  SharedDerivedVariables derive(
    BaseTemplateVariables base,
    SharedDerivedVariables acc,
    PlanningLogger logger,
  ) {
    // Get the active preset (defaults to starter if not specified)
    final preset = base.preset != null && base.preset!.isNotEmpty
        ? FoundationPreset.fromVars({MasonVarKey.preset.key: base.preset})
        : FoundationPreset.starter;

    // Apply preset-based configuration to derived variables
    return acc.copyWith(
      flyPackages: preset.flyPackages,
    );
  }
}

