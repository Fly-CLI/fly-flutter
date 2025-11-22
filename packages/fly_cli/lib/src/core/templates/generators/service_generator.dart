import 'package:fly_cli/src/core/templates/foundation_orchestrator.dart';
import 'package:fly_cli/src/core/templates/generators/generation_result.dart';
import 'package:mason_logger/mason_logger.dart';

/// Generator for service components.
///
/// Handles service generation using the TemplateGenerationOrchestrator,
/// working in both standalone and project-scaffolding contexts.
class ServiceGenerator {
  final TemplateGenerationOrchestrator _orchestrator;
  final Logger _logger;

  /// Create a ServiceGenerator with the given orchestrator and logger.
  ServiceGenerator({
    required TemplateGenerationOrchestrator orchestrator,
    required Logger logger,
  })  : _orchestrator = orchestrator,
        _logger = logger;

  /// Generate a service component.
  ///
  /// [rawVars] should contain normalized variables from ServiceVariableBuilder.
  /// [outputDirectory] is the target directory for generation.
  ///
  /// Returns a GenerationResult with success status and generated files.
  Future<GenerationResult> generate({
    required Map<String, dynamic> rawVars,
    required String outputDirectory,
  }) async {
    try {
      _logger.info('Generating service: ${rawVars['name']}');
      _logger.info('Feature: ${rawVars['feature']}');
      _logger.info('Type: ${rawVars['service_type']}');
      _logger.info('With tests: ${rawVars['with_tests']}');
      _logger.info('With mocks: ${rawVars['with_mocks']}');
      _logger.info('With retry logic: ${rawVars['with_retry_logic']}');
      _logger.info('With caching: ${rawVars['with_caching']}');
      if (rawVars['service_type'] == 'api') {
        _logger.info('With interceptors: ${rawVars['with_interceptors']}');
        _logger.info('Base URL: ${rawVars['api_base_url']}');
      }

      final result = await _orchestrator.generate(
        rawVars: rawVars,
        outputDirectory: outputDirectory,
      );

      if (!result.success) {
        return GenerationResult.failure(
          error: result.error ?? 'Failed to generate service',
          data: {
            'component_name': rawVars['name'],
            'feature': rawVars['feature'],
            'service_type': rawVars['service_type'],
          },
        );
      }

      return GenerationResult.success(
        files: result.files ?? [],
        targetDirectory: result.targetDirectory ?? outputDirectory,
        data: {
          'component_name': rawVars['name'],
          'feature': rawVars['feature'],
          'service_type': rawVars['service_type'],
          'with_tests': rawVars['with_tests'],
          'with_mocks': rawVars['with_mocks'],
          'with_interceptors': rawVars['with_interceptors'] ?? false,
          'with_retry_logic': rawVars['with_retry_logic'] ?? false,
          'with_caching': rawVars['with_caching'] ?? false,
          if (rawVars['api_base_url'] != null) 'base_url': rawVars['api_base_url'],
        },
      );
    } catch (e, stackTrace) {
      _logger.err('Service generation failed: $e');
      _logger.detail('Stack trace: $stackTrace');
      return GenerationResult.failure(
        error: 'Failed to generate service: $e',
        data: {
          'component_name': rawVars['name'],
          'error_type': e.runtimeType.toString(),
        },
      );
    }
  }
}

