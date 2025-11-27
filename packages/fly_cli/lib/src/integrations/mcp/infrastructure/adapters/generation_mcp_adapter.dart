import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/modes/generation_mode_profile.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';

/// Adapter for MCP tools to use generation strategies.
///
/// Provides a unified interface for MCP tools to execute generation
/// operations, ensuring consistency with CLI commands and benefiting
/// from the same strategy-based architecture.
///
/// This adapter translates MCP-specific parameters into GenerationRequestDto
/// objects and delegates execution to strategies from the profiles map,
/// which is the single source of truth for all mode-specific logic.
class GenerationMcpAdapter {
  /// Creates a new instance of [GenerationMcpAdapter].
  ///
  /// [profiles] provides access to all generation mode profiles, which contain
  /// all mode-specific logic and dependencies (including strategies).
  GenerationMcpAdapter({
    required Map<GenerationMode, GenerationModeProfile> profiles,
  }) : _profiles = profiles;

  final Map<GenerationMode, GenerationModeProfile> _profiles;

  /// Execute feature generation from MCP parameters.
  ///
  /// Delegates to the strategy from the profiles map to ensure consistency with CLI behavior.
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

    final profile = _profiles[GenerationMode.feature];
    if (profile == null) {
      throw StateError(
        'No profile found for generation mode: ${GenerationMode.feature.key}',
      );
    }

    return profile.strategy.execute(request);
  }

  /// Execute service generation from MCP parameters.
  ///
  /// Delegates to the strategy from the profiles map to ensure consistency with CLI behavior.
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

    final profile = _profiles[GenerationMode.service];
    if (profile == null) {
      throw StateError(
        'No profile found for generation mode: ${GenerationMode.service.key}',
      );
    }

    return profile.strategy.execute(request);
  }

  /// Execute project generation from MCP parameters.
  ///
  /// Delegates to the strategy from the profiles map to ensure consistency with CLI behavior.
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

    final profile = _profiles[GenerationMode.project];
    if (profile == null) {
      throw StateError(
        'No profile found for generation mode: ${GenerationMode.project.key}',
      );
    }

    return profile.strategy.execute(request);
  }
}
