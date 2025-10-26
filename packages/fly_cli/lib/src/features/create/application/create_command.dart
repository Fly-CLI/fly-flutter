import 'dart:io';
import 'package:args/args.dart' hide OptionType;

import 'package:fly_cli/src/core/command_foundation/application/command_base.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_validator.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_middleware.dart';
import '../../schema/domain/command_definition.dart' show ArgumentDefinition, CommandDefinition, CommandExample, OptionDefinition, OptionType;
import 'package:fly_cli/src/core/templates/template_manager.dart';

/// CreateCommand using new architecture
class CreateCommand extends FlyCommand {
  CreateCommand(CommandContext context) : super(context);

  @override
  String get name => 'create';

  @override
  String get description => 'Create a new Flutter project';

  @override
  CommandDefinition? get metadata => CommandDefinition(
    name: name,
    description: description,
    arguments: [
      const ArgumentDefinition(
        name: 'project_name',
        description: 'Name of the Flutter project to create',
      ),
    ],
    options: [
      const OptionDefinition(
        name: 'template',
        description: 'Project template to use',
        type: OptionType.value,
        short: 't',
        allowedValues: ['minimal', 'riverpod'],
        defaultValue: 'riverpod',
      ),
      const OptionDefinition(
        name: 'organization',
        description: 'Organization identifier (e.g., com.example)',
        type: OptionType.value,
        short: 'o',
        defaultValue: 'com.example',
      ),
      const OptionDefinition(
        name: 'platforms',
        description: 'Target platforms for the project',
        type: OptionType.value,
        allowedValues: ['ios', 'android', 'web', 'macos', 'windows', 'linux'],
        defaultValue: 'ios,android',
      ),
      const OptionDefinition(
        name: 'interactive',
        description: 'Run in interactive mode to configure project settings',
        short: 'i',
      ),
    ],
    examples: [
      const CommandExample(
        command: 'fly create my_app --template=minimal',
        description: 'Create a minimal Flutter project',
      ),
      const CommandExample(
        command: 'fly create my_app --template=riverpod --platforms=ios,android,web',
        description: 'Create a Riverpod project with multiple platforms',
      ),
    ],
  );

  @override
  ArgParser get argParser {
    final parser = super.argParser;
    parser
      ..addOption(
        'template',
        abbr: 't',
        help: 'Project template to use',
        allowed: ['minimal', 'riverpod'],
        defaultsTo: 'riverpod',
      )
      ..addOption(
        'organization',
        abbr: 'o',
        help: 'Organization identifier',
        defaultsTo: 'com.example',
      )
      ..addMultiOption(
        'platforms',
        help: 'Target platforms',
        allowed: ['ios', 'android', 'web', 'macos', 'windows', 'linux'],
        defaultsTo: ['ios', 'android'],
      )
      ..addFlag(
        'interactive',
        abbr: 'i',
        help: 'Run in interactive mode',
        negatable: false,
      );
    return parser;
  }

  @override
  List<CommandValidator> get validators => [
    RequiredArgumentValidator('project_name'),
    ProjectNameValidator(),
    TemplateExistsValidator(),
    DirectoryWritableValidator(),
    EnvironmentValidator(),
  ];

  @override
  List<CommandMiddleware> get middleware => [
    LoggingMiddleware(),
    MetricsMiddleware(),
    DryRunMiddleware(),
    CachingMiddleware(),
  ];

  @override
  Future<CommandResult> execute() async {
    final projectName = argResults!.rest.first;
    final template = argResults!['template'] as String;
    final organization = argResults!['organization'] as String;
    final platforms = argResults!['platforms'] as List<String>;
    final interactive = argResults!['interactive'] as bool;

    if (interactive) {
      return _runInteractiveMode(projectName, template, organization, platforms);
    }

    return _createProject(projectName, template, organization, platforms);
  }

