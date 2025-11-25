import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';

/// Sealed class for generation requests with type-safe variants.
///
/// Used to transfer data between presentation and application layers.
/// The generation mode is encoded in the type itself, providing
/// compile-time type safety and enabling exhaustive pattern matching.
sealed class GenerationRequestDto {
  const GenerationRequestDto({
    required this.variables,
    required this.outputDirectory,
    this.dryRun = false,
  });

  /// Input variables for generation
  final Map<String, dynamic> variables;

  /// Output directory where files should be generated
  final String outputDirectory;

  /// Whether this is a dry run (preview only)
  final bool dryRun;

  /// Get the generation mode for this request
  GenerationMode get mode;

  /// Create from a map (e.g., from CLI flags or MCP params)
  ///
  /// Returns the appropriate variant based on the mode.
  factory GenerationRequestDto.fromMap({
    required GenerationMode mode,
    required Map<String, dynamic> variables,
    required String outputDirectory,
    bool dryRun = false,
  }) {
    switch (mode) {
      case GenerationMode.project:
        return ProjectGenerationRequest(
          variables: variables,
          outputDirectory: outputDirectory,
          dryRun: dryRun,
        );
      case GenerationMode.feature:
        return FeatureGenerationRequest(
          variables: variables,
          outputDirectory: outputDirectory,
          dryRun: dryRun,
        );
      case GenerationMode.service:
        return ServiceGenerationRequest(
          variables: variables,
          outputDirectory: outputDirectory,
          dryRun: dryRun,
        );
    }
  }

  /// Convert to a map
  Map<String, dynamic> toMap() {
    return {
      'mode': mode.key,
      'variables': variables,
      'output_directory': outputDirectory,
      'dry_run': dryRun,
    };
  }
}

/// Request for project generation.
final class ProjectGenerationRequest extends GenerationRequestDto {
  const ProjectGenerationRequest({
    required super.variables,
    required super.outputDirectory,
    super.dryRun = false,
  });

  @override
  GenerationMode get mode => GenerationMode.project;
}

/// Request for feature generation.
final class FeatureGenerationRequest extends GenerationRequestDto {
  const FeatureGenerationRequest({
    required super.variables,
    required super.outputDirectory,
    super.dryRun = false,
  });

  @override
  GenerationMode get mode => GenerationMode.feature;
}

/// Request for service generation.
final class ServiceGenerationRequest extends GenerationRequestDto {
  const ServiceGenerationRequest({
    required super.variables,
    required super.outputDirectory,
    super.dryRun = false,
  });

  @override
  GenerationMode get mode => GenerationMode.service;
}
