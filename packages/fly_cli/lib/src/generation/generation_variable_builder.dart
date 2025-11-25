import 'package:args/args.dart';
import 'package:fly_cli/src/cli/infrastructure/validation/validation_rules.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/infrastructure/flags/cli_flags.dart';
import 'package:fly_cli/src/features/commands/infrastructure/flags/flag_accessor.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/generation/variables/validation/variable_validation_service.dart';

/// Base class for building generation variables from various input sources.
///
/// This provides a unified interface for collecting and normalizing variables
/// from flags, interactive prompts, or manifest data into the rawVars format
/// expected by TemplateGenerationOrchestrator.
abstract class GenerationVariableBuilder {
  /// Build variables from command context (flags or interactive mode).
  Future<Map<String, dynamic>> buildFromContext({
    required CommandContext context,
    required bool interactive,
    String? outputDir,
  });

  /// Build variables from a map (e.g., from manifest or programmatic input).
  Map<String, dynamic> buildFromMap(Map<String, dynamic> input);

  /// Validate that all required variables are present.
  ValidationResult validate(Map<String, dynamic> rawVars);
}

/// Builder for feature generation variables.
class FeatureVariableBuilder implements GenerationVariableBuilder {
  const FeatureVariableBuilder();

  @override
  Future<Map<String, dynamic>> buildFromContext({
    required CommandContext context,
    required bool interactive,
    String? outputDir,
  }) async {
    if (interactive) {
      return _buildInteractive(context);
    } else {
      return _buildFromFlags(context.argResults);
    }
  }

  @override
  Map<String, dynamic> buildFromMap(Map<String, dynamic> input) {
    final componentName =
        input['name'] as String?;
    if (componentName == null) {
      throw ArgumentError('Feature name is required');
    }

    final feature = input['feature'] as String? ?? 'home';
    final screenTypeStr = input['screen_type'] as String? ?? 'list';
    final screenType =
        ScreenType.tryFromKey(screenTypeStr, defaultValue: ScreenType.list) ??
        ScreenType.list;

    return {
      'name': componentName,
      // Required by validation - feature names are already snake_case
      'generation_mode': 'feature',
      'feature': feature,
      'screen_type': screenType.key,
      'with_viewmodel': input['with_viewmodel'] as bool? ?? false,
      'with_tests': input['with_tests'] as bool? ?? true,
      'with_validation': input['with_validation'] as bool? ?? false,
      'with_navigation': input['with_navigation'] as bool? ?? false,
      'preset': input['preset'] as String? ?? 'starter',
    };
  }

  @override
  ValidationResult validate(Map<String, dynamic> rawVars) {
    // Use unified validation service
    final errors = VariableValidationService.validateBusinessRules(
      GenerationMode.feature,
      rawVars,
    );

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }

  Future<Map<String, dynamic>> _buildInteractive(CommandContext context) async {
    final prompter = context.interactivePrompt;
    final logger = context.logger;

    logger.info('🎬 Generating a new feature component');
    logger.info('');

    // 1. Screen/component name
    final componentName = await prompter.promptString(
      prompt: 'Screen name',
      validator: NameValidationRule.isValidScreenName,
      validationError:
          'Screen name must contain only lowercase letters, numbers, and underscores',
    );

    // 2. Feature
    final feature = await prompter.promptString(
      prompt: 'Feature name',
      defaultValue: 'home',
      validator: NameValidationRule.isValidFeatureName,
      validationError:
          'Feature name must contain only lowercase letters, numbers, and underscores',
    );

    // 3. Screen type
    final screenTypeStr = await prompter.promptChoice(
      prompt: 'Screen type',
      choices: ScreenType.values.map((e) => e.key).toList(),
      defaultChoice: ScreenType.list.key,
    );
    final screenType = ScreenType.fromKey(screenTypeStr);

    // 4. ViewModel
    final withViewModel = await prompter.promptConfirm(
      prompt: 'Include ViewModel/Provider?',
    );

    // 5. Tests
    final withTests = await prompter.promptConfirm(
      prompt: 'Include test files?',
    );

    // 6. Additional options based on screen type
    var withValidation = false;
    if (screenType == ScreenType.form) {
      withValidation = await prompter.promptConfirm(
        prompt: 'Include form validation?',
      );
    }

    final withNavigation = await prompter.promptConfirm(
      prompt: 'Include navigation logic?',
    );

    return {
      'name': componentName,
      // Required by validation - feature names are already snake_case
      'generation_mode': 'feature',
      'feature': feature,
      'screen_type': screenType.key,
      'with_viewmodel': withViewModel,
      'with_tests': withTests,
      'with_validation': withValidation,
      'with_navigation': withNavigation,
      'preset': 'starter',
    };
  }

