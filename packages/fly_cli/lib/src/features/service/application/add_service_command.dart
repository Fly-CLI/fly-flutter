import 'package:args/args.dart';
import 'package:fly_cli/src/core/command_foundation/application/command_base.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_middleware.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_validator.dart';
import 'package:fly_cli/src/core/templates/models/brick_info.dart';
import 'package:fly_cli/src/core/templates/template_manager.dart';
import 'package:fly_cli/src/core/validation/validation_rules.dart';

/// AddServiceCommand using new architecture
class AddServiceCommand extends FlyCommand {
  AddServiceCommand(super.context);

  /// Factory constructor for enum-based command creation
  factory AddServiceCommand.create(CommandContext context) => AddServiceCommand(context);

  @override
  String get name => 'service';

  @override
  String get description => 'Add a new service component to the current project';

  @override
  ArgParser get argParser {
    final parser = super.argParser

      ..addOption(
        'feature',
        help: 'Feature name',
        defaultsTo: 'core',
      )
      ..addOption(
        'type',
        abbr: 't',
        help: 'Service type',
        allowed: ['api', 'local', 'cache', 'analytics', 'storage'],
        defaultsTo: 'api',
      )
      ..addFlag(
        'with-tests',
        help: 'Include test files',
      )
      ..addFlag(
        'with-mocks',
        help: 'Include mock files',
      )
      ..addFlag(
        'interactive',
        abbr: 'i',
        help: 'Run in interactive mode',
        negatable: false,
      )
      ..addFlag(
        'with-interceptors',
        help: 'Include HTTP interceptors (for API services)',
      )
      ..addOption(
        'base-url',
        help: 'Base URL for API services',
        defaultsTo: 'https://api.example.com',
      );
    return parser;
  }

  @override
  List<CommandValidator> get validators => [
    RequiredArgumentValidator('service_name'),
    ServiceNameValidator(),
    FlutterProjectValidator(),
    DirectoryWritableValidator(),
  ];

  @override
  List<CommandMiddleware> get middleware => [
    LoggingMiddleware(),
    MetricsMiddleware(),
    DryRunMiddleware(),
  ];

  @override
  Future<CommandResult> execute() async {
    final interactive = argResults!['interactive'] as bool? ?? false;
    
    if (interactive) {
      return _runInteractiveMode();
    }
    
    return _runNonInteractiveMode();
  }

  /// Run in interactive mode
  Future<CommandResult> _runInteractiveMode() async {
    try {
      final prompter = context.interactivePrompt;
      
      logger.info('🔧 Adding a new service');
      logger.info('');
      
      // 1. Service name
      final serviceName = await prompter.promptString(
        prompt: 'Service name',
        validator: NameValidationRule.isValidServiceName,
        validationError: 'Service name must contain only lowercase letters, numbers, and underscores',
      );
      
      // 2. Feature
      final feature = await prompter.promptString(
        prompt: 'Feature name',
        defaultValue: 'core',
        validator: NameValidationRule.isValidFeatureName,
        validationError: 'Feature name must contain only lowercase letters, numbers, and underscores',
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
      logger.info('');
      logger.info('Service Configuration:');
      logger.info('  Name: $serviceName');
      logger.info('  Feature: $feature');
      logger.info('  Type: $serviceType');
      logger.info('  With Tests: $withTests');
      logger.info('  With Mocks: $withMocks');
      if (serviceType == 'api') {
        logger.info('  With Interceptors: $withInterceptors');
        logger.info('  Base URL: $baseUrl');
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
      
      // Generate service using Mason brick
      return await _generateServiceWithMason(
        serviceName: serviceName,
        feature: feature,
        serviceType: serviceType,
        withTests: withTests,
        withMocks: withMocks,
        withInterceptors: withInterceptors,
        baseUrl: baseUrl,
      );
    } catch (e) {
      return CommandResult.error(
        message: 'Interactive mode failed: $e',
        suggestion: 'Try running without --interactive flag',
      );
    }
  }

  /// Run in non-interactive mode
  Future<CommandResult> _runNonInteractiveMode() async {
    final serviceName = argResults!.rest.first;
    final feature = argResults!['feature'] as String? ?? 'core';
    final serviceType = argResults!['type'] as String? ?? 'api';
    final withTests = argResults!['with-tests'] as bool? ?? false;
    final withMocks = argResults!['with-mocks'] as bool? ?? false;
    final withInterceptors = argResults!['with-interceptors'] as bool? ?? false;
    final baseUrl = argResults!['base-url'] as String? ?? 'https://api.example.com';

    return _generateServiceWithMason(
      serviceName: serviceName,
      feature: feature,
      serviceType: serviceType,
      withTests: withTests,
      withMocks: withMocks,
      withInterceptors: withInterceptors,
      baseUrl: baseUrl,
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
    required String baseUrl,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      logger.info('Adding service: $serviceName');
      logger.info('Feature: $feature');
      logger.info('Type: $serviceType');
      logger.info('With tests: $withTests');
      logger.info('With mocks: $withMocks');
      if (serviceType == 'api') {
        logger.info('With interceptors: $withInterceptors');
        logger.info('Base URL: $baseUrl');
      }

      // Use injected template manager
      final templateManager = context.templateManager;

      // Create service configuration for Mason brick
      final serviceConfig = <String, dynamic>{
        'service_name': serviceName,
        'feature': feature,
        'service_type': serviceType,
        'with_tests': withTests,
        'with_mocks': withMocks,
        'with_interceptors': withInterceptors,
        'base_url': baseUrl,
      };

      // Generate service using TemplateManager
      final result = await templateManager.generateComponent(
        componentName: serviceName,
        componentType: BrickType.service,
        config: serviceConfig,
        targetPath: context.workingDirectory,
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
        command: 'service',
        message: 'Service added successfully',
        data: {
          'service_name': serviceName,
          'feature': feature,
          'service_type': serviceType,
          'with_tests': withTests,
          'with_mocks': withMocks,
          'with_interceptors': withInterceptors,
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
        message: 'Failed to add service: $e',
        suggestion: 'Check your project structure and try again',
      );
    }
  }

  // Lifecycle hooks implementation
  @override
  Future<void> onBeforeExecute(CommandContext context) async {
    logger.info('🔧 Preparing to add service...');
  }

  @override
  Future<void> onAfterExecute(CommandContext context, CommandResult result) async {
    if (result.success) {
      logger.info('🎉 Service added successfully!');
    }
  }

  @override
  Future<void> onError(CommandContext context, Object error, StackTrace stackTrace) async {
    logger.err('💥 Service creation failed: $error');
    if (context.verbose) {
      logger.err('Stack trace: $stackTrace');
    }
  }
}
