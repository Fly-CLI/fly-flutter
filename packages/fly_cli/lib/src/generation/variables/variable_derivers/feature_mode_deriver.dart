import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/generation/utils/mason_variable_keys.dart';

/// Deriver that sets feature-mode-specific variables.
class FeatureModeDeriver implements VariableDeriver {
  /// Creates a new [FeatureModeDeriver].
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
        ctx.rawVars[FeatureVarKey.screenType.key] as String? ??
        ctx.rawVars['screen_type'] as String?;
    final screenType = screenTypeStr != null
        ? ScreenType.fromKey(screenTypeStr)
        : ScreenType.list;

    final withValidation =
        ctx.rawVars[FeatureVarKey.withValidation.key] as bool? ??
        ctx.rawVars['with_validation'] as bool? ??
        false;

    final withNavigation =
        ctx.rawVars[FeatureVarKey.withNavigation.key] as bool? ??
        ctx.rawVars['with_navigation'] as bool? ??
        false;

    final stateMgmtStr =
        ctx.rawVars[BaseVarKey.stateMgmt.key] as String? ??
        ctx.rawVars['state_mgmt'] as String?;
    final stateMgmt = stateMgmtStr != null
        ? StateManagement.fromKey(stateMgmtStr)
        : StateManagement.riverpod;

    final name =
        ctx.rawVars[BaseVarKey.name.key] as String? ??
        ctx.rawVars['name'] as String? ??
        'unnamed';
    final snakeName = NamingUtils.toSnakeCase(name);

    // Get feature from input vars or current bag, defaulting to 'core' if not provided
    final feature =
        ctx.rawVars[BaseVarKey.feature.key] as String? ??
        ctx.rawVars['feature'] as String? ??
        current.get<String>(BaseVarKey.feature.key) ??
        'core';

    final isFormScreen =
        screenType == ScreenType.form || screenType == ScreenType.auth;
    final requiresValidation = withValidation || isFormScreen;

    return current.setAll({
      FeatureVarKey.screenType.key: screenType.key,
      FeatureVarKey.isListScreen.key: screenType == ScreenType.list,
      FeatureVarKey.isDetailScreen.key: screenType == ScreenType.detail,
      FeatureVarKey.isFormScreen.key: isFormScreen,
      FeatureVarKey.requiresValidation.key: requiresValidation,
      FeatureVarKey.withNavigation.key: withNavigation,
      FeatureVarKey.useRiverpod.key: stateMgmt == StateManagement.riverpod,
      FeatureVarKey.useBloc.key: stateMgmt == StateManagement.bloc,
      FeatureVarKey.useCubit.key: stateMgmt == StateManagement.cubit,
      BaseVarKey.feature.key: feature,
      BaseVarKey.componentName.key: snakeName,
    });
  }
}
