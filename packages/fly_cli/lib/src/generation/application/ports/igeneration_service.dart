import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/generation/generation_request.dart';
import 'package:fly_cli/src/generation/generators/generation_result.dart';

/// Interface extracted from GenerationService.
///
/// Represents the core generation service operations.
/// This interface will be implemented by use cases in Phase 3.
abstract class IGenerationService {
  /// Generate code using the unified service.
  ///
  /// [mode] specifies the generation mode (project, feature, or service).
  /// [rawVars] contains the input variables for generation.
  /// [outputDirectory] is where files should be generated.
  /// [dryRun] if true, generates a preview instead of actual files.
  ///
  /// Returns a [GenerationResult] with success status and generated files or preview.
  Future<GenerationResult> generate({
    required GenerationMode mode,
    required Map<String, dynamic> rawVars,
    required String outputDirectory,
    bool dryRun = false,
  });

  /// Generate from a GenerationRequest (for backward compatibility).
  ///
  /// This method adapts GenerationRequest to the unified generate method.
  Future<GenerationResult> generateFromRequest({
    required GenerationRequest request,
    required String outputDirectory,
    bool dryRun = false,
  });
}

