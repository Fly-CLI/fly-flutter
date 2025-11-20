import 'package:fly_foundation_planning/fly_foundation_planning.dart';
import 'package:fly_cli/src/core/templates/mason_variable_keys.dart';

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
    PlanningLogger logger,
  ) {
    final platformsRaw = ctx.rawVars[MasonVarKey.platforms.key] as List? ??
        ctx.rawVars['platforms'] as List? ??
        ['ios', 'android'];

    final platforms = PlatformType.fromVars(ctx.rawVars);

    final desktopPlatforms = {
      PlatformType.macos.key,
      PlatformType.windows.key,
      PlatformType.linux.key,
    };

    final platformKeys = platforms.map((p) => p.key).toSet();
    final supportsDesktop =
        platformKeys.intersection(desktopPlatforms).isNotEmpty;

    return current.setAll({
      MasonVarKey.supportsIos.key: platforms.contains(PlatformType.ios),
      MasonVarKey.supportsAndroid.key: platforms.contains(PlatformType.android),
      MasonVarKey.supportsWeb.key: platforms.contains(PlatformType.web),
      MasonVarKey.supportsMacos.key: platforms.contains(PlatformType.macos),
      MasonVarKey.supportsWindows.key: platforms.contains(PlatformType.windows),
      MasonVarKey.supportsLinux.key: platforms.contains(PlatformType.linux),
      MasonVarKey.supportsDesktop.key: supportsDesktop,
    });
  }
}

