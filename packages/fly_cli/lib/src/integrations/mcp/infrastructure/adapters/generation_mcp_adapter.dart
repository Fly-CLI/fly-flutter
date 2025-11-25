import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/use_cases/generate_feature_use_case.dart';
import 'package:fly_cli/src/generation/application/use_cases/generate_project_use_case.dart';
import 'package:fly_cli/src/generation/application/use_cases/generate_service_use_case.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';

/// Adapter for MCP tools to use generation use cases.
///
/// Provides a unified interface for MCP tools to execute generation
/// operations through use cases, ensuring consistency with CLI commands.
class GenerationMcpAdapter {
  GenerationMcpAdapter({
    required GenerateFeatureUseCase generateFeatureUseCase,
    required GenerateServiceUseCase generateServiceUseCase,
    required GenerateProjectUseCase generateProjectUseCase,
  }) : _generateFeatureUseCase = generateFeatureUseCase,
       _generateServiceUseCase = generateServiceUseCase,
       _generateProjectUseCase = generateProjectUseCase;

  final GenerateFeatureUseCase _generateFeatureUseCase;
  final GenerateServiceUseCase _generateServiceUseCase;
  final GenerateProjectUseCase _generateProjectUseCase;

  /// Execute feature generation from MCP parameters.
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

    return await _generateFeatureUseCase.execute(request);
  }

  /// Execute service generation from MCP parameters.
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

    return await _generateServiceUseCase.execute(request);
  }

  /// Execute project generation from MCP parameters.
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

    return await _generateProjectUseCase.execute(request);
  }
}
