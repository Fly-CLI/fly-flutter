import 'package:fly_cli/src/generation/domain/entities/brick.dart';
import 'package:fly_cli/src/generation/generators/generation_result.dart';

/// Interface for code generation engines.
///
/// Abstracts the actual code generation process, allowing different
/// implementations (Mason, custom generators, etc.).
abstract class IGenerationEngine {
  /// Generate code from a brick.
  ///
  /// [brick] is the brick to use for generation.
  /// [variables] are the variables to pass to the brick.
  /// [outputDirectory] is where files should be generated.
  /// [dryRun] if true, generates a preview instead of actual files.
  ///
  /// Returns a [GenerationResult] with success status and generated files.
  Future<GenerationResult> generate({
    required Brick brick,
    required Map<String, dynamic> variables,
    required String outputDirectory,
    bool dryRun = false,
  });

  /// Generate a preview of what would be generated.
  ///
  /// Returns a preview without actually creating files.
  Future<GenerationResult> preview({
    required Brick brick,
    required Map<String, dynamic> variables,
    required String outputDirectory,
  });
}

