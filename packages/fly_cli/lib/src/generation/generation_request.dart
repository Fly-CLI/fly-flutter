import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/generation/generation_types.dart';

/// Request model for code generation operations.
///
/// Encapsulates input parameters from different sources (CLI flags, MCP params, manifest)
/// and provides a unified interface for the generation service.
sealed class GenerationRequest {
  /// Create a request for feature generation
  factory GenerationRequest.feature({
    required String componentName,
    String? feature,
    String? screenType,
    bool? withViewModel,
    bool? withTests,
    bool? withValidation,
    bool? withNavigation,
    required String outputDirectory,
    CommandContext? context,
  }) {
    return FeatureGenerationRequest(
      componentName: componentName,
      feature: feature,
      screenType: screenType,
      withViewModel: withViewModel,
      withTests: withTests,
      withValidation: withValidation,
      withNavigation: withNavigation,
      outputDirectory: outputDirectory,
      context: context,
    );
  }

  /// Create a request for service generation
  factory GenerationRequest.service({
    required String componentName,
    String? feature,
    String? serviceType,
    bool? withTests,
    bool? withMocks,
    bool? withInterceptors,
    String? baseUrl,
    required String outputDirectory,
    CommandContext? context,
  }) {
    return ServiceGenerationRequest(
      componentName: componentName,
      feature: feature,
      serviceType: serviceType,
      withTests: withTests,
      withMocks: withMocks,
      withInterceptors: withInterceptors,
      baseUrl: baseUrl,
      outputDirectory: outputDirectory,
      context: context,
    );
  }

  /// Create a request for project generation
  factory GenerationRequest.project({
    required String projectName,
    required String outputDirectory,
    String? organization,
    String? description,
    List<String>? platforms,
    String? template,
    List<String>? features,
    List<String>? services,
    CommandContext? context,
  }) {
    return ProjectGenerationRequest(
      projectName: projectName,
      organization: organization,
      description: description,
      platforms: platforms,
      template: template,
      features: features,
      services: services,
      outputDirectory: outputDirectory,
      context: context,
    );
  }

  /// Create a request from a map (e.g., from manifest)
  factory GenerationRequest.fromMap({
    required GenerationMode type,
    required Map<String, dynamic> input,
    required String outputDirectory,
    CommandContext? context,
  }) {
    final componentName =
        input['name'] as String? ??
        input['service_name'] as String? ??
        input['screen_name'] as String?;
    if (componentName == null) {
      throw ArgumentError('Component name is required');
    }

    switch (type) {
      case GenerationMode.feature:
        return FeatureGenerationRequest(
          componentName: componentName,
          feature: input['feature'] as String?,
          screenType: input['screen_type'] as String?,
          withViewModel: input['with_viewmodel'] as bool?,
          withTests: input['with_tests'] as bool?,
          withValidation: input['with_validation'] as bool?,
          withNavigation: input['with_navigation'] as bool?,
          outputDirectory: outputDirectory,
          context: context,
        );
      case GenerationMode.service:
        return ServiceGenerationRequest(
          componentName: componentName,
          feature: input['feature'] as String?,
          serviceType: input['service_type'] as String?,
          withTests: input['with_tests'] as bool?,
          withMocks: input['with_mocks'] as bool?,
          withInterceptors: input['with_interceptors'] as bool?,
          baseUrl:
              input['api_base_url'] as String? ?? input['base_url'] as String?,
          outputDirectory: outputDirectory,
          context: context,
        );
      case GenerationMode.project:
        return ProjectGenerationRequest(
          projectName: componentName,
          organization: input['organization'] as String?,
          description: input['description'] as String?,
          platforms: (input['platforms'] as List<dynamic>?)?.cast<String>(),
          template: input['template'] as String?,
          features: (input['features'] as List<dynamic>?)?.cast<String>(),
          services: (input['services'] as List<dynamic>?)?.cast<String>(),
          outputDirectory: outputDirectory,
          context: context,
        );
    }
  }

  const GenerationRequest({
    required this.componentName,
    this.feature,
    required this.outputDirectory,
    this.context,
  });

  /// Type of generation (feature or service)
  GenerationMode get type;

  /// Name of the component to generate
  final String componentName;

  /// Feature name (optional)
  final String? feature;

