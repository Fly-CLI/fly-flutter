import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';

/// Data Transfer Object for generation requests.
///
/// Used to transfer data between presentation and application layers.
class GenerationRequestDto {
  const GenerationRequestDto({
    required this.mode,
    required this.variables,
    required this.outputDirectory,
    this.dryRun = false,
  });

  /// Generation mode (project, feature, service)
  final GenerationMode mode;

  /// Input variables for generation
  final Map<String, dynamic> variables;

  /// Output directory where files should be generated
  final String outputDirectory;

  /// Whether this is a dry run (preview only)
  final bool dryRun;

  /// Create from a map (e.g., from CLI flags or MCP params)
  factory GenerationRequestDto.fromMap({
    required GenerationMode mode,
    required Map<String, dynamic> variables,
    required String outputDirectory,
    bool dryRun = false,
  }) {
    return GenerationRequestDto(
      mode: mode,
      variables: variables,
      outputDirectory: outputDirectory,
      dryRun: dryRun,
    );
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

