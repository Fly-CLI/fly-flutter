import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/templates/generation/component_generation_service.dart';
import 'package:fly_cli/src/core/templates/generation/generation_request.dart';
import 'package:fly_cli/src/core/templates/generators/generation_result.dart';
import 'package:mason_logger/mason_logger.dart';

/// Generator for service components.
///
/// Handles service generation using the ComponentGenerationService,
/// working in both standalone and project-scaffolding contexts.
/// This ensures consistency between CLI commands and MCP tools.
class ServiceGenerator {
  final CommandContext _context;
  final Logger _logger;

  /// Create a ServiceGenerator with the given context and logger.
  ///
  /// [context] is required to create the ComponentGenerationService.
  /// [logger] is used for logging generation progress.
  ServiceGenerator({
    required CommandContext context,
    required Logger logger,
  })  : _context = context,
        _logger = logger;

  /// Generate a service component.
  ///
  /// [rawVars] should contain normalized variables from ServiceVariableBuilder.
  /// [outputDirectory] is the target directory for generation.
  ///
  /// Returns a GenerationResult with success status and generated files.
  ///
  /// This method delegates to ComponentGenerationService to ensure
  /// consistency with MCP tool generation paths.
  Future<GenerationResult> generate({
    required Map<String, dynamic> rawVars,
    required String outputDirectory,
  }) async {
    try {
      // Create generation request from rawVars
      final request = GenerationRequest.service(
        componentName: rawVars['name'] as String,
        feature: rawVars['feature'] as String?,
        serviceType: rawVars['service_type'] as String?,
        withTests: rawVars['with_tests'] as bool?,
        withMocks: rawVars['with_mocks'] as bool?,
        withInterceptors: rawVars['with_interceptors'] as bool?,
        baseUrl: rawVars['api_base_url'] as String?,
        outputDirectory: outputDirectory,
        context: _context,
      );

      // Use ComponentGenerationService for consistent generation
      final service = ComponentGenerationService(context: _context);
      return await service.generateService(request: request);
    } catch (e, stackTrace) {
      _logger.err('Service generation failed: $e');
      _logger.detail('Stack trace: $stackTrace');
      return GenerationResult.failure(
        error: 'Failed to generate service: $e',
        data: {
          'component_name': rawVars['name'] as String? ?? 'unknown',
          'error_type': e.runtimeType.toString(),
        },
      );
    }
  }
}

