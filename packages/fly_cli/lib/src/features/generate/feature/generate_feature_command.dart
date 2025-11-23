import 'package:fly_cli/src/core/command/foundation/application/command_base.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_validator.dart';
import 'package:fly_cli/src/core/command/foundation/flags/cli_flags.dart';
import 'package:fly_cli/src/core/command/foundation/flags/flag_accessor.dart';
import 'package:fly_cli/src/core/errors/error_codes.dart';
import 'package:fly_cli/src/core/errors/error_context.dart';
import 'package:fly_cli/src/core/middleware/domain/command_middleware.dart';
import 'package:fly_cli/src/core/generation/generation/generation_variable_builder.dart';
import 'package:fly_cli/src/features/generate/common/generation_command_handler.dart';

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
      // Use execution context's argResults (set by CommandRunner) instead of registration context
      final executionContext = context.factory.createExecutionContext(argResults!);
      const variableBuilder = FeatureVariableBuilder();
      final rawVars = await variableBuilder.buildFromContext(
        context: executionContext,
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

      // Get generation handler from service container
      final handler = context.getService<GenerationCommandHandler>();

      // Generate feature
      final result = await handler.executeFeature(
        variables: rawVars,
        outputDirectory: targetDir,
        dryRun: context.planMode,
      );

      stopwatch.stop();

      // Result is already a CommandResult from the handler
      // Add timing information
      if (result.success && result.data != null) {
        result.data!['duration_ms'] = stopwatch.elapsedMilliseconds;
      }
      return result;
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
