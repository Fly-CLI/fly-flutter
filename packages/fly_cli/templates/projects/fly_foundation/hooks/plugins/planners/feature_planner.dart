import 'package:mason/mason.dart';
import '../foundation_model.dart';
import '../naming_utils.dart';
import '../variables/mode_specific_variables.dart';
import '../variables/feature_variables.dart';
import 'mode_specific_planner.dart';

/// Planner that derives feature-specific variables.
class FeaturePlanner implements ModeSpecificPlanner {
  @override
  GenerationMode get supportedMode => GenerationMode.feature;

  @override
  FeatureVariables derive(
    BaseTemplateVariables base,
    Logger logger,
  ) {
    final screenType = base.screenType ?? ScreenType.list;
    final withValidation = base.featureValidation;
    final withNavigation = base.featureNavigation;
    final stateMgmt = base.stateManagement;
    final snakeName = NamingUtils.toSnakeCase(base.name);

    final isFormScreen =
        screenType == ScreenType.form || screenType == ScreenType.auth;
    final requiresValidation = withValidation || isFormScreen;

    return FeatureVariables(
      isFeature: true,
      screenType: screenType,
      isListScreen: screenType == ScreenType.list,
      isDetailScreen: screenType == ScreenType.detail,
      isFormScreen: isFormScreen,
      requiresValidation: requiresValidation,
      withNavigation: withNavigation,
      useRiverpod: stateMgmt == StateManagement.riverpod,
      useBloc: stateMgmt == StateManagement.bloc,
      useCubit: stateMgmt == StateManagement.cubit,
      feature: snakeName,
      componentName: snakeName,
    );
  }
}

