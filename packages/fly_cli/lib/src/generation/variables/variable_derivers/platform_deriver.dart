import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/generation/utils/mason_variable_keys.dart';

/// Deriver that sets platform support flags based on platforms in raw vars.
class PlatformDeriver implements VariableDeriver {
  const PlatformDeriver();

  @override
  String get id => 'platform';

  @override
  bool supports(GenerationContext ctx) => true; // Always run

  @override
  VariableBag derive(
    GenerationContext ctx,
    VariableBag current,
    ComposerLogger logger,
  ) {
    final platformsRaw =
        ctx.rawVars[BaseVarKey.platforms.key] as List? ??
        ctx.rawVars['platforms'] as List? ??
        ['ios', 'android'];

    final platforms = PlatformType.fromVars(ctx.rawVars);

    // Convert platform types to string list
    final platformKeys = platforms.map((p) => p.key).toList();

    final desktopPlatforms = {
      PlatformType.macos.key,
      PlatformType.windows.key,
      PlatformType.linux.key,
    };

    final platformKeysSet = platformKeys.toSet();
    final supportsDesktop = platformKeysSet
        .intersection(desktopPlatforms)
        .isNotEmpty;

    return current.setAll({
      BaseVarKey.platforms.key: platformKeys, // Set platforms field itself
      BaseVarKey.supportsIos.key: platforms.contains(PlatformType.ios),
      BaseVarKey.supportsAndroid.key: platforms.contains(PlatformType.android),
      BaseVarKey.supportsWeb.key: platforms.contains(PlatformType.web),
      BaseVarKey.supportsMacos.key: platforms.contains(PlatformType.macos),
      BaseVarKey.supportsWindows.key: platforms.contains(PlatformType.windows),
      BaseVarKey.supportsLinux.key: platforms.contains(PlatformType.linux),
      BaseVarKey.supportsDesktop.key: supportsDesktop,
    });
  }
}
