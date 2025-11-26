import 'package:fly_cli/src/generation/domain/generation_error_type.dart';
import 'package:fly_cli/src/generation/generators/generation_result.dart';

/// Data Transfer Object for generation results.
///
/// Used to transfer generation results between application and presentation layers.
class GenerationResultDto {
  /// Create a new GenerationResultDto.
  const GenerationResultDto({
    required this.success,
    this.error,
    this.errorType,
    this.generatedFiles = const [],
    this.preview,
    this.data = const {},
  });

  /// Create from GenerationResult
  factory GenerationResultDto.fromResult(GenerationResult result) {
    return GenerationResultDto(
      success: result.success,
      error: result.error,
      errorType: result.errorType,
      generatedFiles: result.files?.map((f) => f.path).toList() ?? [],
      preview: result.preview != null
          ? {
              'brick_name': result.preview!.brickName,
              'brick_type': result.preview!.brickType.name,
              'target_directory': result.preview!.targetDirectory,
              'files_to_generate': result.preview!.filesToGenerate,
              'directories_to_create': result.preview!.directoriesToCreate,
            }
          : null,
      data: result.data ?? {},
    );
  }

  /// Whether generation was successful
  final bool success;

  /// Error message if generation failed
  final String? error;

  /// Error type categorization if generation failed
  final GenerationErrorType? errorType;

  /// List of generated file paths
  final List<String> generatedFiles;

  /// Preview data (for dry runs)
  final Map<String, dynamic>? preview;

  /// Additional data
  final Map<String, dynamic> data;

  /// Convert to a map
  Map<String, dynamic> toMap() {
    return {
      'success': success,
      if (error != null) 'error': error,
      if (errorType != null) 'error_type': errorType!.name,
      'generated_files': generatedFiles,
      if (preview != null) 'preview': preview,
      'data': data,
    };
  }
}