  Map<String, dynamic> _buildFromFlags(ArgResults? argResults) {
    if (argResults == null || argResults.rest.isEmpty) {
      throw ArgumentError('Feature name is required as a positional argument');
    }

    final componentName = argResults.rest.first;
    final feature = FlagAccessor.getStringOrDefault(
      argResults,
      const GenerateScreenFeatureFlag(),
      'home',
    );
    final screenTypeStr = FlagAccessor.getStringOrDefault(
      argResults,
      const GenerateScreenTypeFlag(),
      ScreenType.list.key,
    );
    final screenType =
        ScreenType.tryFromKey(screenTypeStr, defaultValue: ScreenType.list) ??
        ScreenType.list;
    final withViewModel = FlagAccessor.getBool(
      argResults,
      const GenerateScreenWithViewModelFlag(),
    );
    final withTests = FlagAccessor.getBool(
      argResults,
      const GenerateScreenWithTestsFlag(),
    );
    final withValidation = FlagAccessor.getBool(
      argResults,
      const GenerateScreenWithValidationFlag(),
    );
    final withNavigation = FlagAccessor.getBool(
      argResults,
      const GenerateScreenWithNavigationFlag(),
    );

    return {
      'name': componentName,
      // Required by validation - feature names are already snake_case
      'generation_mode': 'feature',
      'feature': feature,
      'screen_type': screenType.key,
      'with_viewmodel': withViewModel,
      'with_tests': withTests,
      'with_validation': withValidation,
      'with_navigation': withNavigation,
      'preset': 'starter',
    };
  }
}

/// Builder for service generation variables.
class ServiceVariableBuilder implements GenerationVariableBuilder {
  const ServiceVariableBuilder();

  @override
  Future<Map<String, dynamic>> buildFromContext({
    required CommandContext context,
    required bool interactive,
    String? outputDir,
  }) async {
    if (interactive) {
      return _buildInteractive(context);
    } else {
      return _buildFromFlags(context.argResults);
    }
  }

  @override
  Map<String, dynamic> buildFromMap(Map<String, dynamic> input) {
    final serviceName =
        input['name'] as String? ?? input['service_name'] as String?;
    if (serviceName == null) {
      throw ArgumentError('Service name is required');
    }

    final feature = input['feature'] as String? ?? 'core';
    final serviceTypeStr = input['service_type'] as String? ?? 'api';
    final serviceType =
        ServiceType.tryFromKey(serviceTypeStr, defaultValue: ServiceType.api) ??
        ServiceType.api;
    final isApiService = serviceType == ServiceType.api;

    return {
      'name': serviceName,
      // Required by validation - service names are already snake_case
      'generation_mode': 'service',
      'feature': feature,
      'service_type': serviceType.key,
      'with_tests': input['with_tests'] as bool? ?? true,
      'with_mocks': input['with_mocks'] as bool? ?? false,
      'with_interceptors':
          input['with_interceptors'] as bool? ?? (isApiService ? false : false),
      'with_retry_logic': isApiService,
      'with_caching': serviceType == ServiceType.cache,
      if (isApiService)
        'api_base_url':
            input['api_base_url'] as String? ??
            input['base_url'] as String? ??
            'https://api.example.com',
      'preset': input['preset'] as String? ?? 'starter',
    };
  }

  @override
  ValidationResult validate(Map<String, dynamic> rawVars) {
    // Use unified validation service
    final errors = VariableValidationService.validateBusinessRules(
      GenerationMode.service,
      rawVars,
    );

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }

