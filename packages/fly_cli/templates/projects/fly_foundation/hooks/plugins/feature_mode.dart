import 'package:mason/mason.dart';

import 'foundation_model.dart';
import 'planner.dart';

class FeatureModePlanner implements PlannerPlugin {
  @override
  bool canHandle(BaseTemplateVariables base) {
    return base.generationMode == GenerationMode.feature;
  }

  @override
  DerivedTemplateVariables derive(
    BaseTemplateVariables base,
    DerivedTemplateVariables acc,
    Logger logger,
  ) {
    final screenType = base.screenType ?? ScreenType.list;
    final withValidation = base.featureValidation;
    final withNavigation = base.featureNavigation;
    final stateMgmt = base.stateManagement;

    final isFormScreen =
        screenType == ScreenType.form || screenType == ScreenType.auth;
    final requiresValidation = withValidation || isFormScreen;

    return DerivedTemplateVariables(
      isProject: false,
      isFeature: true,
      isService: false,
      activeMode: GenerationMode.feature,
      screenType: screenType,
      isListScreen: screenType == ScreenType.list,
      isDetailScreen: screenType == ScreenType.detail,
      isFormScreen: isFormScreen,
      requiresValidation: requiresValidation,
      withNavigation: withNavigation,
      useRiverpod: stateMgmt == StateManagement.riverpod,
      useBloc: stateMgmt == StateManagement.bloc,
      useCubit: stateMgmt == StateManagement.cubit,
    );
  }
}
