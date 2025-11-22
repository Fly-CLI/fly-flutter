import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/templates/generation/component_generation_service.dart';
import 'package:fly_cli/src/core/templates/generation/generation_request.dart';
import 'package:fly_cli/src/core/templates/generators/generation_result.dart';
import 'package:mason_logger/mason_logger.dart';

/// Generator for feature/screen components.
///
/// Handles feature generation using the ComponentGenerationService,
/// working in both standalone and project-scaffolding contexts.
/// This ensures consistency between CLI commands and MCP tools.
class FeatureGenerator {
  final CommandContext _context;
  final Logger _logger;

  /// Create a FeatureGenerator with the given context and logger.
  ///
  /// [context] is required to create the ComponentGenerationService.
  /// [logger] is used for logging generation progress.
  FeatureGenerator({
    required CommandContext context,
    required Logger logger,
  })  : _context = context,
        _logger = logger;

  /// Generate a feature component.
  ///
  /// [rawVars] should contain normalized variables from FeatureVariableBuilder.
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
      final request = GenerationRequest.feature(
        componentName: rawVars['name'] as String,
        feature: rawVars['feature'] as String?,
        screenType: rawVars['screen_type'] as String?,
        withViewModel: rawVars['with_viewmodel'] as bool?,
        withTests: rawVars['with_tests'] as bool?,
        withValidation: rawVars['with_validation'] as bool?,
        withNavigation: rawVars['with_navigation'] as bool?,
        outputDirectory: outputDirectory,
        context: _context,
      );

      // Use ComponentGenerationService for consistent generation
      final service = ComponentGenerationService(context: _context);
      return await service.generateFeature(request: request);
    } catch (e, stackTrace) {
      _logger.err('Feature generation failed: $e');
      _logger.detail('Stack trace: $stackTrace');
      return GenerationResult.failure(
        error: 'Failed to generate feature component: $e',
        data: {
          'component_name': rawVars['name'] as String? ?? 'unknown',
          'error_type': e.runtimeType.toString(),
        },
      );
    }
  }
}

