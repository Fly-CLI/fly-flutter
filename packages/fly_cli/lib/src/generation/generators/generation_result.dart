import 'package:fly_cli/src/generation/domain/generation_error_type.dart';
import 'package:fly_cli/src/generation/generation_preview.dart';
import 'package:fly_cli/src/generation/template/template_info.dart';
import 'package:mason/mason.dart';

/// Standardized result type for all generators.
///
/// Provides a unified interface for generation results that can be converted
/// to CommandResult for command responses. This is the single source of truth
/// for all generation operations, replacing TemplateGenerationResult,
/// FoundationGenerationResult, and GenerationPreview.
class GenerationResult {
  const GenerationResult._({
    required this.success,
    this.files,
    this.targetDirectory,
    this.error,
    this.errorType,
    this.data,
    this.isDryRun = false,
    this.preview,
    this.template,
    this.duration,
  });

  /// Create a successful generation result.
  factory GenerationResult.success({
    required List<GeneratedFile> files,
    required String targetDirectory,
    Map<String, dynamic>? data,
    TemplateInfo? template,
    Duration? duration,
  }) {
    return GenerationResult._(
      success: true,
      files: files,
      targetDirectory: targetDirectory,
      data: data,
      template: template,
      duration: duration,
    );
  }

  /// Create a failed generation result.
  factory GenerationResult.failure({
    required String error,
    GenerationErrorType? errorType,
    Map<String, dynamic>? data,
  }) {
    return GenerationResult._(
      success: false,
      error: error,
      errorType: errorType,
      data: data,
    );
  }

  /// Create a dry-run/preview result.
  factory GenerationResult.dryRun({
    required GenerationPreview preview,
    TemplateInfo? template,
    Map<String, dynamic>? data,
  }) {
    return GenerationResult._(
      success: true,
      isDryRun: true,
      preview: preview,
      targetDirectory: preview.targetDirectory,
      template: template,
      data: data,
    );
  }

  /// Whether the generation was successful.
  final bool success;

  /// List of generated files (only present on success and non-dry-run).
  final List<GeneratedFile>? files;

  /// Target directory where files were generated or will be generated.
  final String? targetDirectory;

  /// Error message (only present on failure).
  final String? error;

  /// Error type categorization (only present on failure).
  final GenerationErrorType? errorType;

  /// Additional data for the result.
  final Map<String, dynamic>? data;

  /// Whether this is a dry-run/preview result.
  final bool isDryRun;

  /// Preview information (only present on dry-run).
  final GenerationPreview? preview;

  /// Template information used for generation.
  final TemplateInfo? template;

  /// Duration of the generation operation.
  final Duration? duration;

  /// Number of files generated.
  int get filesGenerated => files?.length ?? 0;

  /// Convert to a map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'is_dry_run': isDryRun,
      if (files != null) 'files_generated': files!.length,
      if (targetDirectory != null) 'target_directory': targetDirectory,
      if (error != null) 'error': error,
      if (errorType != null) 'error_type': errorType!.name,
      if (duration != null) 'duration_ms': duration!.inMilliseconds,
      if (template != null) 'template_name': template!.name,
      if (preview != null) 'preview': preview!.toJson(),
      if (data != null) ...data!,
    };
  }
}