  /// Run in interactive mode
  Future<CommandResult> _runInteractiveMode(
    String projectName,
    String template,
    String organization,
    List<String> platforms,
  ) async {
    logger.info('🚀 Welcome to Fly CLI Interactive Mode');
    logger.info("Let's create your Flutter project step by step.\n");

    try {
      // Use injected interactive prompt
      final prompter = context.interactivePrompt;

      // 1. Project name
      final finalProjectName = await prompter.promptString(
        prompt: 'Project name',
        defaultValue: projectName,
        validator: _isValidProjectName,
        validationError: 'Project name must contain only lowercase letters, numbers, and underscores',
      );

      // 2. Template selection
      final finalTemplate = await prompter.promptChoice(
        prompt: 'Select template',
        choices: ['minimal', 'riverpod'],
        defaultChoice: template,
      );

      // 3. Organization
      final finalOrganization = await prompter.promptString(
        prompt: 'Organization identifier',
        defaultValue: organization,
      );

      // 4. Platforms
      final finalPlatforms = await prompter.promptMultiChoice(
        prompt: 'Select target platforms',
        choices: ['ios', 'android', 'web', 'macos', 'windows', 'linux'],
        defaultChoices: platforms,
      );

      // 5. Display summary
      logger.info('\n📋 Project Configuration:');
      logger.info('  Name: $finalProjectName');
      logger.info('  Template: $finalTemplate');
      logger.info('  Organization: $finalOrganization');
      logger.info('  Platforms: ${finalPlatforms.join(', ')}');

      // 6. Confirmation
      final confirmed = await prompter.promptConfirm(
        prompt: '\nCreate project with this configuration?',
      );

      if (!confirmed) {
        return CommandResult.error(
          message: 'Project creation cancelled',
          suggestion: 'Run the command again to start over',
        );
      }

      logger.info('\nGenerating project...\n');

      return _createProject(finalProjectName, finalTemplate, finalOrganization, finalPlatforms);
    } catch (e) {
      return CommandResult.error(
        message: 'Interactive mode failed: $e',
        suggestion: 'Try running without --interactive flag',
      );
    }
  }

  /// Create the project
  Future<CommandResult> _createProject(
    String projectName,
    String template,
    String organization,
    List<String> platforms,
  ) async {
    try {
      final stopwatch = Stopwatch()..start();

      logger.info('Creating Flutter project...');
      logger.info('Template: $template');
      logger.info('Organization: $organization');
      logger.info('Platforms: ${platforms.join(', ')}');

      // Use injected template manager
      final templateManager = context.templateManager;

      // Create template variables
      final templateVariables = TemplateVariables(
        projectName: projectName,
        organization: organization,
        platforms: platforms,
      );

      // Generate project using template manager
      final generationResult = await templateManager.generateProject(
        templateName: template,
        projectName: projectName,
        outputDirectory: context.workingDirectory,
        variables: templateVariables,
      );

      if (generationResult is TemplateGenerationFailure) {
        return CommandResult.error(
          message: 'Failed to generate project: ${generationResult.error}',
          suggestion: 'Check template availability and try again',
        );
      }

      if (generationResult is! TemplateGenerationSuccess) {
        return CommandResult.error(
          message: 'Unexpected generation result',
          suggestion: 'Try again or contact support',
        );
      }

      stopwatch.stop();

      return CommandResult.success(
        command: 'create',
        message: 'Project created successfully',
        data: {
          'project_name': projectName,
          'template': template,
          'organization': organization,
          'platforms': platforms,
          'files_generated': generationResult.filesGenerated,
          'duration_ms': stopwatch.elapsedMilliseconds,
          'target_directory': generationResult.targetDirectory,
        },
        nextSteps: [
          NextStep(
            command: 'cd $projectName',
            description: 'Navigate to project directory',
          ),
          const NextStep(
            command: 'flutter run',
            description: 'Run the application',
          ),
        ],
      );
    } catch (e) {
      return CommandResult.error(
        message: 'Failed to create project: $e',
        suggestion: 'Check your Flutter installation and try again',
      );
    }
  }

  /// Validate project name
  bool _isValidProjectName(String name) {
    final regex = RegExp(r'^[a-z][a-z0-9_]*$');
    return regex.hasMatch(name) && name.length <= 50;
  }

  // Lifecycle hooks implementation
  @override
  Future<void> onBeforeExecute(CommandContext context) async {
    logger.info('🔧 Preparing to create project...');
  }

  @override
  Future<void> onAfterExecute(CommandContext context, CommandResult result) async {
    if (result.success) {
      logger.info('🎉 Project creation completed successfully!');
    }
  }

  @override
  Future<void> onError(CommandContext context, Object error, StackTrace stackTrace) async {
    logger.err('💥 Project creation failed: $error');
    if (context.verbose) {
      logger.err('Stack trace: $stackTrace');
    }
  }
}
