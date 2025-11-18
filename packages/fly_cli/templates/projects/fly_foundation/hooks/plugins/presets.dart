import 'package:mason/mason.dart';
import 'mason_variable_keys.dart';

import 'foundation_model.dart';
import 'hook_exception.dart';

/// Comprehensive configuration for a foundation preset.
///
/// This class contains all configurable properties that a preset can set,
/// making it easy to see what each preset includes at a glance.
/// All properties are required to ensure presets are comprehensive and exhaustive.
class PresetConfiguration {
  const PresetConfiguration({
    // Cross-cutting features
    required this.withTests,
    required this.withDocs,
    required this.withMcp,
    required this.codeGeneration,
    required this.aiIntegration,
    // Service features
    required this.serviceRetry,
    required this.serviceCaching,
    required this.serviceInterceptors,
    required this.serviceMocks,
    // Feature capabilities
    required this.featureViewModel,
    required this.featureValidation,
    required this.featureNavigation,
    // State management
    required this.stateMgmt,
  });

  // Cross-cutting features
  final bool withTests;
  final bool withDocs;
  final bool withMcp;
  final bool codeGeneration;
  final bool aiIntegration;

  // Service features
  final bool serviceRetry;
  final bool serviceCaching;
  final bool serviceInterceptors;
  final bool serviceMocks;

  // Feature capabilities
  final bool featureViewModel;
  final bool featureValidation;
  final bool featureNavigation;

  // State management
  final StateManagement stateMgmt;

  /// Applies this configuration to a BaseTemplateVariables instance.
  ///
  /// [presetKey] is the string key of the preset being applied.
  BaseTemplateVariables applyTo(BaseTemplateVariables base, String presetKey) {
    return base.copyWith(
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
      preset: presetKey,
    );
  }
}

/// Foundation preset enum with configuration for each preset.
enum FoundationPreset {
  starter(
    PresetConfiguration(
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
  ),
  batteriesIncluded(
    PresetConfiguration(
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
  ),
  minimal(
    PresetConfiguration(
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
    ),
  );

  const FoundationPreset(this.config);

  final PresetConfiguration config;

  // Convenience getters that delegate to config for backward compatibility
  bool get withTests => config.withTests;
  bool get withDocs => config.withDocs;
  bool get withMcp => config.withMcp;
  bool get codeGeneration => config.codeGeneration;
  bool get aiIntegration => config.aiIntegration;
  bool get serviceRetry => config.serviceRetry;
  bool get serviceCaching => config.serviceCaching;
  bool get serviceInterceptors => config.serviceInterceptors;
  bool get serviceMocks => config.serviceMocks;
  bool get featureViewModel => config.featureViewModel;
  bool get featureValidation => config.featureValidation;
  bool get featureNavigation => config.featureNavigation;
  StateManagement get stateMgmt => config.stateMgmt;

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
    return config.applyTo(base, key);
  }
}