  /// Output directory where files should be generated
  final String outputDirectory;

  /// Command context (optional, for CLI commands)
  final CommandContext? context;

  /// Convert to a map for variable building
  Map<String, dynamic> toVariableMap();
}

/// Request for feature generation
final class FeatureGenerationRequest extends GenerationRequest {
  const FeatureGenerationRequest({
    required super.componentName,
    super.feature,
    this.screenType,
    this.withViewModel,
    this.withTests,
    this.withValidation,
    this.withNavigation,
    required super.outputDirectory,
    super.context,
  });

  @override
  GenerationMode get type => GenerationMode.feature;

  /// Screen type (for feature generation)
  final String? screenType;

  /// Whether to include ViewModel/Provider (for feature generation)
  final bool? withViewModel;

  /// Whether to include test files
  final bool? withTests;

  /// Whether to include form validation (for feature generation)
  final bool? withValidation;

  /// Whether to include navigation logic (for feature generation)
  final bool? withNavigation;

  @override
  Map<String, dynamic> toVariableMap() {
    return {
      'name': componentName,
      'generation_mode': type.key,
      if (feature != null) 'feature': feature,
      'preset': 'starter',
      if (screenType != null) 'screen_type': screenType,
      if (withViewModel != null) 'with_viewmodel': withViewModel,
      if (withTests != null) 'with_tests': withTests,
      if (withValidation != null) 'with_validation': withValidation,
      if (withNavigation != null) 'with_navigation': withNavigation,
    };
  }
}

/// Request for service generation
final class ServiceGenerationRequest extends GenerationRequest {
  const ServiceGenerationRequest({
    required super.componentName,
    super.feature,
    this.serviceType,
    this.withTests,
    this.withMocks,
    this.withInterceptors,
    this.baseUrl,
    required super.outputDirectory,
    super.context,
  });

  @override
  GenerationMode get type => GenerationMode.service;

  /// Service type (for service generation)
  final String? serviceType;

  /// Whether to include test files
  final bool? withTests;

  /// Whether to include mock files (for service generation)
  final bool? withMocks;

  /// Whether to include HTTP interceptors (for service generation)
  final bool? withInterceptors;

  /// Base URL for API services
  final String? baseUrl;

  @override
  Map<String, dynamic> toVariableMap() {
    final baseMap = <String, dynamic>{
      'name': componentName,
      'generation_mode': type.key,
      if (feature != null) 'feature': feature,
      'preset': 'starter',
      if (serviceType != null) 'service_type': serviceType,
      if (withTests != null) 'with_tests': withTests,
      if (withMocks != null) 'with_mocks': withMocks,
      if (withInterceptors != null) 'with_interceptors': withInterceptors,
      if (baseUrl != null) 'api_base_url': baseUrl,
    };

    // Auto-derive service-specific flags
    final isApiService = serviceType == 'api';
    baseMap['with_retry_logic'] = isApiService;
    baseMap['with_caching'] = serviceType == 'cache';

    return baseMap;
  }
}

/// Request for project generation
final class ProjectGenerationRequest extends GenerationRequest {
  const ProjectGenerationRequest({
    required this.projectName,
    required super.outputDirectory,
    this.organization,
    this.description,
    this.platforms,
    this.template,
    this.features,
    this.services,
    super.context,
  }) : super(componentName: projectName);

  @override
  GenerationMode get type => GenerationMode.project;

  /// Project name (alias for componentName)
  final String projectName;

  /// Organization identifier (e.g., "com.example")
  final String? organization;

  /// Project description
  final String? description;

  /// Target platforms (e.g., ["ios", "android", "web"])
  final List<String>? platforms;

  /// Template to use (defaults to "fly_foundation")
  final String? template;

  /// List of features to include
  final List<String>? features;

  /// List of services to include
  final List<String>? services;

  @override
  Map<String, dynamic> toVariableMap() {
    return {
      'name': projectName,
      'project_name': projectName,
      'generation_mode': type.key,
      'preset': 'starter',
      if (organization != null) 'organization': organization,
      if (description != null) 'description': description,
      if (platforms != null) 'platforms': platforms,
      if (template != null) 'template': template,
      if (features != null) 'features': features,
      if (services != null) 'services': services,
    };
  }
}
