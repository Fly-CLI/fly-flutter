import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';

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

  /// Create a request from a map (e.g., from manifest)
  factory GenerationRequest.fromMap({
    required GenerationType type,
    required Map<String, dynamic> input,
    required String outputDirectory,
    CommandContext? context,
  }) {
    final componentName = input['name'] as String? ??
        input['component_name'] as String? ??
        input['service_name'] as String? ??
        input['screen_name'] as String?;
    if (componentName == null) {
      throw ArgumentError('Component name is required');
    }

    switch (type) {
      case GenerationType.feature:
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
      case GenerationType.service:
        return ServiceGenerationRequest(
          componentName: componentName,
          feature: input['feature'] as String?,
          serviceType: input['service_type'] as String?,
          withTests: input['with_tests'] as bool?,
          withMocks: input['with_mocks'] as bool?,
          withInterceptors: input['with_interceptors'] as bool?,
          baseUrl: input['api_base_url'] as String? ??
              input['base_url'] as String?,
          outputDirectory: outputDirectory,
          context: context,
        );
      case GenerationType.project:
        throw UnimplementedError('Project generation not yet supported');
    }
  }

  const GenerationRequest({
    required this.componentName,
    this.feature,
    required this.outputDirectory,
    this.context,
  });

  /// Type of generation (feature or service)
  GenerationType get type;

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
  GenerationType get type => GenerationType.feature;

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
      if (feature != null) 'feature': feature!,
      'preset': 'starter',
      if (screenType != null) 'screen_type': screenType!,
      if (withViewModel != null) 'with_viewmodel': withViewModel!,
      if (withTests != null) 'with_tests': withTests!,
      if (withValidation != null) 'with_validation': withValidation!,
      if (withNavigation != null) 'with_navigation': withNavigation!,
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
  GenerationType get type => GenerationType.service;

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
      if (feature != null) 'feature': feature!,
      'preset': 'starter',
      if (serviceType != null) 'service_type': serviceType!,
      if (withTests != null) 'with_tests': withTests!,
      if (withMocks != null) 'with_mocks': withMocks!,
      if (withInterceptors != null) 'with_interceptors': withInterceptors!,
      if (baseUrl != null) 'api_base_url': baseUrl!,
    };

    // Auto-derive service-specific flags
    final isApiService = serviceType == 'api';
    baseMap['with_retry_logic'] = isApiService;
    baseMap['with_caching'] = serviceType == 'cache';

    return baseMap;
  }
}

/// Type of generation operation
enum GenerationType {
  feature,
  service,
  project;

  /// Key used in variable maps
  String get key {
    switch (this) {
      case GenerationType.feature:
        return 'feature';
      case GenerationType.service:
        return 'service';
      case GenerationType.project:
        return 'project';
    }
  }
}


