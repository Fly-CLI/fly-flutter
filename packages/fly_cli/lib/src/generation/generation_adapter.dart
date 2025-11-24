import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/generation/generation_request.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/tools/types/generate_screen_params.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/tools/types/generate_service_params.dart';

/// Adapter utilities for converting between different input formats.
///
/// Provides methods to convert MCP tool parameters and CLI command inputs
/// into GenerationRequest objects for use with the unified generation service.
class GenerationAdapter {
  /// Convert MCP feature generation params to a GenerationRequest
  static GenerationRequest fromMcpFeatureParams({
    required GenerateScreenParams params,
    required String outputDirectory,
    CommandContext? context,
  }) {
    return GenerationRequest.feature(
      componentName: params.screenName,
      feature: params.feature,
      screenType: params.screenType,
      withViewModel: params.withViewModel,
      withTests: params.withTests,
      withValidation: params.withValidation,
      withNavigation: params.withNavigation,
      outputDirectory: outputDirectory,
      context: context,
    );
  }

  /// Convert MCP service generation params to a GenerationRequest
  static GenerationRequest fromMcpServiceParams({
    required GenerateServiceParams params,
    required String outputDirectory,
    CommandContext? context,
  }) {
    return GenerationRequest.service(
      componentName: params.serviceName,
      feature: params.feature,
      serviceType: params.serviceType,
      withTests: params.withTests,
      withMocks: params.withMocks,
      withInterceptors: params.withInterceptors,
      baseUrl: params.baseUrl,
      outputDirectory: outputDirectory,
      context: context,
    );
  }
}


