import 'package:fly_cli/src/cli/infrastructure/middleware/domain/command_middleware.dart';
import 'package:fly_cli/src/cli/infrastructure/middleware/infrastructure/optional/caching_middleware.dart';
import 'package:fly_cli/src/cli/infrastructure/validation/validation_rules.dart';
import 'package:fly_cli/src/features/commands/application/command_base.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/domain/command_definition.dart';
import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/features/commands/domain/command_validator.dart';
import 'package:fly_cli/src/features/commands/infrastructure/flags/cli_flags.dart';
import 'package:fly_cli/src/features/commands/infrastructure/flags/flag_accessor.dart';
import 'package:fly_cli/src/features/generate/common/generation_command_handler.dart';
import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/domain/entities/manifest_parser.dart';
import 'package:fly_cli/src/generation/generation_variable_builder.dart';
import 'package:fly_cli/src/generation/utils/mason_variable_keys.dart';
import 'package:fly_cli/src/shared/errors/domain/error_codes.dart';
import 'package:fly_cli/src/shared/errors/domain/error_context.dart';

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
        command: 'fly generate project my_app --features=home,profile,settings',
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

    // Build variables using ProjectVariableBuilder
    // Use execution context's argResults (set by CommandRunner) instead of registration context
    final executionContext = context.factory.createExecutionContext(
      argResults!,
    );
    const variableBuilder = ProjectVariableBuilder();
    final rawVars = variableBuilder.buildFromContext(
      context: executionContext,
      interactive: false,
      outputDir: null,
    );

    // Validate variables
    final validationResult = variableBuilder.validate(await rawVars);
    if (!validationResult.isValid) {
      return CommandResult.error(
        message: 'Validation failed: ${validationResult.errors.join(', ')}',
        suggestion: 'Check your input and try again',
        errorCode: ErrorCode.invalidArgumentValue,
      );
    }

    return _createProject(
      rawVars: await rawVars,
      projectPath: projectPath.absolute,
    );
  }

  /// Execute project generation from manifest file
  Future<CommandResult> _executeFromManifest(String manifestPath) async {
    try {
      // Parse manifest
      final manifest = await ProjectManifest.fromFile(manifestPath);

      // Warn if CLI flags are also provided (manifest takes precedence)
      final hasCliFlags =
          FlagAccessor.getString(
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
      final outputDir = FlagAccessor.getString(
        argResults,
        const OutputDirFlag(),
      );
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
      final featureInstances = _convertScreensToFeatureInstances(
        manifest.screens,
      );
      if (featureInstances.isEmpty) {
        featureInstances.add({
          BaseVarKey.name.key: 'home',
          'type': 'feature',
          'params': {
            BaseVarKey.feature.key: 'home',
            FeatureVarKey.screenType.key: 'list',
            FeatureVarKey.withViewModel.key: true,
            BaseVarKey.withTests.key: manifest.config.generateTests,
            FeatureVarKey.withValidation.key: false,
            FeatureVarKey.withNavigation.key: false,
          },
        });
      }

      // Convert manifest services to service instances
      final serviceInstances = _convertServicesToServiceInstances(
        manifest.services,
      );

      // Convert manifest to rawVars format using ProjectVariableBuilder
      const variableBuilder = ProjectVariableBuilder();
      final rawVars = variableBuilder.buildFromMap({
        BaseVarKey.name.key: projectName,
        'template': manifest.template,
        BaseVarKey.organization.key: manifest.organization,
        BaseVarKey.description.key: manifest.description ?? 'A new Flutter project',
        BaseVarKey.platforms.key: manifest.platforms,
        BaseVarKey.features.key: featureInstances,
        'services': serviceInstances,
        ProjectVarKey.preset.key: _determinePresetFromManifest(manifest.config),
      });

      // Validate variables
      final validationResult = variableBuilder.validate(rawVars);
      if (!validationResult.isValid) {
        return CommandResult.error(
          message: 'Validation failed: ${validationResult.errors.join(', ')}',
          suggestion: 'Check your manifest file and try again',
          errorCode: ErrorCode.invalidArgumentValue,
        );
      }

      return _createProject(
        rawVars: rawVars,
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
      final feature = screen.features.isNotEmpty
          ? screen.features.first
          : screen.name;

      return {
        BaseVarKey.name.key: screen.name,
        'type': 'feature',
        'params': {
          BaseVarKey.feature.key: feature,
          FeatureVarKey.screenType.key: screen.type ?? 'list',
          FeatureVarKey.withViewModel.key: true,
          BaseVarKey.withTests.key: true, // Will be overridden by preset if needed
          FeatureVarKey.withValidation.key: screen.type == 'form',
          FeatureVarKey.withNavigation.key: false,
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
        BaseVarKey.name.key: service.name,
        'type': 'service',
        'params': {
          BaseVarKey.feature.key: service.features.isNotEmpty
              ? service.features.first
              : 'core',
          ServiceVarKey.serviceType.key: serviceType,
          BaseVarKey.withTests.key: true,
          ServiceVarKey.withMocks.key: false,
          ServiceVarKey.withInterceptors.key: isApiService,
          ServiceVarKey.withRetryLogic.key: isApiService,
          ServiceVarKey.withCaching.key: serviceType == 'cache',
          if (isApiService && service.apiBase != null)
            ServiceVarKey.apiBaseUrl.key: service.apiBase,
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
        validationError:
            'Project name must contain only lowercase letters, '
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
        prompt: 'Select initial features to generate',
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

      // Build variables using ProjectVariableBuilder
      const variableBuilder = ProjectVariableBuilder();
      final rawVars = await variableBuilder.buildFromContext(
        context: context,
        interactive: true,
        outputDir: null,
      );

      // Override with interactive values
      rawVars[BaseVarKey.name.key] = finalProjectName;
      rawVars['template'] = finalTemplate;
      rawVars[BaseVarKey.organization.key] = finalOrganization;
      rawVars[BaseVarKey.description.key] = description.isNotEmpty
          ? description
          : 'A new Flutter project';
      rawVars[BaseVarKey.platforms.key] = finalPlatforms;
      rawVars[BaseVarKey.features.key] = finalFeatures.map((featureName) {
        return {
          BaseVarKey.name.key: featureName,
          'type': 'feature',
          'params': {
            BaseVarKey.feature.key: featureName,
            FeatureVarKey.screenType.key: 'list',
            FeatureVarKey.withViewModel.key: true,
            BaseVarKey.withTests.key: true,
            FeatureVarKey.withValidation.key: false,
            FeatureVarKey.withNavigation.key: false,
          },
        };
      }).toList();
      rawVars['services'] = [];

      // Validate variables
      final validationResult = variableBuilder.validate(rawVars);
      if (!validationResult.isValid) {
        return CommandResult.error(
          message: 'Validation failed: ${validationResult.errors.join(', ')}',
          suggestion: 'Check your input and try again',
          errorCode: ErrorCode.invalidArgumentValue,
        );
      }

      return _createProject(
        rawVars: rawVars,
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
    required Map<String, dynamic> rawVars,
    required String projectPath,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      final projectName = rawVars[BaseVarKey.name.key] as String;
      final template = rawVars['template'] as String? ?? 'fly_foundation';
      final organization = rawVars[BaseVarKey.organization.key] as String? ?? 'com.example';
      final description =
          rawVars[BaseVarKey.description.key] as String? ?? 'A new Flutter project';
      final platforms =
          (rawVars[BaseVarKey.platforms.key] as List<dynamic>?)?.cast<String>() ??
          ['ios', 'android'];
      final features = (rawVars[BaseVarKey.features.key] as List<dynamic>?) ?? [];
      final featureNames = features.map((f) {
        if (f is Map) return f[BaseVarKey.name.key] as String;
        return f.toString();
      }).toList();

      logger
        ..info('Creating Flutter project...')
        ..info('Template: $template')
        ..info('Organization: $organization')
        ..info('Platforms: ${platforms.join(', ')}')
        ..info('Features: ${featureNames.join(', ')}');

      // All templates now use orchestrator
      // Ensure features list is in the correct format
      final featureInstances = features.isNotEmpty
          ? features.cast<Map<String, dynamic>>()
          : [
              {
                BaseVarKey.name.key: 'home',
                'type': 'feature',
                'params': {
                  BaseVarKey.feature.key: 'home',
                  FeatureVarKey.screenType.key: 'list',
                  FeatureVarKey.withViewModel.key: true,
                  BaseVarKey.withTests.key: true,
                  FeatureVarKey.withValidation.key: false,
                  FeatureVarKey.withNavigation.key: false,
                },
              },
            ];

      // Ensure services list is in the correct format
      final serviceInstances =
          (rawVars['services'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      // Prepare raw variables for planning
      final projectRawVars = <String, dynamic>{
        BaseVarKey.name.key: projectName,
        BaseVarKey.organization.key: organization,
        BaseVarKey.description.key: description,
        BaseVarKey.platforms.key: platforms,
        BaseVarKey.generationMode.key: 'project',
        'template': template,
        ProjectVarKey.preset.key: rawVars[ProjectVarKey.preset.key] as String? ?? 'starter',
        BaseVarKey.features.key: featureInstances,
        'services': serviceInstances,
      };

      // Get generation handler from service container
      final handler = context.getService<GenerationCommandHandler>();

      // Extract properties and construct request
      final request = ProjectGenerationRequest(
        name: projectName,
        template: template,
        organization: organization,
        description: description,
        platforms: platforms,
        features: featureInstances,
        services: serviceInstances,
        preset: projectRawVars[ProjectVarKey.preset.key] as String? ?? 'starter',
        outputDirectory: projectPath,
        dryRun: context.planMode,
      );

      // Generate project
      final result = await handler.executeProject(request);

      stopwatch.stop();

      // Result is already a CommandResult from the handler
      // Add additional data if needed
      if (result.success && result.data != null) {
        result.data!['duration_ms'] = stopwatch.elapsedMilliseconds;
        result.data![ProjectVarKey.projectName.key] = projectName;
        result.data!['template'] = template;
        result.data![BaseVarKey.organization.key] = organization;
        result.data![BaseVarKey.platforms.key] = platforms;
        result.data![BaseVarKey.features.key] = featureNames;
        result.data!['target_directory'] = projectPath;
      }

      return result;
    } catch (e) {
      return CommandResult.error(
        message: 'Failed to create project: $e',
        suggestion: 'Check your Flutter installation and try again',
        errorCode: ErrorCode.templateGenerationFailed,
        context: ErrorContext.forProjectOperation(
          'create_project',
          rawVars[BaseVarKey.name.key] as String? ?? 'unknown',
          projectType: rawVars['template'] as String? ?? 'unknown',
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