  Future<Map<String, dynamic>> _buildInteractive(CommandContext context) async {
    final prompter = context.interactivePrompt;
    final logger = context.logger;

    logger.info('🔧 Generating a new service');
    logger.info('');

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
    final serviceTypeStr = await prompter.promptChoice(
      prompt: 'Service type',
      choices: ServiceType.values.map((e) => e.key).toList(),
      defaultChoice: ServiceType.api.key,
    );
    final serviceType = ServiceType.fromKey(serviceTypeStr);

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
    if (serviceType == ServiceType.api) {
      withInterceptors = await prompter.promptConfirm(
        prompt: 'Include HTTP interceptors?',
      );

      baseUrl = await prompter.promptString(
        prompt: 'Base URL',
        defaultValue: 'https://api.example.com',
      );
    }

    final withRetryLogic = serviceType == ServiceType.api;
    final withCaching = serviceType == ServiceType.cache;

    return {
      'name': componentName,
      // Required by validation - service names are already snake_case
      'generation_mode': 'service',
      'feature': feature,
      'service_type': serviceType.key,
      'with_tests': withTests,
      'with_mocks': withMocks,
      'with_interceptors': withInterceptors,
      'with_retry_logic': withRetryLogic,
      'with_caching': withCaching,
      if (serviceType == ServiceType.api) 'api_base_url': baseUrl,
      'preset': 'starter',
    };
  }

  Map<String, dynamic> _buildFromFlags(ArgResults? argResults) {
    if (argResults == null || argResults.rest.isEmpty) {
      throw ArgumentError('Service name is required as a positional argument');
    }

    final serviceName = argResults.rest.first;
    final feature = FlagAccessor.getStringOrDefault(
      argResults,
      const GenerateServiceFeatureFlag(),
      'core',
    );
    final serviceTypeStr = FlagAccessor.getStringOrDefault(
      argResults,
      const GenerateServiceTypeFlag(),
      ServiceType.api.key,
    );
    final serviceType =
        ServiceType.tryFromKey(serviceTypeStr, defaultValue: ServiceType.api) ??
        ServiceType.api;
    final withTests = FlagAccessor.getBool(
      argResults,
      const GenerateServiceWithTestsFlag(),
    );
    final withMocks = FlagAccessor.getBool(
      argResults,
      const GenerateServiceWithMocksFlag(),
    );
    final withInterceptors = FlagAccessor.getBool(
      argResults,
      const GenerateServiceWithInterceptorsFlag(),
    );
    final withRetryLogic = serviceType == ServiceType.api;
    final withCaching = serviceType == ServiceType.cache;

    final baseUrl = FlagAccessor.getStringOrDefault(
      argResults,
      const GenerateServiceBaseUrlFlag(),
      'https://api.example.com',
    );

    return {
      'name': serviceName,
      // Required by validation - service names are already snake_case
      'generation_mode': 'service',
      'feature': feature,
      'service_type': serviceType.key,
      'with_tests': withTests,
      'with_mocks': withMocks,
      'with_interceptors': withInterceptors,
      'with_retry_logic': withRetryLogic,
      'with_caching': withCaching,
      if (serviceType == ServiceType.api) 'api_base_url': baseUrl,
      'preset': 'starter',
    };
  }
}

/// Builder for project generation variables.
class ProjectVariableBuilder implements GenerationVariableBuilder {
  const ProjectVariableBuilder();

  @override
  Future<Map<String, dynamic>> buildFromContext({
    required CommandContext context,
    required bool interactive,
    String? outputDir,
  }) async {
    if (interactive) {
      return _buildInteractive(context);
    } else {
      return _buildFromFlags(context);
    }
  }

  @override
  Map<String, dynamic> buildFromMap(Map<String, dynamic> input) {
    final projectName =
        input['name'] as String? ?? input['project_name'] as String?;
    if (projectName == null) {
      throw ArgumentError('Project name is required');
    }

    final organization = input['organization'] as String? ?? 'com.example';
    final description =
        input['description'] as String? ?? 'A new Flutter project';
    final platforms =
        input['platforms'] as List<dynamic>? ?? ['ios', 'android'];
    final template = input['template'] as String? ?? 'fly_foundation';
    final preset = input['preset'] as String? ?? 'starter';

    // Convert features list to feature instances format
    final featuresInput = input['features'] as List<dynamic>? ?? [];
    final featureInstances = featuresInput.map((featureName) {
      return {
        'name': featureName is String
            ? featureName
            : (featureName as Map)['name'],
        'type': 'feature',
        'params': featureName is Map
            ? featureName['params'] as Map<String, dynamic>?
            : {
                'feature': featureName,
                'screen_type': 'list',
                'with_viewmodel': true,
                'with_tests': true,
                'with_validation': false,
                'with_navigation': false,
              },
      };
    }).toList();

    // Convert services list to service instances format
    final servicesInput = input['services'] as List<dynamic>? ?? [];
    final serviceInstances = servicesInput.map((serviceData) {
      if (serviceData is Map) {
        return {
          'name': serviceData['name'],
          'type': 'service',
          'params': serviceData['params'] as Map<String, dynamic>? ?? {},
        };
      }
      return {
        'name': serviceData,
        'type': 'service',
        'params': {
          'feature': 'core',
          'service_type': 'api',
          'with_tests': true,
          'with_mocks': false,
          'with_interceptors': false,
          'with_retry_logic': true,
          'with_caching': false,
        },
      };
    }).toList();

    return {
      'name': projectName,
      'project_name': projectName,
      // Required by validation - project names are already snake_case
      'organization': organization,
      'description': description,
      'platforms': platforms,
      'generation_mode': 'project',
      'template': template,
      'preset': preset,
      'features': featureInstances,
      'services': serviceInstances,
    };
  }

