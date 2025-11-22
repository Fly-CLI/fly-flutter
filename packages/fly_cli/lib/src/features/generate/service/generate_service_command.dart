import 'package:fly_cli/src/core/command/foundation/application/command_base.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_validator.dart';
import 'package:fly_cli/src/core/command/foundation/flags/cli_flags.dart';
import 'package:fly_cli/src/core/command/foundation/flags/flag_accessor.dart';
import 'package:fly_cli/src/core/errors/error_codes.dart';
import 'package:fly_cli/src/core/errors/error_context.dart';
import 'package:fly_cli/src/core/middleware/domain/command_middleware.dart';
import 'package:fly_cli/src/core/templates/foundation_orchestrator.dart';
import 'package:fly_cli/src/core/templates/generation_variable_builder.dart';
import 'package:fly_cli/src/core/templates/generators/service_generator.dart';

/// GenerateServiceCommand using new architecture
class GenerateServiceCommand extends FlyCommand {
  GenerateServiceCommand(super.context);

  /// Factory constructor for enum-based command creation
  factory GenerateServiceCommand.create(CommandContext context) =>
      GenerateServiceCommand(context);

  @override
  String get name => 'service';

  @override
  String get description =>
      'Generate a new service component to the current project';

  @override
  List<CliFlag> get flags => [
        const GenerateServiceFeatureFlag(),
        const GenerateServiceTypeFlag(),
        const GenerateServiceWithTestsFlag(),
        const GenerateServiceWithMocksFlag(),
        const InteractiveFlag(),
        const GenerateServiceWithInterceptorsFlag(),
        const GenerateServiceBaseUrlFlag(),
        const OutputDirFlag(),
      ];

  @override
  List<CommandValidator> get validators => [
        RequiredArgumentValidator('service_name'),
        ServiceNameValidator(),
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

      // Build variables using ServiceVariableBuilder
      final variableBuilder = const ServiceVariableBuilder();
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
            'generate service',
            arguments: argResults?.arguments,
          ),
        );
      }
      final targetDir = outputDirResult.path!.absolute;

      // Create orchestrator and generator
      final orchestrator = TemplateGenerationOrchestrator(
        templateManager: context.templateManager,
        logger: logger,
      );
      final generator = ServiceGenerator(
        orchestrator: orchestrator,
        logger: logger,
      );

      // Generate service
      final result = await generator.generate(
        rawVars: rawVars,
        outputDirectory: targetDir,
      );

      stopwatch.stop();

      if (!result.success) {
        return CommandResult.error(
          message: result.error ?? 'Failed to generate service',
          suggestion: 'Check service brick availability and try again',
          errorCode: ErrorCode.templateGenerationFailed,
        );
      }

      // Convert GenerationResult to CommandResult
      return CommandResult.success(
        command: 'generate service',
        message: 'Service generated successfully',
        data: {
          ...result.data ?? {},
          'files_generated': result.filesGenerated,
          'duration_ms': stopwatch.elapsedMilliseconds,
        },
        nextSteps: [
          const NextStep(
            command: 'flutter run',
            description: 'Run the application to test the new service',
          ),
        ],
      );
    } catch (e) {
      return CommandResult.error(
        message: 'Failed to generate service: $e',
        suggestion: 'Check your project structure and try again',
      );
    }
  }


  // Lifecycle hooks implementation
  @override
  Future<void> onBeforeExecute(CommandContext context) async {
    logger.info('🔧 Preparing to generate service...');
  }

  @override
  Future<void> onAfterExecute(
      CommandContext context, CommandResult result) async {
    if (result.success) {
      logger.info('🎉 Service generated successfully!');
    }
  }

  @override
  Future<void> onError(
      CommandContext context, Object error, StackTrace stackTrace) async {
    logger.err('💥 Service generation failed: $error');
    if (context.verbose) {
      logger.err('Stack trace: $stackTrace');
    }
  }
}
