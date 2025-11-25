import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';

/// Sealed class for generation requests with type-safe variants.
///
/// Used to transfer data between presentation and application layers.
/// The generation mode is encoded in the type itself, providing
/// compile-time type safety and enabling exhaustive pattern matching.
sealed class GenerationRequestDto {
  const GenerationRequestDto({
    required this.outputDirectory,
    this.dryRun = false,
  });

  /// Output directory where files should be generated
  final String outputDirectory;

  /// Whether this is a dry run (preview only)
  final bool dryRun;

  /// Get the generation mode for this request
  GenerationMode get mode;

  /// Convert to a variables map for backward compatibility with existing code
  Map<String, dynamic> toVariablesMap();

  /// Convert to a map
  Map<String, dynamic> toMap() {
    return {
      'mode': mode.key,
      'variables': toVariablesMap(),
      'output_directory': outputDirectory,
      'dry_run': dryRun,
    };
  }
}

/// Request for project generation.
final class ProjectGenerationRequest extends GenerationRequestDto {
  const ProjectGenerationRequest({
    required this.name,
    this.template = 'fly_foundation',
    this.organization = 'com.example',
    this.description,
    this.platforms = const ['ios', 'android'],
    this.features = const [],
    this.services = const [],
    this.preset = 'starter',
    required super.outputDirectory,
    super.dryRun = false,
  });

  /// Project name
  final String name;

  /// Template to use for generation
  final String template;

  /// Organization identifier
  final String organization;

  /// Project description
  final String? description;

  /// Target platforms
  final List<String> platforms;

  /// List of feature instances to generate
  final List<Map<String, dynamic>> features;

  /// List of service instances to generate
  final List<Map<String, dynamic>> services;

  /// Preset configuration
  final String preset;

  @override
  GenerationMode get mode => GenerationMode.project;

  @override
  Map<String, dynamic> toVariablesMap() {
    return {
      'name': name,
      'project_name': name,
      'generation_mode': 'project',
      'template': template,
      'organization': organization,
      if (description != null) 'description': description,
      'platforms': platforms,
      'features': features,
      'services': services,
      'preset': preset,
    };
  }
}

/// Request for feature generation.
final class FeatureGenerationRequest extends GenerationRequestDto {
  const FeatureGenerationRequest({
    required this.name,
    this.feature = 'home',
    this.screenType = ScreenType.list,
    this.withViewModel = false,
    this.withTests = true,
    this.withValidation = false,
    this.withNavigation = false,
    this.preset = 'starter',
    required super.outputDirectory,
    super.dryRun = false,
  });

  /// Component/screen name
  final String name;

  /// Feature name this component belongs to
  final String feature;

  /// Type of screen to generate
  final ScreenType screenType;

  /// Whether to include ViewModel/Provider
  final bool withViewModel;

  /// Whether to include test files
  final bool withTests;

  /// Whether to include form validation
  final bool withValidation;

  /// Whether to include navigation logic
  final bool withNavigation;

  /// Preset configuration
  final String preset;

  @override
  GenerationMode get mode => GenerationMode.feature;

  @override
  Map<String, dynamic> toVariablesMap() {
    return {
      'name': name,
      'component_name': name,
      'generation_mode': 'feature',
      'feature': feature,
      'screen_type': screenType.key,
      'with_viewmodel': withViewModel,
      'with_tests': withTests,
      'with_validation': withValidation,
      'with_navigation': withNavigation,
      'preset': preset,
    };
  }
}

/// Request for service generation.
final class ServiceGenerationRequest extends GenerationRequestDto {
  const ServiceGenerationRequest({
    required this.name,
    this.feature = 'core',
    this.serviceType = ServiceType.api,
    this.withTests = true,
    this.withMocks = false,
    this.withInterceptors = false,
    this.apiBaseUrl,
    this.preset = 'starter',
    required super.outputDirectory,
    super.dryRun = false,
  });

  /// Service name
  final String name;

  /// Feature name this service belongs to
  final String feature;

  /// Type of service to generate
  final ServiceType serviceType;

  /// Whether to include test files
  final bool withTests;

  /// Whether to include mock files
  final bool withMocks;

  /// Whether to include HTTP interceptors
  final bool withInterceptors;

  /// Base URL for API services (only used for API service type)
  final String? apiBaseUrl;

  /// Preset configuration
  final String preset;

  @override
  GenerationMode get mode => GenerationMode.service;

  @override
  Map<String, dynamic> toVariablesMap() {
    return {
      'name': name,
      'component_name': name,
      'generation_mode': 'service',
      'feature': feature,
      'service_type': serviceType.key,
      'with_tests': withTests,
      'with_mocks': withMocks,
      'with_interceptors': withInterceptors,
      'with_retry_logic': serviceType == ServiceType.api,
      'with_caching': serviceType == ServiceType.cache,
      if (serviceType == ServiceType.api)
        'api_base_url': apiBaseUrl ?? 'https://api.example.com',
      'preset': preset,
    };
  }
}
