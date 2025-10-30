import 'package:args/args.dart' hide OptionType;
import 'package:path/path.dart' as path;

import 'package:fly_cli/src/core/command_foundation/application/command_base.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_middleware.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_validator.dart';
import 'package:fly_cli/src/core/command_metadata/command_metadata.dart';
import 'package:fly_cli/src/core/errors/error_codes.dart';
import 'package:fly_cli/src/core/errors/error_context.dart';
import 'package:fly_cli/src/core/templates/template_manager.dart';
import 'package:fly_cli/src/core/validation/validation_rules.dart';

/// CreateCommand using new architecture
class CreateCommand extends FlyCommand {
  /// Creates a new CreateCommand instance
  CreateCommand(super.context);

  /// Factory constructor for enum-based command creation
  factory CreateCommand.create(CommandContext context) => 
      CreateCommand(context);

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
        command: 'fly create my_app --template=riverpod '
            '--platforms=ios,android,web',
        description: 'Create a Riverpod project with multiple platforms',
      ),
    ],
  );

  @override
  ArgParser get argParser {
    final parser = super.argParser

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
      )
      ..addOption(
        'from-manifest',
        help: 'Create project from manifest file',
      )
      ..addOption(
        'output-dir',
        help: 'Output directory for generated files (defaults to current directory)',
        defaultsTo: null,
      );
    return parser;
  }

  @override
  List<CommandValidator> get validators => [
    RequiredArgumentValidator('project_name'),
    ProjectNameValidator(),
    TemplateExistsValidator(),
    PlatformValidator(),
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
    final outputDir = argResults!['output-dir'] as String? ?? context.workingDirectory;

    // Construct the full project path
    final projectPath = path.join(outputDir, projectName);

    if (interactive) {
      return _runInteractiveMode(
        projectName, template, organization, platforms, projectPath,
      );
    }

    return _createProject(
      projectName, template, organization, platforms, projectPath,
    );
  }

  /// Run in interactive mode
  Future<CommandResult> _runInteractiveMode(
    String projectName,
    String template,
    String organization,
    List<String> platforms,
    String projectPath,
  ) async {
    logger..info('🚀 Welcome to Fly CLI Interactive Mode')
    ..info("Let's create your Flutter project step by step.\n");

    try {
      // Use injected interactive prompt
      final prompter = context.interactivePrompt;

      // 1. Project name
      final finalProjectName = await prompter.promptString(
        prompt: 'Project name',
        defaultValue: projectName,
        validator: NameValidationRule.isValidProjectName,
        validationError: 'Project name must contain only lowercase letters, '
            'numbers, and underscores',
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
      logger..info('\n📋 Project Configuration:')
      ..info('  Name: $finalProjectName')
      ..info('  Template: $finalTemplate')
      ..info('  Organization: $finalOrganization')
      ..info('  Platforms: ${finalPlatforms.join(', ')}');

      // 6. Confirmation
      final confirmed = await prompter.promptConfirm(
        prompt: '\nCreate project with this configuration?',
      );

      if (!confirmed) {
        return CommandResult.error(
          message: 'Project creation cancelled',
          suggestion: 'Run the command again to start over',
          errorCode: ErrorCode.invalidArgumentValue,
          context: ErrorContext.forCommand(
            'create',
            arguments: argResults?.arguments,
            extra: {'interactive': true, 'cancelled': true},
          ),
        );
      }

      logger.info('\nGenerating project...\n');

      return _createProject(
        finalProjectName, finalTemplate, finalOrganization, finalPlatforms, projectPath,
      );
    } catch (e) {
      return CommandResult.error(
        message: 'Interactive mode failed: $e',
        suggestion: 'Try running without --interactive flag',
        errorCode: ErrorCode.internalError,
        context: ErrorContext.forCommand(
          'create',
          arguments: argResults?.arguments,
          extra: {'interactive': true, 'error': e.toString()},
        ),
      );
    }
  }

  /// Create the project
  Future<CommandResult> _createProject(
    String projectName,
    String template,
    String organization,
    List<String> platforms,
    String projectPath,
  ) async {
    try {
      final stopwatch = Stopwatch()..start();

      logger..info('Creating Flutter project...')
      ..info('Template: $template')
      ..info('Organization: $organization')
      ..info('Platforms: ${platforms.join(', ')}');

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
        outputDirectory: projectPath,
        variables: templateVariables,
      );

      if (generationResult is TemplateGenerationFailure) {
        return CommandResult.error(
          message: 'Failed to generate project: ${generationResult.error}',
          suggestion: 'Check template availability and try again',
          errorCode: ErrorCode.templateGenerationFailed,
          context: ErrorContext.forTemplateOperation(
            'generate_project',
            template,
            outputPath: projectName,
            variables: templateVariables.toMasonVars(),
          ),
        );
      }

      if (generationResult is! TemplateGenerationSuccess) {
        return CommandResult.error(
          message: 'Unexpected generation result',
          suggestion: 'Try again or contact support',
          errorCode: ErrorCode.internalError,
          context: ErrorContext.forTemplateOperation(
            'generate_project',
            template,
            outputPath: projectName,
          ),
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
        errorCode: ErrorCode.templateGenerationFailed,
        context: ErrorContext.forProjectOperation(
          'create_project',
          projectName,
          projectType: template,
        ),
      );
    }
  }

  // Lifecycle hooks implementation
  @override
  Future<void> onBeforeExecute(CommandContext context) async {
    logger.info('🔧 Preparing to create project...');
  }

  @override
  Future<void> onAfterExecute(
    CommandContext context, 
    CommandResult result,
  ) async {
    if (result.success) {
      logger.info('🎉 Project creation completed successfully!');
    }
  }

  @override
  Future<void> onError(
    CommandContext context, 
    Object error, 
    StackTrace stackTrace,
  ) async {
    logger.err('💥 Project creation failed: $error');
    if (context.verbose) {
      logger.err('Stack trace: $stackTrace');
    }
  }
}
