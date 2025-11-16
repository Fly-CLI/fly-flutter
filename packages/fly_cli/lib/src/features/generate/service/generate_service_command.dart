import 'package:fly_cli/src/core/command/foundation/application/command_base.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_validator.dart';
import 'package:fly_cli/src/core/command/foundation/flags/cli_flags.dart';
import 'package:fly_cli/src/core/command/foundation/flags/flag_accessor.dart';
import 'package:fly_cli/src/core/errors/error_codes.dart';
import 'package:fly_cli/src/core/errors/error_context.dart';
import 'package:fly_cli/src/core/middleware/domain/command_middleware.dart';
import 'package:fly_cli/src/core/templates/brick_info.dart';
import 'package:fly_cli/src/core/templates/template_manager.dart';
import 'package:fly_cli/src/core/validation/validation_rules.dart';

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
    final interactive =
        FlagAccessor.getBool(argResults, const InteractiveFlag());
    final outputDir = FlagAccessor.getString(argResults, const OutputDirFlag());

    if (interactive) {
      return _runInteractiveMode(outputDir);
    }

    return _runNonInteractiveMode(outputDir);
  }

  /// Run in interactive mode
  Future<CommandResult> _runInteractiveMode(String? outputDir) async {
    try {
      final prompter = context.interactivePrompt;

      logger..info('🔧 Generating a new service')
      ..info('');

      // 1. Service name
      final componentName = await prompter.promptString(
        prompt: 'Service name',
        validator: NameValidationRule.isValidServiceName,
        validationError:
            'Service name must contain only lowercase letters, numbers, and underscores',
      );

      // 2. Feature
      final feature = await prompter.promptString(
        prompt: 'Feature name',
        defaultValue: 'core',
        validator: NameValidationRule.isValidFeatureName,
        validationError:
            'Feature name must contain only lowercase letters, numbers, and underscores',
      );

      // 3. Service type
      final serviceType = await prompter.promptChoice(
        prompt: 'Service type',
        choices: ['api', 'local', 'cache', 'analytics', 'storage'],
        defaultChoice: 'api',
      );

      // 4. Tests
      final withTests = await prompter.promptConfirm(
        prompt: 'Include test files?',
      );

      // 5. Mocks
      final withMocks = await prompter.promptConfirm(
        prompt: 'Include mock files?',
      );

      // 6. Additional options based on service type
      var withInterceptors = false;
      var baseUrl = 'https://api.example.com';
      if (serviceType == 'api') {
        withInterceptors = await prompter.promptConfirm(
          prompt: 'Include HTTP interceptors?',
        );

        baseUrl = await prompter.promptString(
          prompt: 'Base URL',
          defaultValue: 'https://api.example.com',
        );
      }

      // 7. Confirmation
      final withRetryLogic = serviceType == 'api';
      final withCaching = serviceType == 'cache';

      logger..info('')
      ..info('Service Configuration:')
      ..info('  Name: $componentName')
      ..info('  Feature: $feature')
      ..info('  Type: $serviceType')
      ..info('  With Tests: $withTests')
      ..info('  With Mocks: $withMocks')
      ..info('  With Retry Logic: $withRetryLogic')
      ..info('  With Caching: $withCaching');
      if (serviceType == 'api') {
        logger..info('  With Interceptors: $withInterceptors')
        ..info('  Base URL: $baseUrl');
      }

      final confirmed = await prompter.promptConfirm(
        prompt: '\nCreate service with this configuration?',
      );

      if (!confirmed) {
        return CommandResult.error(
          message: 'Service creation cancelled',
          suggestion: 'Run the command again to start over',
        );
      }

      // Resolve output directory via PathResolver
      final resolvedOutputDir =
          await context.pathResolver.resolveOutputDirectory(
        context,
        outputDir,
      );

      if (!resolvedOutputDir.success) {
        return CommandResult.error(
          message:
              'Failed to resolve output directory: ${resolvedOutputDir.errors.join(', ')}',
          suggestion: 'Specify a valid --output-dir or run from a project root',
          errorCode: ErrorCode.fileSystemError,
          context: ErrorContext.forCommand(
            'generate service',
            arguments: argResults?.arguments,
          ),
        );
      }

      final targetDir = resolvedOutputDir.path!.absolute;

      // Generate service using Mason brick
      return await _generateServiceWithMason(
        serviceName: componentName,
        feature: feature,
        serviceType: serviceType,
        withTests: withTests,
        withMocks: withMocks,
        withInterceptors: withInterceptors,
        withRetryLogic: withRetryLogic,
        withCaching: withCaching,
        baseUrl: baseUrl,
        outputDir: targetDir,
      );
    } catch (e) {
      return CommandResult.error(
        message: 'Interactive mode failed: $e',
        suggestion: 'Try running without --interactive flag',
      );
    }
  }

  /// Run in non-interactive mode
  Future<CommandResult> _runNonInteractiveMode(String? outputDir) async {
    final serviceName = argResults!.rest.first;
    final feature = FlagAccessor.getStringOrDefault(
      argResults,
      const GenerateServiceFeatureFlag(),
      'core',
    );
    final serviceType = FlagAccessor.getStringOrDefault(
      argResults,
      const GenerateServiceTypeFlag(),
      'api',
    );
    final withTests =
        FlagAccessor.getBool(argResults, const GenerateServiceWithTestsFlag());
    final withMocks =
        FlagAccessor.getBool(argResults, const GenerateServiceWithMocksFlag());
    final withInterceptors = FlagAccessor.getBool(
      argResults,
      const GenerateServiceWithInterceptorsFlag(),
    );
    final withRetryLogic = serviceType == 'api';
    final withCaching = serviceType == 'cache';

    final baseUrl = FlagAccessor.getStringOrDefault(
      argResults,
      const GenerateServiceBaseUrlFlag(),
      'https://api.example.com',
    );

    // Resolve the target output directory, prioritizing --output-dir and FLY_OUTPUT_DIR.
    final outputDirResult = await context.pathResolver.resolveOutputDirectory(
      context,
      outputDir,
    );
    if (!outputDirResult.success) {
      return CommandResult.error(
        message:
            'Failed to resolve output directory: ${outputDirResult.errors.join(', ')}',
        suggestion: 'Specify a valid --output-dir or set FLY_OUTPUT_DIR',
        errorCode: ErrorCode.fileSystemError,
        context: ErrorContext.forCommand(
          'generate service',
          arguments: argResults?.arguments,
        ),
      );
    }
    final targetProjectDir = outputDirResult.path!.absolute;

    return _generateServiceWithMason(
      serviceName: serviceName,
      feature: feature,
      serviceType: serviceType,
      withTests: withTests,
      withMocks: withMocks,
      withInterceptors: withInterceptors,
      withRetryLogic: withRetryLogic,
      withCaching: withCaching,
      baseUrl: baseUrl,
      outputDir: targetProjectDir,
    );
  }

  /// Generate service using Mason brick
  Future<CommandResult> _generateServiceWithMason({
    required String serviceName,
    required String feature,
    required String serviceType,
    required bool withTests,
    required bool withMocks,
    required bool withInterceptors,
    required bool withRetryLogic,
    required bool withCaching,
    required String baseUrl,
    required String outputDir,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      logger..info('Generating service: $serviceName')
      ..info('Feature: $feature')
      ..info('Type: $serviceType')
      ..info('With tests: $withTests')
      ..info('With mocks: $withMocks')
      ..info('With retry logic: $withRetryLogic')
      ..info('With caching: $withCaching');
      if (serviceType == 'api') {
        logger..info('With interceptors: $withInterceptors')
        ..info('Base URL: $baseUrl');
      }

      // Use injected template manager
      final templateManager = context.templateManager;

      // Create service configuration for Mason brick
      final serviceConfig = <String, dynamic>{
        'component_name': serviceName,
        'feature': feature,
        'service_type': serviceType,
        'with_tests': withTests,
        'with_mocks': withMocks,
        'with_interceptors': withInterceptors,
        'with_retry_logic': withRetryLogic,
        'with_caching': withCaching,
        'base_url': baseUrl,
      };

      // Generate service using TemplateManager
      final result = await templateManager.generateComponent(
        componentName: serviceName,
        componentType: BrickType.service,
        config: serviceConfig,
        targetPath: outputDir,
      );

      stopwatch.stop();

      if (result is TemplateGenerationFailure) {
        return CommandResult.error(
          message: 'Failed to generate service: ${result.error}',
          suggestion: 'Check service brick availability and try again',
        );
      }

      if (result is! TemplateGenerationSuccess) {
        return CommandResult.error(
          message: 'Unexpected generation result',
          suggestion: 'Try again or contact support',
        );
      }

      // Count generated files
      var filesGenerated = result.filesGenerated;

      return CommandResult.success(
        command: 'generate service',
        message: 'Service generated successfully',
        data: {
          'component_name': serviceName,
          'feature': feature,
          'service_type': serviceType,
          'with_tests': withTests,
          'with_mocks': withMocks,
          'with_interceptors': withInterceptors,
          'with_retry_logic': withRetryLogic,
          'with_caching': withCaching,
          'base_url': baseUrl,
          'files_generated': filesGenerated,
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
