import 'package:fly_cli/src/cli/infrastructure/middleware/domain/command_middleware.dart';
import 'package:fly_cli/src/features/commands/application/command_base.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/features/commands/domain/command_validator.dart';
import 'package:fly_cli/src/features/commands/infrastructure/flags/cli_flags.dart';
import 'package:fly_cli/src/features/commands/infrastructure/flags/flag_accessor.dart';
import 'package:fly_cli/src/features/generate/common/generation_result_mapper.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_executor_registry.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/shared/errors/domain/error_codes.dart';
import 'package:fly_cli/src/shared/errors/domain/error_context.dart';

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
      final interactive = FlagAccessor.getBool(
        argResults,
        const InteractiveFlag(),
      );
      final outputDir = FlagAccessor.getString(
        argResults,
        const OutputDirFlag(),
      );

      // Get generation registry from service container
      final registry = context.getService<GenerationExecutorRegistry>();

      // Get profile for service mode (single source of truth)
      final profile = registry.getProfile(GenerationMode.service);
      if (profile == null) {
        return CommandResult.error(
          message: 'No profile found for generation mode: service',
          suggestion: 'Verify that the generation mode is properly registered',
          errorCode: ErrorCode.invalidArgumentValue,
        );
      }

      // Build variables using builder from profile
      // Use execution context's argResults (set by CommandRunner) instead of registration context
      final executionContext = context.factory.createExecutionContext(
        argResults!,
      );
      final rawVars = await profile.variableBuilder.buildFromContext(
        context: executionContext,
        interactive: interactive,
        outputDir: outputDir,
      );

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

      // Construct request using factory from profile
      final request = profile.requestFactory.createRequest(
        variables: rawVars,
        outputDirectory: targetDir,
        dryRun: context.planMode,
      );

      // Execute generation via registry
      final generationResult = await registry.execute(request);

      stopwatch.stop();

      // Convert generation result to command result
      final strategy = registry.getStrategy(GenerationMode.service);
      final result = GenerationResultMapper.toCommandResult(
        generationResult,
        GenerationMode.service,
        strategy,
      );

      // Add timing information
      if (result.success && result.data != null) {
        result.data!['duration_ms'] = stopwatch.elapsedMilliseconds;
      }
      return result;
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
    CommandContext context,
    CommandResult result,
  ) async {
    if (result.success) {
      logger.info('🎉 Service generated successfully!');
    }
  }

  @override
  Future<void> onError(
    CommandContext context,
    Object error,
    StackTrace stackTrace,
  ) async {
    logger.err('💥 Service generation failed: $error');
    if (context.verbose) {
      logger.err('Stack trace: $stackTrace');
    }
  }
}
