import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_mode_registry.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';

/// Adapter for MCP tools to use generation strategies.
///
/// Provides a unified interface for MCP tools to execute generation
/// operations through the generation mode registry, ensuring consistency
/// with CLI commands and benefiting from the same strategy-based architecture.
///
/// This adapter translates MCP-specific parameters into GenerationRequestDto
/// objects and delegates execution to the GenerationModeRegistry, which routes
/// requests to the appropriate strategy implementation.
class GenerationMcpAdapter {
  /// Creates a new instance of [GenerationMcpAdapter].
  GenerationMcpAdapter({
    required GenerationModeRegistry registry,
  }) : _registry = registry;

  final GenerationModeRegistry _registry;

  /// Execute feature generation from MCP parameters.
  ///
  /// Delegates to the generation mode registry to ensure consistency with CLI behavior.
  Future<GenerationResultDto> generateFeature({
    required String screenName,
    String? feature,
    String? screenType,
    bool? withViewModel,
    bool? withTests,
    bool? withValidation,
    bool? withNavigation,
    required String outputDirectory,
  }) async {
    final request = FeatureGenerationRequest(
      name: screenName,
      feature: feature ?? 'home',
      screenType: screenType != null
          ? ScreenType.fromKey(screenType)
          : ScreenType.list,
      withViewModel: withViewModel ?? false,
      withTests: withTests ?? true,
      withValidation: withValidation ?? false,
      withNavigation: withNavigation ?? false,
      outputDirectory: outputDirectory,
    );

    return _registry.execute(request);
  }

  /// Execute service generation from MCP parameters.
  ///
  /// Delegates to the generation mode registry to ensure consistency with CLI behavior.
  Future<GenerationResultDto> generateService({
    required String serviceName,
    String? feature,
    String? serviceType,
    bool? withTests,
    bool? withMocks,
    bool? withInterceptors,
    String? baseUrl,
    required String outputDirectory,
  }) async {
    final request = ServiceGenerationRequest(
      name: serviceName,
      feature: feature ?? 'core',
      serviceType: serviceType != null
          ? ServiceType.fromKey(serviceType)
          : ServiceType.api,
      withTests: withTests ?? true,
      withMocks: withMocks ?? false,
      withInterceptors: withInterceptors ?? false,
      apiBaseUrl: baseUrl,
      outputDirectory: outputDirectory,
    );

    return _registry.execute(request);
  }

  /// Execute project generation from MCP parameters.
  ///
  /// Delegates to the generation mode registry to ensure consistency with CLI behavior.
  Future<GenerationResultDto> generateProject({
    required String projectName,
    String? template,
    String? organization,
    String? description,
    List<String>? platforms,
    List<String>? features,
    required String outputDirectory,
  }) async {
    // Convert features list to feature instances format
    final featureInstances = (features ?? []).map((featureName) {
      return {
        'name': featureName,
        'type': 'feature',
        'params': {
          'feature': featureName,
          'screen_type': 'list',
          'with_viewmodel': true,
          'with_tests': true,
          'with_validation': false,
          'with_navigation': false,
        },
      };
    }).toList();

    final request = ProjectGenerationRequest(
      name: projectName,
      template: template ?? 'fly_foundation',
      organization: organization ?? 'com.example',
      description: description,
      platforms: platforms ?? ['ios', 'android'],
      features: featureInstances,
      services: [],
      outputDirectory: outputDirectory,
    );

    return _registry.execute(request);
  }
}
