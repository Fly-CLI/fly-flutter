import 'package:fly_cli/src/cli/infrastructure/middleware/domain/command_middleware.dart';
import 'package:fly_cli/src/features/commands/application/command_base.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/features/commands/domain/command_validator.dart';
import 'package:fly_cli/src/features/commands/infrastructure/flags/cli_flags.dart';
import 'package:fly_cli/src/features/commands/infrastructure/flags/flag_accessor.dart';
import 'package:fly_cli/src/features/generate/common/generation_command_handler.dart';
import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/generation/generation_variable_builder.dart';
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

      // Build variables using ServiceVariableBuilder
      // Use execution context's argResults (set by CommandRunner) instead of registration context
      final executionContext = context.factory.createExecutionContext(
        argResults!,
      );
      const variableBuilder = ServiceVariableBuilder();
      final rawVars = await variableBuilder.buildFromContext(
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

      // Get generation handler from service container
      final handler = context.getService<GenerationCommandHandler>();

      // Extract properties from rawVars and construct request
      final request = ServiceGenerationRequest(
        name: rawVars['name'] as String,
        feature: rawVars['feature'] as String? ?? 'core',
        serviceType: ServiceType.tryFromKey(
          rawVars['service_type'] as String?,
          defaultValue: ServiceType.api,
        ) ?? ServiceType.api,
        withTests: rawVars['with_tests'] as bool? ?? true,
        withMocks: rawVars['with_mocks'] as bool? ?? false,
        withInterceptors: rawVars['with_interceptors'] as bool? ?? false,
        apiBaseUrl: rawVars['api_base_url'] as String?,
        preset: rawVars['preset'] as String? ?? 'starter',
        outputDirectory: targetDir,
        dryRun: context.planMode,
      );

      // Generate service
      final result = await handler.executeService(request);

      stopwatch.stop();

      // Result is already a CommandResult from the handler
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