  @override
  ValidationResult validate(Map<String, dynamic> rawVars) {
    // Use unified validation service
    final errors = VariableValidationService.validateBusinessRules(
      GenerationMode.project,
      rawVars,
    );

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }

  Future<Map<String, dynamic>> _buildInteractive(CommandContext context) async {
    final prompter = context.interactivePrompt;
    final logger = context.logger;

    logger.info('🚀 Welcome to Fly CLI Interactive Mode');
    logger.info("Let's create your Flutter project step by step.\n");

    // 1. Project name
    final projectName = await prompter.promptString(
      prompt: 'Project name',
      validator: NameValidationRule.isValidProjectName,
      validationError:
          'Project name must contain only lowercase letters, '
          'numbers, and underscores',
    );

    // 2. Template selection
    final template = await prompter.promptChoice(
      prompt: 'Select template',
      choices: ['fly_foundation'],
      defaultChoice: 'fly_foundation',
    );

    // 3. Organization
    final organization = await prompter.promptString(
      prompt: 'Organization identifier',
      defaultValue: 'com.example',
    );

    // 4. Platforms
    final platforms = await prompter.promptMultiChoice(
      prompt: 'Select target platforms',
      choices: ['ios', 'android', 'web', 'macos', 'windows', 'linux'],
      defaultChoices: ['ios', 'android'],
    );

    // 5. Features
    final features = await prompter.promptMultiChoice(
      prompt: 'Select initial features to generate',
      choices: ['home', 'auth', 'profile', 'settings', 'catalog', 'cart'],
      defaultChoices: [],
    );

    // Convert features to feature instances
    final featureInstances = features.map((featureName) {
      return {
        'name': featureName,
        'type': 'feature',
        'params': {
          'feature': featureName,
          'screen_type': 'list',
          'with_viewmodel': true,
          'with_tests': true,
          'with_validation': false,
          'with_navigation': false,
        },
      };
    }).toList();

    return {
      'name': projectName,
      'project_name': projectName,
      // Required by validation - project names are already snake_case
      'template': template,
      'organization': organization,
      'description': 'A new Flutter project',
      'platforms': platforms,
      'generation_mode': 'project',
      'preset': 'starter',
      'features': featureInstances,
      'services': [],
    };
  }

  Map<String, dynamic> _buildFromFlags(CommandContext context) {
    final argResults = context.argResults;
    if (argResults == null || argResults.rest.isEmpty) {
      throw ArgumentError('Project name is required as a positional argument');
    }

    final projectName = argResults.rest.first;
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
    final description =
        FlagAccessor.getString(
          argResults,
          const CreateDescriptionFlag(),
        ) ??
        'A new Flutter project';
    final platforms = FlagAccessor.getStringList(
      argResults,
      CreatePlatformsFlag(),
    );
    final features = FlagAccessor.getStringList(
      argResults,
      CreateFeaturesFlag(),
    );

    // Convert features to feature instances
    final featureInstances = features.map((featureName) {
      return {
        'name': featureName,
        'type': 'feature',
        'params': {
          'feature': featureName,
          'screen_type': 'list',
          'with_viewmodel': true,
          'with_tests': true,
          'with_validation': false,
          'with_navigation': false,
        },
      };
    }).toList();

    return {
      'name': projectName,
      'project_name': projectName,
      // Required by validation - project names are already snake_case
      'template': template,
      'organization': organization,
      'description': description,
      'platforms': platforms.isEmpty ? ['ios', 'android'] : platforms,
      'generation_mode': 'project',
      'preset': 'starter',
      'features': featureInstances,
      'services': [],
    };
  }
}
