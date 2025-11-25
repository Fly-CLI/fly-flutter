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
    final variables = <String, dynamic>{
      'name': screenName,
      'component_name': screenName,
      'generation_mode': 'feature',
      if (feature != null) 'feature': feature,
      if (screenType != null) 'screen_type': screenType,
      if (withViewModel != null) 'with_viewmodel': withViewModel,
      if (withTests != null) 'with_tests': withTests,
      if (withValidation != null) 'with_validation': withValidation,
      if (withNavigation != null) 'with_navigation': withNavigation,
      'preset': 'starter',
    };

    final request = FeatureGenerationRequest(
      variables: variables,
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
    final variables = <String, dynamic>{
      'name': serviceName,
      'generation_mode': 'service',
      if (feature != null) 'feature': feature,
      if (serviceType != null) 'service_type': serviceType,
      if (withTests != null) 'with_tests': withTests,
      if (withMocks != null) 'with_mocks': withMocks,
      if (withInterceptors != null) 'with_interceptors': withInterceptors,
      if (baseUrl != null) 'api_base_url': baseUrl,
      'preset': 'starter',
    };

    final request = ServiceGenerationRequest(
      variables: variables,
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
    final variables = <String, dynamic>{
      'name': projectName,
      'project_name': projectName,
      'generation_mode': 'project',
      if (template != null) 'template': template,
      if (organization != null) 'organization': organization,
      if (description != null) 'description': description,
      if (platforms != null) 'platforms': platforms,
      if (features != null) 'features': features,
      'preset': 'starter',
    };

    final request = ProjectGenerationRequest(
      variables: variables,
      outputDirectory: outputDirectory,
    );

    return await _generateProjectUseCase.execute(request);
  }
}
