import 'package:fly_foundation_planning/fly_foundation_planning.dart';

/// Deriver that sets preset-based configuration (flyPackages).
class PresetDeriver implements VariableDeriver {
  const PresetDeriver();

  @override
  String get id => 'preset_shared';

  @override
  bool supports(GenerationContext ctx) => true; // Always run

  @override
  VariableBag derive(
    GenerationContext ctx,
    VariableBag current,
    PlanningLogger logger,
  ) {
    // Get the active preset (defaults to starter if not specified)
    FoundationPreset preset;
    try {
      preset = FoundationPreset.fromVars(ctx.rawVars);
    } catch (e) {
      logger.warn('Failed to parse preset: $e. Using default (starter).');
      preset = FoundationPreset.starter;
    }

    return current.set(MasonVarKey.flyPackages.key, preset.flyPackages);
  }
}

