import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/core/templates/foundation/foundation_domain/foundation_types.dart'
    show ScreenType, ServiceType, StateManagement, FoundationVars;
import 'package:fly_cli/src/core/templates/utils/mason_variable_keys.dart';

/// Foundation-specific template variables representing all input variables.
///
/// This class extends the core planning concepts with Fly foundation-specific
/// configuration including presets, state management, screen/service types, etc.
class FoundationTemplateVariables {
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

  /// Creates [FoundationTemplateVariables] from a Mason variables map using MasonVarKey.
  factory FoundationTemplateVariables.fromVars(FoundationVars vars) {
    final name = vars.getVar<String>(MasonVarKey.name) ?? 'unnamed';
    final organization =
        vars.getVar<String>(MasonVarKey.organization) ?? 'com.example';
    final generationMode = GenerationMode.fromVars(vars);
    final platforms = PlatformType.fromVars(vars);

    return FoundationTemplateVariables(
      name: name,
      organization: organization,
      generationMode: generationMode,
      platforms: platforms,
      description: vars.getVar<String>(MasonVarKey.description) ??
          'A new Fly foundation project',
      templateVariant:
          vars.getVar<String>(MasonVarKey.templateVariant) ?? 'foundation',
      minFlutterSdk: vars.getVar<String>(MasonVarKey.minFlutterSdk) ?? '3.10.0',
      minDartSdk: vars.getVar<String>(MasonVarKey.minDartSdk) ?? '3.0.0',
      withTests: vars.getVar<bool>(MasonVarKey.withTests) ?? true,
      withDocs: vars.getVar<bool>(MasonVarKey.withDocs) ?? true,
      withMcp: vars.getVar<bool>(MasonVarKey.withMcp) ?? true,
      codeGeneration: vars.getVar<bool>(MasonVarKey.codeGeneration) ?? true,
      aiIntegration: vars.getVar<bool>(MasonVarKey.aiIntegration) ?? true,
      serviceRetry: vars.getVar<bool>(MasonVarKey.withRetryLogic) ?? false,
      serviceCaching: vars.getVar<bool>(MasonVarKey.withCaching) ?? false,
      serviceInterceptors:
          vars.getVar<bool>(MasonVarKey.withInterceptors) ?? false,
      serviceMocks: vars.getVar<bool>(MasonVarKey.withMocks) ?? false,
      featureViewModel: vars.getVar<bool>(MasonVarKey.withViewModel) ?? true,
      featureValidation: vars.getVar<bool>(MasonVarKey.withValidation) ?? false,
      featureNavigation: vars.getVar<bool>(MasonVarKey.withNavigation) ?? false,
      stateManagement: StateManagement.fromVars(vars),
      screenType: ScreenType.fromVars(vars),
      serviceType: ServiceType.fromVars(vars),
      apiBaseUrl: vars.getVar<String>(MasonVarKey.apiBaseUrl),
      preset: vars.getVar<String>(MasonVarKey.preset),
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

