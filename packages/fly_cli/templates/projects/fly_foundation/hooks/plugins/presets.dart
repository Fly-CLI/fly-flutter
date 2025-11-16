import 'package:mason/mason.dart';
import 'mason_variable_keys.dart';

import 'foundation_model.dart';
import 'hook_exception.dart';

/// Foundation preset enum with configuration for each preset.
enum FoundationPreset {
  starter(
    withTests: true,
    withDocs: true,
    withMcp: true,
    codeGeneration: true,
    aiIntegration: true,
    serviceRetry: false,
    serviceCaching: false,
    serviceInterceptors: false,
    serviceMocks: true,
    featureViewModel: true,
    featureValidation: false,
    featureNavigation: true,
    stateMgmt: StateManagement.riverpod,
  ),
  batteriesIncluded(
    withTests: true,
    withDocs: true,
    withMcp: true,
    codeGeneration: true,
    aiIntegration: true,
    serviceRetry: true,
    serviceCaching: true,
    serviceInterceptors: true,
    serviceMocks: true,
    featureViewModel: true,
    featureValidation: true,
    featureNavigation: true,
    stateMgmt: StateManagement.riverpod,
  ),
  minimal(
    withTests: false,
    withDocs: false,
    withMcp: false,
    codeGeneration: true,
    aiIntegration: false,
    serviceRetry: false,
    serviceCaching: false,
    serviceInterceptors: false,
    serviceMocks: false,
    featureViewModel: true,
    featureValidation: false,
    featureNavigation: false,
    stateMgmt: StateManagement.riverpod,
  );

  const FoundationPreset({
    required this.withTests,
    required this.withDocs,
    required this.withMcp,
    required this.codeGeneration,
    required this.aiIntegration,
    required this.serviceRetry,
    required this.serviceCaching,
    required this.serviceInterceptors,
    required this.serviceMocks,
    required this.featureViewModel,
    required this.featureValidation,
    required this.featureNavigation,
    required this.stateMgmt,
  });

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
  final StateManagement stateMgmt;

  /// Returns the string key for this preset.
  String get key {
    switch (this) {
      case FoundationPreset.starter:
        return 'starter';
      case FoundationPreset.batteriesIncluded:
        return 'batteries_included';
      case FoundationPreset.minimal:
        return 'minimal';
    }
  }

  /// Returns all valid preset keys.
  static List<String> get allKeys =>
      FoundationPreset.values.map((e) => e.key).toList();

  /// Parses preset from vars and returns the corresponding enum.
  /// Defaults to starter if not specified.
  static FoundationPreset fromVars(Vars vars) {
    final presetStr = vars.getVar<String>(MasonVarKey.preset)?.toLowerCase();
    if (presetStr == null || presetStr.isEmpty) {
      return FoundationPreset.starter; // Default
    }

    for (final preset in FoundationPreset.values) {
      if (preset.key == presetStr) {
        return preset;
      }
    }

    throw HookException(
      'Invalid preset: "$presetStr". Must be one of: ${allKeys.join(', ')}.',
    );
  }

  /// Creates a BaseTemplateVariables with preset values applied.
  BaseTemplateVariables applyTo(BaseTemplateVariables base) {
    return BaseTemplateVariables(
      name: base.name,
      organization: base.organization,
      generationMode: base.generationMode,
      platforms: base.platforms,
      description: base.description,
      templateVariant: base.templateVariant,
      minFlutterSdk: base.minFlutterSdk,
      minDartSdk: base.minDartSdk,
      withTests: withTests,
      withDocs: withDocs,
      withMcp: withMcp,
      codeGeneration: codeGeneration,
      aiIntegration: aiIntegration,
      serviceRetry: serviceRetry,
      serviceCaching: serviceCaching,
      serviceInterceptors: serviceInterceptors,
      serviceMocks: serviceMocks,
      featureViewModel: featureViewModel,
      featureValidation: featureValidation,
      featureNavigation: featureNavigation,
      stateManagement: stateMgmt,
      screenType: base.screenType,
      serviceType: base.serviceType,
      apiBaseUrl: base.apiBaseUrl,
      preset: key,
    );
  }
}
