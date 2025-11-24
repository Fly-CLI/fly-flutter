
import 'package:fly_cli/src/cli/infrastructure/middleware/domain/command_middleware.dart';
import 'package:fly_cli/src/features/commands/application/command_base.dart';
import 'package:fly_cli/src/features/commands/domain/command_validator.dart';

/// Base class for generation commands.
///
/// Provides common functionality for all generation commands,
/// including variable building, validation, and result handling.
abstract class GenerationCommandBase extends FlyCommand {
  GenerationCommandBase(super.context);

  /// Get the generation mode (feature, service, project).
  String get generationMode;

  /// Build variables from command context.
  ///
  /// Subclasses should implement this to build variables specific
  /// to their generation type.
  Future<Map<String, dynamic>> buildVariables({
    required bool interactive,
    String? outputDir,
  });

  /// Validate variables.
  ///
  /// Subclasses should implement this to validate variables specific
  /// to their generation type.
  bool validateVariables(Map<String, dynamic> variables);

  /// Get output directory from flags or resolve default.
  Future<String?> resolveOutputDirectory(String? outputDir) async {
    if (outputDir != null) {
      return outputDir;
    }

    final result = await context.pathResolver.resolveOutputDirectory(
      context,
      outputDir,
    );

    if (!result.success) {
      return null;
    }

    return result.path?.absolute;
  }

  @override
  List<CommandValidator> get validators => [
        RequiredArgumentValidator('component_name'),
        FlutterProjectValidator(),
        DirectoryWritableValidator(),
      ];

  @override
  List<CommandMiddleware> get middleware => [];
}

