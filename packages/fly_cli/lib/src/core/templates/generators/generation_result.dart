import 'package:mason/mason.dart';

/// Standardized result type for all generators.
///
/// Provides a unified interface for generation results that can be converted
/// to CommandResult for command responses.
class GenerationResult {
  const GenerationResult._({
    required this.success,
    this.files,
    this.targetDirectory,
    this.error,
    this.data,
  });

  /// Create a successful generation result.
  factory GenerationResult.success({
    required List<GeneratedFile> files,
    required String targetDirectory,
    Map<String, dynamic>? data,
  }) {
    return GenerationResult._(
      success: true,
      files: files,
      targetDirectory: targetDirectory,
      data: data,
    );
  }

  /// Create a failed generation result.
  factory GenerationResult.failure({
    required String error,
    Map<String, dynamic>? data,
  }) {
    return GenerationResult._(
      success: false,
      error: error,
      data: data,
    );
  }

  /// Whether the generation was successful.
  final bool success;

  /// List of generated files (only present on success).
  final List<GeneratedFile>? files;

  /// Target directory where files were generated.
  final String? targetDirectory;

  /// Error message (only present on failure).
  final String? error;

  /// Additional data for the result.
  final Map<String, dynamic>? data;

  /// Number of files generated.
  int get filesGenerated => files?.length ?? 0;

  /// Convert to a map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'success': success,
      if (files != null) 'files_generated': files!.length,
      if (targetDirectory != null) 'target_directory': targetDirectory,
      if (error != null) 'error': error,
      if (data != null) ...data!,
    };
  }
}

