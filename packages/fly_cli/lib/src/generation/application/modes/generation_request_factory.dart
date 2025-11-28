import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';

/// Factory interface for creating generation request DTOs from variable maps.
///
/// This factory encapsulates mode-specific logic for constructing request DTOs,
/// including default values and type conversions. This centralizes request
/// construction logic that was previously scattered across command files.
abstract class GenerationRequestFactory {
  /// Creates a generation request DTO from a variable map.
  ///
  /// [variables] - Raw variables from CLI flags, interactive prompts, or manifest
  /// [outputDirectory] - Target directory for generation
  /// [dryRun] - Whether this is a dry run (preview only)
  ///
  /// Returns a properly constructed [GenerationRequestDto] with all defaults applied.
  GenerationRequestDto createRequest({
    required Map<String, dynamic> variables,
    required String outputDirectory,
    required bool dryRun,
  });
}

/// Factory for creating feature generation requests.
class FeatureRequestFactory implements GenerationRequestFactory {
  /// Creates a feature generation request.
  const FeatureRequestFactory();

  @override
  FeatureGenerationRequest createRequest({
    required Map<String, dynamic> variables,
    required String outputDirectory,
    required bool dryRun,
  }) {
    return FeatureGenerationRequest(
      name: variables['name'] as String,
      feature: variables['feature'] as String? ?? 'home',
      screenType: ScreenType.tryFromKey(
        variables['screen_type'] as String?,
        defaultValue: ScreenType.empty,
      ) ?? ScreenType.empty,
      withViewModel: variables['with_viewmodel'] as bool? ?? false,
      withTests: variables['with_tests'] as bool? ?? true,
      withValidation: variables['with_validation'] as bool? ?? false,
      withNavigation: variables['with_navigation'] as bool? ?? false,
      preset: variables['preset'] as String? ?? 'starter',
      outputDirectory: outputDirectory,
      dryRun: dryRun,
    );
  }
}

/// Factory for creating service generation requests.
class ServiceRequestFactory implements GenerationRequestFactory {
  /// Creates a service generation request.
  const ServiceRequestFactory();

  @override
  ServiceGenerationRequest createRequest({
    required Map<String, dynamic> variables,
    required String outputDirectory,
    required bool dryRun,
  }) {
    return ServiceGenerationRequest(
      name: variables['name'] as String,
      feature: variables['feature'] as String? ?? 'core',
      serviceType: ServiceType.tryFromKey(
        variables['service_type'] as String?,
        defaultValue: ServiceType.api,
      ) ?? ServiceType.api,
      withTests: variables['with_tests'] as bool? ?? true,
      withMocks: variables['with_mocks'] as bool? ?? false,
      withInterceptors: variables['with_interceptors'] as bool? ?? false,
      apiBaseUrl: variables['api_base_url'] as String?,
      preset: variables['preset'] as String? ?? 'starter',
      outputDirectory: outputDirectory,
      dryRun: dryRun,
    );
  }
}

/// Factory for creating project generation requests.
class ProjectRequestFactory implements GenerationRequestFactory {
  /// Creates a project generation request.
  const ProjectRequestFactory();

  @override
  ProjectGenerationRequest createRequest({
    required Map<String, dynamic> variables,
    required String outputDirectory,
    required bool dryRun,
  }) {
    return ProjectGenerationRequest(
      name: variables['name'] as String? ?? variables['project_name'] as String,
      template: variables['template'] as String? ?? 'fly_foundation',
      organization: variables['organization'] as String? ?? 'com.example',
      description: variables['description'] as String? ?? 'A new Flutter project',
      platforms: (variables['platforms'] as List<dynamic>?)?.cast<String>() ??
          const ['ios', 'android'],
      features: (variables['features'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
          const [],
      services: (variables['services'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
          const [],
      preset: variables['preset'] as String? ?? 'starter',
      outputDirectory: outputDirectory,
      dryRun: dryRun,
    );
  }
}

