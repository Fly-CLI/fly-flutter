import 'mode_specific_variables.dart';
import '../foundation_model.dart';
import '../mason_variable_keys.dart';

/// Feature-specific derived variables.
final class FeatureVariables extends ModeSpecificVariables {
  const FeatureVariables({
    this.isFeature = true,
    this.screenType,
    this.isListScreen = false,
    this.isDetailScreen = false,
    this.isFormScreen = false,
    this.requiresValidation = false,
    this.withNavigation = false,
    this.useRiverpod = false,
    this.useBloc = false,
    this.useCubit = false,
    this.feature,
    this.componentName,
  });

  final bool isFeature;
  final ScreenType? screenType;
  final bool isListScreen;
  final bool isDetailScreen;
  final bool isFormScreen;
  final bool requiresValidation;
  final bool withNavigation;
  final bool useRiverpod;
  final bool useBloc;
  final bool useCubit;
  final String? feature;
  final String? componentName;

  @override
  GenerationMode get mode => GenerationMode.feature;

  @override
  Map<String, dynamic> toMasonVars() {
    final result = <String, dynamic>{
      MasonVarKey.isFeature.key: isFeature,
      MasonVarKey.isListScreen.key: isListScreen,
      MasonVarKey.isDetailScreen.key: isDetailScreen,
      MasonVarKey.isFormScreen.key: isFormScreen,
      MasonVarKey.requiresValidation.key: requiresValidation,
      MasonVarKey.withNavigation.key: withNavigation,
      MasonVarKey.useRiverpod.key: useRiverpod,
      MasonVarKey.useBloc.key: useBloc,
      MasonVarKey.useCubit.key: useCubit,
    };

    if (screenType != null) {
      result[MasonVarKey.screenType.key] = screenType!.key;
    }
    if (feature != null) {
      result[MasonVarKey.feature.key] = feature;
    }
    if (componentName != null) {
      result[MasonVarKey.componentName.key] = componentName;
    }

    return result;
  }

  /// Creates a copy with updated fields.
  FeatureVariables copyWith({
    bool? isFeature,
    ScreenType? screenType,
    bool? isListScreen,
    bool? isDetailScreen,
    bool? isFormScreen,
    bool? requiresValidation,
    bool? withNavigation,
    bool? useRiverpod,
    bool? useBloc,
    bool? useCubit,
    String? feature,
    String? componentName,
  }) {
    return FeatureVariables(
      isFeature: isFeature ?? this.isFeature,
      screenType: screenType ?? this.screenType,
      isListScreen: isListScreen ?? this.isListScreen,
      isDetailScreen: isDetailScreen ?? this.isDetailScreen,
      isFormScreen: isFormScreen ?? this.isFormScreen,
      requiresValidation: requiresValidation ?? this.requiresValidation,
      withNavigation: withNavigation ?? this.withNavigation,
      useRiverpod: useRiverpod ?? this.useRiverpod,
      useBloc: useBloc ?? this.useBloc,
      useCubit: useCubit ?? this.useCubit,
      feature: feature ?? this.feature,
      componentName: componentName ?? this.componentName,
    );
  }
}

