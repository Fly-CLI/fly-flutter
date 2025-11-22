import 'package:fly_cli/src/core/templates/foundation_orchestrator.dart';
import 'package:fly_cli/src/core/templates/generators/generation_result.dart';
import 'package:mason_logger/mason_logger.dart';

/// Generator for feature/screen components.
///
/// Handles feature generation using the TemplateGenerationOrchestrator,
/// working in both standalone and project-scaffolding contexts.
class FeatureGenerator {
  final TemplateGenerationOrchestrator _orchestrator;
  final Logger _logger;

  /// Create a FeatureGenerator with the given orchestrator and logger.
  FeatureGenerator({
    required TemplateGenerationOrchestrator orchestrator,
    required Logger logger,
  })  : _orchestrator = orchestrator,
        _logger = logger;

  /// Generate a feature component.
  ///
  /// [rawVars] should contain normalized variables from FeatureVariableBuilder.
  /// [outputDirectory] is the target directory for generation.
  ///
  /// Returns a GenerationResult with success status and generated files.
  Future<GenerationResult> generate({
    required Map<String, dynamic> rawVars,
    required String outputDirectory,
  }) async {
    try {
      _logger.info('Generating feature component: ${rawVars['name']}');
      _logger.info('Feature: ${rawVars['feature']}');
      _logger.info('Type: ${rawVars['screen_type']}');
      _logger.info('With viewmodel: ${rawVars['with_viewmodel']}');
      _logger.info('With tests: ${rawVars['with_tests']}');
      if (rawVars['screen_type'] == 'form') {
        _logger.info('With validation: ${rawVars['with_validation']}');
      }
      _logger.info('With navigation: ${rawVars['with_navigation']}');

      final result = await _orchestrator.generate(
        rawVars: rawVars,
        outputDirectory: outputDirectory,
      );

      if (!result.success) {
        return GenerationResult.failure(
          error: result.error ?? 'Failed to generate feature component',
          data: {
            'component_name': rawVars['name'],
            'feature': rawVars['feature'],
            'screen_type': rawVars['screen_type'],
          },
        );
      }

      return GenerationResult.success(
        files: result.files ?? [],
        targetDirectory: result.targetDirectory ?? outputDirectory,
        data: {
          'component_name': rawVars['name'],
          'feature': rawVars['feature'],
          'screen_type': rawVars['screen_type'],
          'with_viewmodel': rawVars['with_viewmodel'],
          'with_tests': rawVars['with_tests'],
          'with_validation': rawVars['with_validation'] ?? false,
          'with_navigation': rawVars['with_navigation'] ?? false,
        },
      );
    } catch (e, stackTrace) {
      _logger.err('Feature generation failed: $e');
      _logger.detail('Stack trace: $stackTrace');
      return GenerationResult.failure(
        error: 'Failed to generate feature component: $e',
        data: {
          'component_name': rawVars['name'],
          'error_type': e.runtimeType.toString(),
        },
      );
    }
  }
}

