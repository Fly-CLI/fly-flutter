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

/// GenerateScreenCommand using new architecture
class GenerateScreenCommand extends FlyCommand {
  GenerateScreenCommand(CommandContext context) : super(context);

  /// Factory constructor for enum-based command creation
  factory GenerateScreenCommand.create(CommandContext context) =>
      GenerateScreenCommand(context);

  @override
  String get name => 'screen';

  @override
  String get description =>
      'Generate a new screen component to the current project';

  // @override
  // CommandDefinition? get metadata => null;

  @override
  List<CliFlag> get flags => [
        const GenerateScreenFeatureFlag(),
        const GenerateScreenTypeFlag(),
        const GenerateScreenWithViewModelFlag(),
        const GenerateScreenWithTestsFlag(),
        const InteractiveFlag(),
        const GenerateScreenWithValidationFlag(),
        const GenerateScreenWithNavigationFlag(),
        const OutputDirFlag(),
      ];

  @override
  List<CommandValidator> get validators => [
        RequiredArgumentValidator('screen_name'),
        ScreenNameValidator(),
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

      logger.info('🎬 Generating a new screen');
      logger.info('');

      // 1. Screen name
      final screenName = await prompter.promptString(
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
      final screenType = await prompter.promptChoice(
        prompt: 'Screen type',
        choices: ['list', 'detail', 'form', 'auth', 'settings'],
        defaultChoice: 'list',
      );

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
      if (screenType == 'form') {
        withValidation = await prompter.promptConfirm(
          prompt: 'Include form validation?',
        );
      }

      final withNavigation = await prompter.promptConfirm(
        prompt: 'Include navigation logic?',
      );

      // 7. Confirmation
      logger.info('');
      logger.info('Screen Configuration:');
      logger.info('  Name: $screenName');
      logger.info('  Feature: $feature');
      logger.info('  Type: $screenType');
      logger.info('  With ViewModel: $withViewModel');
      logger.info('  With Tests: $withTests');
      if (screenType == 'form') {
        logger.info('  With Validation: $withValidation');
      }
      logger.info('  With Navigation: $withNavigation');

      final confirmed = await prompter.promptConfirm(
        prompt: '\nCreate screen with this configuration?',
      );

      if (!confirmed) {
        return CommandResult.error(
          message: 'Screen creation cancelled',
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
            'generate screen',
            arguments: argResults?.arguments,
          ),
        );
      }

      final targetDir = resolvedOutputDir.path!.absolute;

      // Generate screen using Mason brick
      return await _generateScreenWithMason(
        screenName: screenName,
        feature: feature,
        screenType: screenType,
        withViewModel: withViewModel,
        withTests: withTests,
        withValidation: withValidation,
        withNavigation: withNavigation,
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
    final screenName = argResults!.rest.first;
    final feature = FlagAccessor.getStringOrDefault(
      argResults,
      const GenerateScreenFeatureFlag(),
      'home',
    );
    final screenType = FlagAccessor.getStringOrDefault(
      argResults,
      const GenerateScreenTypeFlag(),
      'list',
    );
    final withViewModel = FlagAccessor.getBool(
      argResults,
      const GenerateScreenWithViewModelFlag(),
    );
    final withTests =
        FlagAccessor.getBool(argResults, const GenerateScreenWithTestsFlag());
    final withValidation = FlagAccessor.getBool(
      argResults,
      const GenerateScreenWithValidationFlag(),
    );
    final withNavigation = FlagAccessor.getBool(
      argResults,
      const GenerateScreenWithNavigationFlag(),
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
          'generate screen',
          arguments: argResults?.arguments,
        ),
      );
    }
    final targetProjectDir = outputDirResult.path!.absolute;

    return _generateScreenWithMason(
      screenName: screenName,
      feature: feature,
      screenType: screenType,
      withViewModel: withViewModel,
      withTests: withTests,
      withValidation: withValidation,
      withNavigation: withNavigation,
      outputDir: targetProjectDir,
    );
  }

  /// Generate screen using Mason brick
  Future<CommandResult> _generateScreenWithMason({
    required String screenName,
    required String feature,
    required String screenType,
    required bool withViewModel,
    required bool withTests,
    required bool withValidation,
    required bool withNavigation,
    required String outputDir,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      logger.info('Generating screen: $screenName');
      logger.info('Feature: $feature');
      logger.info('Type: $screenType');
      logger.info('With viewmodel: $withViewModel');
      logger.info('With tests: $withTests');
      if (screenType == 'form') {
        logger.info('With validation: $withValidation');
      }
      logger.info('With navigation: $withNavigation');

      // Use injected template manager
      final templateManager = context.templateManager;

      // Create screen configuration for Mason brick
      final screenConfig = <String, dynamic>{
        'screen_name': screenName,
        'feature': feature,
        'screen_type': screenType,
        'screen_type_list': screenType == 'list',
        'screen_type_detail': screenType == 'detail',
        'screen_type_form': screenType == 'form',
        'screen_type_auth': screenType == 'auth',
        'screen_type_settings': screenType == 'settings',
        'with_viewmodel': withViewModel,
        'with_tests': withTests,
        'with_validation': withValidation,
        'with_navigation': withNavigation,
      };

      // Generate screen using TemplateManager
      final result = await templateManager.generateComponent(
        componentName: screenName,
        componentType: BrickType.screen,
        config: screenConfig,
        targetPath: outputDir,
      );

      stopwatch.stop();

      if (result is TemplateGenerationFailure) {
        return CommandResult.error(
          message: 'Failed to generate screen: ${result.error}',
          suggestion: 'Check screen brick availability and try again',
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
        command: 'generate screen',
        message: 'Screen generated successfully',
        data: {
          'screen_name': screenName,
          'feature': feature,
          'screen_type': screenType,
          'with_viewmodel': withViewModel,
          'with_tests': withTests,
          'with_validation': withValidation,
          'with_navigation': withNavigation,
          'files_generated': filesGenerated,
          'duration_ms': stopwatch.elapsedMilliseconds,
        },
        nextSteps: [
          const NextStep(
            command: 'flutter run',
            description: 'Run the application to see the new screen',
          ),
        ],
      );
    } catch (e) {
      return CommandResult.error(
        message: 'Failed to generate screen: $e',
        suggestion: 'Check your project structure and try again',
      );
    }
  }

  // Lifecycle hooks implementation
  @override
  Future<void> onBeforeExecute(CommandContext context) async {
    logger.info('🔧 Preparing to generate screen...');
  }

  @override
  Future<void> onAfterExecute(
      CommandContext context, CommandResult result) async {
    if (result.success) {
      logger.info('🎉 Screen generated successfully!');
    }
  }

  @override
  Future<void> onError(
      CommandContext context, Object error, StackTrace stackTrace) async {
    logger.err('💥 Screen generation failed: $error');
    if (context.verbose) {
      logger.err('Stack trace: $stackTrace');
    }
  }
}
