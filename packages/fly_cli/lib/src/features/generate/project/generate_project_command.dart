import 'package:fly_cli/src/core/command/foundation/application/command_base.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_validator.dart';
import 'package:fly_cli/src/core/command/foundation/flags/cli_flags.dart';
import 'package:fly_cli/src/core/command/foundation/flags/flag_accessor.dart';
import 'package:fly_cli/src/core/command/metadata/command_metadata.dart';
import 'package:fly_cli/src/core/errors/error_codes.dart';
import 'package:fly_cli/src/core/errors/error_context.dart';
import 'package:fly_cli/src/core/manifest/manifest_parser.dart';
import 'package:fly_cli/src/core/middleware/domain/command_middleware.dart';
import 'package:fly_cli/src/core/middleware/infrastructure/optional/caching_middleware.dart';
import 'package:fly_cli/src/core/templates/foundation_orchestrator.dart';
import 'package:fly_cli/src/core/templates/template_manager.dart';
import 'package:fly_cli/src/core/validation/validation_rules.dart';

/// GenerateProjectCommand using new architecture
class GenerateProjectCommand extends FlyCommand {
  /// Creates a new GenerateProjectCommand instance
  GenerateProjectCommand(super.context);

  /// Factory constructor for enum-based command creation
  factory GenerateProjectCommand.create(CommandContext context) =>
      GenerateProjectCommand(context);

  @override
  String get name => 'project';

