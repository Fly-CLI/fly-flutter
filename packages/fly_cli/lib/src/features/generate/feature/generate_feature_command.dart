import 'package:fly_cli/src/core/command/foundation/application/command_base.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_validator.dart';
import 'package:fly_cli/src/core/command/foundation/flags/cli_flags.dart';
import 'package:fly_cli/src/core/command/foundation/flags/flag_accessor.dart';
import 'package:fly_cli/src/core/errors/error_codes.dart';
import 'package:fly_cli/src/core/errors/error_context.dart';
import 'package:fly_cli/src/core/middleware/domain/command_middleware.dart';
import 'package:fly_cli/src/core/templates/generation/generation_variable_builder.dart';
import 'package:fly_cli/src/core/templates/generators/feature_generator.dart';

/// GenerateFeatureCommand using new architecture
class GenerateFeatureCommand extends FlyCommand {
  GenerateFeatureCommand(super.context);

  /// Factory constructor for enum-based command creation
  factory GenerateFeatureCommand.create(CommandContext context) =>
      GenerateFeatureCommand(context);

  @override
  String get name => 'feature';

  @override
  String get description =>
      'Generate a new feature (screen) component for the current project';

  // @override
  // CommandDefinition? get metadata => null;

  @override
  List<CliFlag> get flags => [
        const GenerateScreenFeatureFlag(),
        const GenerateScreenTypeFlag(),
        const GenerateScreenWithViewModelFlag(),
        const GenerateScreenWithTestsFlag(),
        const InteractiveFlag(),
        const GenerateScreenWithValidationFlag(),
        const GenerateScreenWithNavigationFlag(),
        const OutputDirFlag(),
      ];

  @override
  List<CommandValidator> get validators => [
        RequiredArgumentValidator('screen_name'),
        ScreenNameValidator(),
        FlutterProjectValidator(),
        DirectoryWritableValidator(),
      ];

  @override
  List<CommandMiddleware> get middleware => [];

  @override
  Future<CommandResult> execute() async {
    try {
      final stopwatch = Stopwatch()..start();
      final interactive =
          FlagAccessor.getBool(argResults, const InteractiveFlag());
      final outputDir = FlagAccessor.getString(argResults, const OutputDirFlag());

      // Build variables using FeatureVariableBuilder
      const variableBuilder = FeatureVariableBuilder();
      final rawVars = await variableBuilder.buildFromContext(
        context: context,
        interactive: interactive,
        outputDir: outputDir,
      );

      // Validate variables
      final validationResult = variableBuilder.validate(rawVars);
      if (!validationResult.isValid) {
        return CommandResult.error(
          message: 'Validation failed: ${validationResult.errors.join(', ')}',
          suggestion: 'Check your input and try again',
          errorCode: ErrorCode.invalidArgumentValue,
        );
      }

      // Resolve output directory
      final outputDirResult = await context.pathResolver.resolveOutputDirectory(
        context,
        outputDir,
      );
      if (!outputDirResult.success) {
        return CommandResult.error(
          message:
              'Failed to resolve output directory: ${outputDirResult.errors.join(', ')}',
          suggestion: 'Specify a valid --output-dir or run from a project root',
          errorCode: ErrorCode.fileSystemError,
          context: ErrorContext.forCommand(
            'generate feature',
            arguments: argResults?.arguments,
          ),
        );
      }
      final targetDir = outputDirResult.path!.absolute;

      // Create generator (which uses GenerationService internally)
      final generator = FeatureGenerator(
        context: context,
        logger: logger,
      );

      // Generate feature
      final result = await generator.generate(
        rawVars: rawVars,
        outputDirectory: targetDir,
      );

      stopwatch.stop();

      if (!result.success) {
        return CommandResult.error(
          message: result.error ?? 'Failed to generate feature component',
          suggestion: 'Check feature brick availability and try again',
          errorCode: ErrorCode.templateGenerationFailed,
        );
      }

      // Convert GenerationResult to CommandResult
      return CommandResult.success(
        command: 'generate feature',
        message: 'Feature component generated successfully',
        data: {
          ...result.data ?? {},
          'files_generated': result.filesGenerated,
          'duration_ms': stopwatch.elapsedMilliseconds,
        },
        nextSteps: [
          const NextStep(
            command: 'flutter run',
            description: 'Run the application to see the new screen',
          ),
        ],
      );
    } catch (e) {
      return CommandResult.error(
        message: 'Failed to generate feature component: $e',
        suggestion: 'Check your project structure and try again',
      );
    }
  }

  // Lifecycle hooks implementation
  @override
  Future<void> onBeforeExecute(CommandContext context) async {
    logger.info('🔧 Preparing to generate feature component...');
  }

  @override
  Future<void> onAfterExecute(
      CommandContext context, CommandResult result) async {
    if (result.success) {
      logger.info('🎉 Feature component generated successfully!');
    }
  }

  @override
  Future<void> onError(
      CommandContext context, Object error, StackTrace stackTrace) async {
    logger.err('💥 Feature generation failed: $error');
    if (context.verbose) {
      logger.err('Stack trace: $stackTrace');
    }
  }
}
