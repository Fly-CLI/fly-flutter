import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/generation/foundation/foundation_domain/foundation_types.dart';
import 'package:fly_cli/src/generation/utils/mason_variable_keys.dart';

/// Deriver that sets feature-mode-specific variables.
class FeatureModeDeriver implements VariableDeriver {
  const FeatureModeDeriver();

  @override
  String get id => 'feature_mode';

  @override
  bool supports(GenerationContext ctx) => ctx.mode == GenerationMode.feature;

  @override
  VariableBag derive(
    GenerationContext ctx,
    VariableBag current,
    ComposerLogger logger,
  ) {
    final screenTypeStr =
        ctx.rawVars[MasonVarKey.screenType.key] as String? ??
        ctx.rawVars['screen_type'] as String?;
    final screenType = screenTypeStr != null
        ? ScreenType.fromKey(screenTypeStr)
        : ScreenType.list;

    final withValidation =
        ctx.rawVars[MasonVarKey.withValidation.key] as bool? ??
        ctx.rawVars['with_validation'] as bool? ??
        false;

    final withNavigation =
        ctx.rawVars[MasonVarKey.withNavigation.key] as bool? ??
        ctx.rawVars['with_navigation'] as bool? ??
        false;

    final stateMgmtStr =
        ctx.rawVars[MasonVarKey.stateMgmt.key] as String? ??
        ctx.rawVars['state_mgmt'] as String?;
    final stateMgmt = stateMgmtStr != null
        ? StateManagement.fromKey(stateMgmtStr)
        : StateManagement.riverpod;

    final name =
        ctx.rawVars[MasonVarKey.name.key] as String? ??
        ctx.rawVars['name'] as String? ??
        'unnamed';
    final snakeName = NamingUtils.toSnakeCase(name);

    // Get feature from input vars or current bag, defaulting to 'core' if not provided
    final feature =
        ctx.rawVars[MasonVarKey.feature.key] as String? ??
        ctx.rawVars['feature'] as String? ??
        current.get<String>(MasonVarKey.feature.key) ??
        'core';

    final isFormScreen =
        screenType == ScreenType.form || screenType == ScreenType.auth;
    final requiresValidation = withValidation || isFormScreen;

    return current.setAll({
      MasonVarKey.isFeature.key: true,
      MasonVarKey.screenType.key: screenType.key,
      MasonVarKey.isListScreen.key: screenType == ScreenType.list,
      MasonVarKey.isDetailScreen.key: screenType == ScreenType.detail,
      MasonVarKey.isFormScreen.key: isFormScreen,
      MasonVarKey.requiresValidation.key: requiresValidation,
      MasonVarKey.withNavigation.key: withNavigation,
      MasonVarKey.useRiverpod.key: stateMgmt == StateManagement.riverpod,
      MasonVarKey.useBloc.key: stateMgmt == StateManagement.bloc,
      MasonVarKey.useCubit.key: stateMgmt == StateManagement.cubit,
      MasonVarKey.feature.key: feature,
      MasonVarKey.componentName.key: snakeName,
    });
  }
}