  @override
  String get description => 'Generate a new Flutter project';

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
        options: flags,
        examples: [
          const CommandExample(
            command:
                'fly generate project my_app --template=fly_foundation --platforms=ios,android,web',
            description: 'Create a Fly foundation project',
          ),
          const CommandExample(
            command:
                'fly generate project my_app --features=home,profile,settings',
            description: 'Create a project with multiple features',
          ),
        ],
      );

  @override
  List<CliFlag> get flags => [
        const CreateTemplateFlag(),
        const CreateOrganizationFlag(),
        const CreateDescriptionFlag(),
        CreatePlatformsFlag(),
        CreateFeaturesFlag(),
        const InteractiveFlag(),
        const CreateFromManifestFlag(),
        const OutputDirFlag(),
      ];

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
        CachingMiddleware(),
      ];

  @override
  Future<CommandResult> execute() async {
    // Check if manifest-based generation is requested
    final manifestPath = FlagAccessor.getString(
      argResults,
      const CreateFromManifestFlag(),
    );

    if (manifestPath != null) {
      return _executeFromManifest(manifestPath);
    }

    // Standard flag-based generation
    final projectName = argResults!.rest.first;
    final template = FlagAccessor.getStringOrDefault(
      argResults,
      const CreateTemplateFlag(),
      'fly_foundation',
    );
    final organization = FlagAccessor.getStringOrDefault(
      argResults,
      const CreateOrganizationFlag(),
      'com.example',
    );
    final description = FlagAccessor.getString(
      argResults,
      const CreateDescriptionFlag(),
    );
    final platforms = FlagAccessor.getStringList(
      argResults,
      CreatePlatformsFlag(),
    );
    final features = FlagAccessor.getStringList(
      argResults,
      CreateFeaturesFlag(),
    );
    final interactive = FlagAccessor.getBool(
      argResults,
      const InteractiveFlag(),
    );
    final outputDir = FlagAccessor.getString(argResults, const OutputDirFlag());

    // Use PathResolver to resolve project path
    final projectPathResult = await context.pathResolver.resolveProjectPath(
      context,
      projectName,
      outputDir,
    );

    if (!projectPathResult.success) {
      return CommandResult.error(
        message:
            'Failed to resolve project path: ${projectPathResult.errors.join(', ')}',
        suggestion: 'Check your output directory and permissions',
        errorCode: ErrorCode.fileSystemError,
        context: ErrorContext.forCommand(
          'generate project',
          arguments: argResults?.arguments,
        ),
      );
    }

    final projectPath = projectPathResult.path!;

    if (interactive) {
      return _runInteractiveMode(
        projectName,
        template,
        organization,
        description ?? '',
        platforms,
        features,
        projectPath.absolute,
      );
    }

    return _createProject(
      projectName: projectName,
      template: template,
      organization: organization,
      description: description ?? '',
      platforms: platforms,
      features: features,
      services: const [],
      projectPath: projectPath.absolute,
    );
  }

  /// Execute project generation from manifest file
  Future<CommandResult> _executeFromManifest(String manifestPath) async {
    try {
      // Parse manifest
      final manifest = await ProjectManifest.fromFile(manifestPath);

      // Warn if CLI flags are also provided (manifest takes precedence)
      final hasCliFlags = FlagAccessor.getString(
                argResults,
                const CreateOrganizationFlag(),
              ) !=
              null ||
          FlagAccessor.getStringList(
            argResults,
            CreatePlatformsFlag(),
          ).isNotEmpty ||
          FlagAccessor.getStringList(
            argResults,
            CreateFeaturesFlag(),
          ).isNotEmpty;

      if (hasCliFlags) {
        logger.warn(
          '⚠️  Manifest file provided. CLI flags (--organization, --platforms, --features) will be ignored in favor of manifest values.',
        );
      }

      // Extract project name from manifest (required)
      final projectName = manifest.name;

      // Resolve output directory
      final outputDir =
          FlagAccessor.getString(argResults, const OutputDirFlag());
      final projectPathResult = await context.pathResolver.resolveProjectPath(
        context,
        projectName,
        outputDir,
      );

      if (!projectPathResult.success) {
        return CommandResult.error(
          message:
              'Failed to resolve project path: ${projectPathResult.errors.join(', ')}',
          suggestion: 'Check your output directory and permissions',
          errorCode: ErrorCode.fileSystemError,
          context: ErrorContext.forCommand(
            'generate project',
            arguments: argResults?.arguments,
          ),
        );
      }

      final projectPath = projectPathResult.path!;

      // Convert manifest screens to feature instances
      final featureInstances =
          _convertScreensToFeatureInstances(manifest.screens);

      // If no screens, use default home feature
      if (featureInstances.isEmpty) {
        featureInstances.add({
          'name': 'home',
          'type': 'feature',
          'params': {
            'feature': 'home',
            'screen_type': 'list',
            'with_viewmodel': true,
            'with_tests': manifest.config.generateTests,
            'with_validation': false,
            'with_navigation': false,
          },
        });
      }

      // Convert manifest services to service instances
      final serviceInstances =
          _convertServicesToServiceInstances(manifest.services);

      // Determine preset from manifest config or default
      final preset = _determinePresetFromManifest(manifest.config);

      return _createProject(
        projectName: projectName,
        template: manifest.template,
        organization: manifest.organization,
        description: manifest.description ?? 'A new Flutter project',
        platforms: manifest.platforms,
        features: featureInstances.map((f) => f['name'] as String).toList(),
        services: serviceInstances,
        preset: preset,
        projectPath: projectPath.absolute,
      );
    } on ManifestException catch (e) {
      return CommandResult.error(
        message: 'Failed to parse manifest: $e',
        suggestion: 'Check the manifest file format and try again',
        errorCode: ErrorCode.invalidArgumentValue,
        context: ErrorContext.forCommand(
          'generate project',
          arguments: argResults?.arguments,
        ),
      );
    } catch (e) {
      return CommandResult.error(
        message: 'Failed to load manifest: $e',
        suggestion: 'Check that the manifest file exists and is readable',
        errorCode: ErrorCode.fileSystemError,
        context: ErrorContext.forCommand(
          'generate project',
          arguments: argResults?.arguments,
        ),
      );
    }
  }

  /// Convert manifest screens to feature instance configs
  List<Map<String, dynamic>> _convertScreensToFeatureInstances(
    List<ScreenConfig> screens,
  ) {
    return screens.map((screen) {
      // Extract feature from screen (default to screen name if no features specified)
      final feature =
          screen.features.isNotEmpty ? screen.features.first : screen.name;

      return {
        'name': screen.name,
        'type': 'feature',
        'params': {
          'feature': feature,
          'screen_type': screen.type ?? 'list',
          'with_viewmodel': true,
          'with_tests': true, // Will be overridden by preset if needed
          'with_validation': screen.type == 'form',
          'with_navigation': false,
        },
      };
    }).toList();
  }

  /// Convert manifest services to service instance configs
  List<Map<String, dynamic>> _convertServicesToServiceInstances(
    List<ServiceConfig> services,
  ) {
    return services.map((service) {
      final serviceType = service.type ?? 'api';
      final isApiService = serviceType == 'api';

      return {
        'name': service.name,
        'type': 'service',
        'params': {
          'feature':
              service.features.isNotEmpty ? service.features.first : 'core',
          'service_type': serviceType,
          'with_tests': true,
          'with_mocks': false,
          'with_interceptors': isApiService,
          'with_retry_logic': isApiService,
          'with_caching': serviceType == 'cache',
          if (isApiService && service.apiBase != null)
            'api_base_url': service.apiBase,
        },
      };
    }).toList();
  }

  /// Determine preset from manifest config
  String _determinePresetFromManifest(ManifestConfig config) {
    // If tests/docs are disabled, use minimal preset
    if (!config.generateTests && !config.generateDocs) {
      return 'minimal';
    }
    // If both tests and docs are enabled, use batteries_included
    if (config.generateTests && config.generateDocs) {
      return 'batteries_included';
    }
    // Default to starter
    return 'starter';
  }

  /// Run in interactive mode
  Future<CommandResult> _runInteractiveMode(
    String projectName,
    String template,
    String organization,
    String description,
    List<String> platforms,
    List<String> features,
    String projectPath,
  ) async {
    logger
      ..info('🚀 Welcome to Fly CLI Interactive Mode')
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
        choices: ['fly_foundation'],
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

      // 5. Features
      final finalFeatures = await prompter.promptMultiChoice(
        prompt: 'Select initial features to scaffold',
        choices: ['home', 'auth', 'profile', 'settings', 'catalog', 'cart'],
        defaultChoices: features,
      );

      // 6. Display summary
      logger
        ..info('\n📋 Project Configuration:')
        ..info('  Name: $finalProjectName')
        ..info('  Template: $finalTemplate')
        ..info('  Organization: $finalOrganization')
        ..info('  Platforms: ${finalPlatforms.join(', ')}')
        ..info('  Features: ${finalFeatures.join(', ')}');

      // 7. Confirmation
      final confirmed = await prompter.promptConfirm(
        prompt: '\nCreate project with this configuration?',
      );

      if (!confirmed) {
        return CommandResult.error(
          message: 'Project creation cancelled',
          suggestion: 'Run the command again to start over',
          errorCode: ErrorCode.invalidArgumentValue,
          context: ErrorContext.forCommand(
            'generate project',
            arguments: argResults?.arguments,
            extra: {'interactive': true, 'cancelled': true},
          ),
        );
      }

      logger.info('\nGenerating project...\n');

      return _createProject(
        projectName: finalProjectName,
        template: finalTemplate,
        organization: finalOrganization,
        description: description,
        // Use description from flags if available
        platforms: finalPlatforms,
        features: finalFeatures,
        services: const [],
        projectPath: projectPath,
      );
    } catch (e) {
      return CommandResult.error(
        message: 'Interactive mode failed: $e',
        suggestion: 'Try running without --interactive flag',
        errorCode: ErrorCode.internalError,
        context: ErrorContext.forCommand(
          'generate project',
          arguments: argResults?.arguments,
          extra: {'interactive': true, 'error': e.toString()},
        ),
      );
    }
  }

  /// Create the project
  Future<CommandResult> _createProject({
    required String projectName,
    required String template,
    required String organization,
    required String description,
    required List<String> platforms,
    required List<String> features,
    required List<Map<String, dynamic>> services,
    required String projectPath,
    String preset = 'starter',
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      logger
        ..info('Creating Flutter project...')
        ..info('Template: $template')
        ..info('Organization: $organization')
        ..info('Platforms: ${platforms.join(', ')}')
        ..info('Features: ${features.join(', ')}');

      // Use injected template manager
      final templateManager = context.templateManager;

      // Check if this is fly_foundation template - use orchestrator
      if (template == 'fly_foundation') {
        return await _generateFoundationProject(
          projectName: projectName,
          organization: organization,
          description: description,
          platforms: platforms,
          features: features,
          services: services,
          preset: preset,
          projectPath: projectPath,
          templateManager: templateManager,
          stopwatch: stopwatch,
        );
      }

      // Create template variables
      final templateVariables = TemplateVariables(
        projectName: projectName,
        organization: organization,
        platforms: platforms,
        description: description,
        features: features,
      );

      // Generate project using template manager (legacy approach)
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
        command: 'generate project',
        message: 'Project created successfully',
        data: {
          'project_name': projectName,
          'template': template,
          'organization': organization,
          'platforms': platforms,
          'features': features,
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

  /// Generate foundation project using the new orchestrator approach.
  Future<CommandResult> _generateFoundationProject({
    required String projectName,
    required String organization,
    required String description,
    required List<String> platforms,
    required List<String> features,
    required List<Map<String, dynamic>> services,
    String preset = 'starter',
    required String projectPath,
    required TemplateManager templateManager,
    required Stopwatch stopwatch,
  }) async {
    try {
      // Create orchestrator
      final orchestrator = TemplateGenerationOrchestrator(
        templateManager: templateManager,
        logger: logger,
      );

      // Convert features list to InstanceConfig format
      final featureInstances = features.isNotEmpty
          ? features.map((featureName) {
              return {
                'name': featureName,
                'type': 'feature',
                'params': {
                  'feature': featureName,
                  'screen_type': 'list', // Default screen type
                  'with_viewmodel': true,
                  'with_tests': true,
                  'with_validation': false,
                  'with_navigation': false,
                },
              };
            }).toList()
          : [
              {
                'name': 'home',
                'type': 'feature',
                'params': {
                  'feature': 'home',
                  'screen_type': 'list',
                  'with_viewmodel': true,
                  'with_tests': true,
                  'with_validation': false,
                  'with_navigation': false,
                },
              }
            ];

      // Prepare raw variables for planning
      final rawVars = <String, dynamic>{
        'name': projectName,
        'organization': organization,
        'description': description.isNotEmpty ? description : 'A new Flutter project',
        'platforms': platforms,
        'generation_mode': 'project',
        'preset': preset,
        'features': featureInstances,
        'services': services,
      };

      // Generate using orchestrator
      final result = await orchestrator.generate(
        rawVars: rawVars,
        outputDirectory: projectPath,
      );

      stopwatch.stop();

      if (!result.success) {
        return CommandResult.error(
          message: 'Failed to generate foundation project: ${result.error}',
          suggestion: 'Check your input and try again',
          errorCode: ErrorCode.templateGenerationFailed,
          context: ErrorContext.forCommand(
            'generate project',
            arguments: argResults?.arguments,
          ),
        );
      }

      return CommandResult.success(
        command: 'generate project',
        message: 'Foundation project created successfully',
        data: {
          'project_name': projectName,
          'template': 'fly_foundation',
          'organization': organization,
          'platforms': platforms,
          'features': features,
          'files_generated': result.files?.length ?? 0,
          'duration_ms': stopwatch.elapsedMilliseconds,
          'target_directory': result.targetDirectory ?? projectPath,
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
      stopwatch.stop();
      return CommandResult.error(
        message: 'Failed to create foundation project: $e',
        suggestion: 'Check your input and try again',
        errorCode: ErrorCode.templateGenerationFailed,
        context: ErrorContext.forCommand(
          'generate project',
          arguments: argResults?.arguments,
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

