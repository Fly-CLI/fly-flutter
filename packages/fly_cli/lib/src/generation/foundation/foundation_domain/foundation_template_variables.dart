import 'package:fly_cli/src/generation/foundation/foundation_domain/foundation_types.dart'
    show FoundationVars, ScreenType, ServiceType, StateManagement;
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/generation/utils/mason_variable_keys.dart';

/// Foundation-specific template variables representing all input variables.
///
/// This class extends the core planning concepts with Fly foundation-specific
/// configuration including presets, state management, screen/service types, etc.
class FoundationTemplateVariables {
  /// Creates a new instance of [FoundationTemplateVariables].
  const FoundationTemplateVariables({
    required this.name,
    required this.organization,
    required this.generationMode,
    required this.platforms,
    this.description = '',
    this.templateVariant = 'foundation',
    this.minFlutterSdk = '3.10.0',
    this.minDartSdk = '3.0.0',
    this.withTests = true,
    this.withDocs = true,
    this.withMcp = true,
    this.codeGeneration = true,
    this.aiIntegration = true,
    this.serviceRetry = false,
    this.serviceCaching = false,
    this.serviceInterceptors = false,
    this.serviceMocks = false,
    this.featureViewModel = true,
    this.featureValidation = false,
    this.featureNavigation = false,
    this.stateManagement = StateManagement.riverpod,
    this.screenType,
    this.serviceType,
    this.apiBaseUrl,
    this.preset,
  });

  final String name;
  final String organization;
  final GenerationMode generationMode;
  final List<PlatformType> platforms;
  final String description;
  final String templateVariant;
  final String minFlutterSdk;
  final String minDartSdk;
  final bool withTests;
  final bool withDocs;
  final bool withMcp;
  final bool codeGeneration;
  final bool aiIntegration;
  final bool serviceRetry;
  final bool serviceCaching;
  final bool serviceInterceptors;
  final bool serviceMocks;
  final bool featureViewModel;
  final bool featureValidation;
  final bool featureNavigation;
  final StateManagement stateManagement;
  final ScreenType? screenType;
  final ServiceType? serviceType;
  final String? apiBaseUrl;
  final String? preset;

  /// Creates [FoundationTemplateVariables] from a Mason variables map using specialized enums.
  factory FoundationTemplateVariables.fromVars(FoundationVars vars) {
    final name = vars.getVar<String>(BaseVarKey.name) ?? 'unnamed';
    final organization =
        vars.getVar<String>(BaseVarKey.organization) ?? 'com.example';
    final generationMode = GenerationMode.fromVars(vars);
    final platforms = PlatformType.fromVars(vars);

    return FoundationTemplateVariables(
      name: name,
      organization: organization,
      generationMode: generationMode,
      platforms: platforms,
      description:
          vars.getVar<String>(BaseVarKey.description) ??
          'A new Fly foundation project',
      templateVariant:
          vars.getVar<String>(BaseVarKey.templateVariant) ?? 'foundation',
      minFlutterSdk: vars.getVar<String>(BaseVarKey.minFlutterSdk) ?? '3.10.0',
      minDartSdk: vars.getVar<String>(BaseVarKey.minDartSdk) ?? '3.0.0',
      withTests: vars.getVar<bool>(BaseVarKey.withTests) ?? true,
      withDocs: vars.getVar<bool>(BaseVarKey.withDocs) ?? true,
      withMcp: vars.getVar<bool>(BaseVarKey.withMcp) ?? true,
      codeGeneration: vars.getVar<bool>(BaseVarKey.codeGeneration) ?? true,
      aiIntegration: vars.getVar<bool>(BaseVarKey.aiIntegration) ?? true,
      serviceRetry: vars.getVar<bool>(ServiceVarKey.withRetryLogic) ?? false,
      serviceCaching: vars.getVar<bool>(ServiceVarKey.withCaching) ?? false,
      serviceInterceptors:
          vars.getVar<bool>(ServiceVarKey.withInterceptors) ?? false,
      serviceMocks: vars.getVar<bool>(ServiceVarKey.withMocks) ?? false,
      featureViewModel: vars.getVar<bool>(FeatureVarKey.withViewModel) ?? true,
      featureValidation:
          vars.getVar<bool>(FeatureVarKey.withValidation) ?? false,
      featureNavigation:
          vars.getVar<bool>(FeatureVarKey.withNavigation) ?? false,
      stateManagement: StateManagement.fromVars(vars),
      screenType: ScreenType.fromVars(vars),
      serviceType: ServiceType.fromVars(vars),
      apiBaseUrl: vars.getVar<String>(ServiceVarKey.apiBaseUrl),
      preset: vars.getVar<String>(ProjectVarKey.preset),
    );
  }

  /// Creates a copy with updated fields.
  ///
  /// Returns a new instance with the specified fields updated, keeping others unchanged.
  FoundationTemplateVariables copyWith({
    String? name,
    String? organization,
    GenerationMode? generationMode,
    List<PlatformType>? platforms,
    String? description,
    String? templateVariant,
    String? minFlutterSdk,
    String? minDartSdk,
    bool? withTests,
    bool? withDocs,
    bool? withMcp,
    bool? codeGeneration,
    bool? aiIntegration,
    bool? serviceRetry,
    bool? serviceCaching,
    bool? serviceInterceptors,
    bool? serviceMocks,
    bool? featureViewModel,
    bool? featureValidation,
    bool? featureNavigation,
    StateManagement? stateManagement,
    ScreenType? screenType,
    ServiceType? serviceType,
    String? apiBaseUrl,
    String? preset,
  }) {
    return FoundationTemplateVariables(
      name: name ?? this.name,
      organization: organization ?? this.organization,
      generationMode: generationMode ?? this.generationMode,
      platforms: platforms ?? this.platforms,
      description: description ?? this.description,
      templateVariant: templateVariant ?? this.templateVariant,
      minFlutterSdk: minFlutterSdk ?? this.minFlutterSdk,
      minDartSdk: minDartSdk ?? this.minDartSdk,
      withTests: withTests ?? this.withTests,
      withDocs: withDocs ?? this.withDocs,
      withMcp: withMcp ?? this.withMcp,
      codeGeneration: codeGeneration ?? this.codeGeneration,
      aiIntegration: aiIntegration ?? this.aiIntegration,
      serviceRetry: serviceRetry ?? this.serviceRetry,
      serviceCaching: serviceCaching ?? this.serviceCaching,
      serviceInterceptors: serviceInterceptors ?? this.serviceInterceptors,
      serviceMocks: serviceMocks ?? this.serviceMocks,
      featureViewModel: featureViewModel ?? this.featureViewModel,
      featureValidation: featureValidation ?? this.featureValidation,
      featureNavigation: featureNavigation ?? this.featureNavigation,
      stateManagement: stateManagement ?? this.stateManagement,
      screenType: screenType ?? this.screenType,
      serviceType: serviceType ?? this.serviceType,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      preset: preset ?? this.preset,
    );
  }
}
