import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/generation/foundation/foundation_domain/foundation_presets.dart';
import 'package:fly_cli/src/generation/utils/mason_variable_keys.dart';

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
    ComposerLogger logger,
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

