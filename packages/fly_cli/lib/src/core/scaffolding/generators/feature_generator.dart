import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/scaffolding/foundation/foundation_enums.dart';
import 'package:fly_cli/src/core/scaffolding/generation/generation_service.dart';
import 'package:fly_cli/src/core/scaffolding/generators/generation_result.dart';
import 'package:mason_logger/mason_logger.dart';

/// Generator for feature/screen components.
///
/// Handles feature generation using the GenerationService,
/// working in both standalone and project-scaffolding contexts.
/// This ensures consistency between CLI commands and MCP tools.
class FeatureGenerator {
  final CommandContext _context;
  final Logger _logger;

  /// Create a FeatureGenerator with the given context and logger.
  ///
  /// [context] is required to create the GenerationService.
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
  /// This method delegates to GenerationService to ensure
  /// consistency with MCP tool generation paths.
  Future<GenerationResult> generate({
    required Map<String, dynamic> rawVars,
    required String outputDirectory,
  }) async {
    try {
      // Create unified generation service
      final service = GenerationService(
        templateManager: _context.templateManager,
        logger: _logger,
      );

      // Generate using unified service
      return await service.generate(
        mode: GenerationMode.feature,
        rawVars: rawVars,
        outputDirectory: outputDirectory,
        dryRun: false,
      );
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

