import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:json_annotation/json_annotation.dart';

part 'generation_request_dto.g.dart';

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
  Map<String, dynamic> toJson();
}

/// Request for project generation.
@JsonSerializable(explicitToJson: true, includeIfNull: false)
final class ProjectGenerationRequest extends GenerationRequestDto {
  /// Create a new ProjectGenerationRequest.
  const ProjectGenerationRequest({
    required this.name,
    required super.outputDirectory,
    this.template = 'fly_foundation',
    this.organization = 'com.example',
    this.description,
    this.platforms = const ['ios', 'android'],
    this.features = const [],
    this.services = const [],
    this.preset = 'starter',
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

  /// Create from JSON.
  factory ProjectGenerationRequest.fromJson(Map<String, dynamic> json) =>
      _$ProjectGenerationRequestFromJson(json);

  @override
  GenerationMode get mode => GenerationMode.project;

  @override
  Map<String, dynamic> toJson() {
    final json = _$ProjectGenerationRequestToJson(this);
    // Add extra fields for backward compatibility
    json['project_name'] = name;
    json['generation_mode'] = 'project';
    return json;
  }
}

/// Request for feature generation.
@JsonSerializable(explicitToJson: true, includeIfNull: false)
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
  @JsonKey(name: 'screen_type')
  @_ScreenTypeConverter()
  final ScreenType screenType;

  /// Whether to include ViewModel/Provider
  @JsonKey(name: 'with_viewmodel')
  final bool withViewModel;

  /// Whether to include test files
  @JsonKey(name: 'with_tests')
  final bool withTests;

  /// Whether to include form validation
  @JsonKey(name: 'with_validation')
  final bool withValidation;

  /// Whether to include navigation logic
  @JsonKey(name: 'with_navigation')
  final bool withNavigation;

  /// Preset configuration
  final String preset;

  /// Create from JSON.
  factory FeatureGenerationRequest.fromJson(Map<String, dynamic> json) =>
      _$FeatureGenerationRequestFromJson(json);

  @override
  GenerationMode get mode => GenerationMode.feature;

  @override
  Map<String, dynamic> toJson() {
    return _$FeatureGenerationRequestToJson(this);
  }
}

/// Request for service generation.
@JsonSerializable(explicitToJson: true, includeIfNull: false)
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
  @JsonKey(name: 'service_type')
  @_ServiceTypeConverter()
  final ServiceType serviceType;

  /// Whether to include test files
  @JsonKey(name: 'with_tests')
  final bool withTests;

  /// Whether to include mock files
  @JsonKey(name: 'with_mocks')
  final bool withMocks;

  /// Whether to include HTTP interceptors
  @JsonKey(name: 'with_interceptors')
  final bool withInterceptors;

  /// Base URL for API services (only used for API service type)
  @JsonKey(name: 'api_base_url')
  final String? apiBaseUrl;

  /// Preset configuration
  final String preset;

  /// Create from JSON.
  factory ServiceGenerationRequest.fromJson(Map<String, dynamic> json) =>
      _$ServiceGenerationRequestFromJson(json);

  @override
  GenerationMode get mode => GenerationMode.service;

  @override
  Map<String, dynamic> toJson() {
    return _$ServiceGenerationRequestToJson(this);
  }
}

/// Converter for ScreenType enum using .key property
class _ScreenTypeConverter implements JsonConverter<ScreenType, String> {
  const _ScreenTypeConverter();

  @override
  ScreenType fromJson(String json) => ScreenType.fromKey(json);

  @override
  String toJson(ScreenType object) => object.key;
}

/// Converter for ServiceType enum using .key property
class _ServiceTypeConverter implements JsonConverter<ServiceType, String> {
  const _ServiceTypeConverter();

  @override
  ServiceType fromJson(String json) => ServiceType.fromKey(json);

  @override
  String toJson(ServiceType object) => object.key;
}
