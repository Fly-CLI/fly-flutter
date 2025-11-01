import 'dart:io';

import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/templates/brick_info.dart';
import 'package:fly_cli/src/core/templates/template_manager.dart';
import 'package:fly_cli/src/integrations/mcp/errors/mcp_error.dart';
import 'package:fly_cli/src/integrations/mcp/mcp_tool_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/types/fly_add_screen_params.dart';
import 'package:fly_cli/src/integrations/mcp/tools/types/fly_add_screen_result.dart';
import 'package:fly_mcp/fly_mcp.dart';

/// Strategy for fly.add.screen tool
class FlyAddScreenStrategy
    extends McpToolStrategy<FlyAddScreenParams, FlyAddScreenResult> {
  @override
  String get name => 'fly.add.screen';

  @override
  String get description =>
      'Add a new screen component to the current Flutter project. '
      'Screen names must be lowercase (e.g., "home" not "Home"). '
      'The tool generates a screen widget with optional view model, tests, validation, and navigation setup.';

  @override
  ObjectSchema get paramsSchema => ObjectSchema(
        description:
            'Parameters for adding a screen. Screen names follow Fly conventions: lowercase with snake_case for multi-word names.',
        properties: {
          'screenName': Schema.string(
            description:
                'The name of the screen to create. Must be lowercase and contain only letters, numbers, and underscores. '
                'Examples: "home", "product_list", "user_profile". '
                'Note: Names will be automatically converted to lowercase if provided in uppercase.',
          ),
          'feature': Schema.string(
            description:
                'The feature module this screen belongs to. Defaults to "home" if not specified.',
          ),
          'screenType': Schema.string(
            description:
                'The type of screen to generate. Each type has different structure and behavior: '
                '- "list": Displays a list of items (e.g., product list) '
                '- "detail": Shows detailed information about a single item '
                '- "form": Input form for creating/editing data '
                '- "auth": Authentication screen (login, signup) '
                '- "settings": Application settings screen',
            enumValues: ['list', 'detail', 'form', 'auth', 'settings'],
          ),
          'withViewModel': Schema.bool(
            description:
                'Whether to generate a view model for state management. Defaults to false.',
          ),
          'withTests': Schema.bool(
            description:
                'Whether to generate unit/widget tests for the screen. Defaults to false.',
          ),
          'withValidation': Schema.bool(
            description:
                'Whether to include form validation logic. Useful for form-type screens. Defaults to false.',
          ),
          'withNavigation': Schema.bool(
            description:
                'Whether to set up navigation/routing for this screen. Defaults to true.',
          ),
        },
        required: ['screenName'],
        additionalProperties: false,
      );

  @override
  ObjectSchema get resultSchema => ObjectSchema(
        description:
            'Result from adding a screen. Contains success status, generated files count, and screen path.',
        properties: {
          'success': Schema.bool(
            description: 'Whether the screen was generated successfully',
          ),
          'message': Schema.string(
            description:
                'Human-readable message describing the operation result',
          ),
          'filesGenerated': Schema.int(
            description:
                'Number of files generated for the screen (widget, tests, view model, etc.)',
          ),
          'screenPath': Schema.string(
            description:
                'Path to the generated screen directory containing all screen files',
          ),
        },
        required: ['success', 'message'],
      );

  @override
  bool get readOnly => false;

  @override
  bool get writesToDisk => true;

  @override
  bool get requiresConfirmation => false;

  @override
  bool get idempotent => false;

  @override
  Duration? get timeout => const Duration(minutes: 2);

  @override
  FlyAddScreenParams paramsFromJson(Map<String, Object?> json) {
    return FlyAddScreenParams.fromJson(json);
  }

  @override
  TypedToolHandler<FlyAddScreenParams, FlyAddScreenResult> createTypedHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return (params, {cancelToken, progressNotifier}) async {
      cancelToken?.throwIfCancelled();

      // Validate screen name with structured errors
      final validationErrors = <String>[];
      if (params.screenName.isEmpty) {
        validationErrors.add('Missing required parameter: screenName');
      } else {
        // Validate screen name follows Fly conventions (lowercase)
        final screenNameLower = params.screenName.toLowerCase();
        if (params.screenName != screenNameLower) {
          // Provide helpful hint about lowercase conversion
          throw McpError.screenNameValidation(
            screenName: params.screenName,
            context: {
              'suggested_name': screenNameLower,
              'tool': name,
              'hint':
                  'Screen names must be lowercase. Consider using: "$screenNameLower"',
            },
          );
        }
        // Validate name contains only valid characters
        if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(params.screenName)) {
          throw McpError.validationError(
            field: 'screenName',
            value: params.screenName,
            reason:
                'Screen names must be lowercase and contain only letters, numbers, and underscores',
            tool: name,
            suggestion:
                'Convert to lowercase snake_case (e.g., "ProductList" → "product_list")',
          );
        }
      }

      if (validationErrors.isNotEmpty) {
        throw McpError.invalidParams(
          tool: name,
          errors: validationErrors,
          context: {
            'screen_name': params.screenName,
          },
        );
      }

      final feature = params.feature ?? 'home';
      final screenType = params.screenType ?? 'list';
      final withViewModel = params.withViewModel ?? false;
      final withTests = params.withTests ?? false;
      final withValidation = params.withValidation ?? false;
      final withNavigation = params.withNavigation ?? true;

      await progressNotifier?.notify(
          message: 'Adding screen: ${params.screenName}...', percent: 10);

      final templateManager = context.templateManager;

      // Create screen configuration for Mason brick
      final screenConfig = <String, dynamic>{
        'screen_name': params.screenName,
        'feature': feature,
        'screen_type': screenType,
        'with_viewmodel': withViewModel,
        'with_tests': withTests,
        'with_validation': withValidation,
        'with_navigation': withNavigation,
      };

      await progressNotifier?.notify(
          message: 'Generating screen files...', percent: 50);

      // Generate screen using TemplateManager
      final result = await templateManager.generateComponent(
        componentName: params.screenName,
        componentType: BrickType.screen,
        config: screenConfig,
        targetPath: Directory.current.path,
      );

      cancelToken?.throwIfCancelled();

      if (result is TemplateGenerationFailure) {
        throw McpError.templateError(
          templateId: 'screen',
          error: result.error,
          variables: screenConfig,
          context: {
            'screen_name': params.screenName,
            'feature': feature,
            'screen_type': screenType,
          },
        );
      }

      if (result is! TemplateGenerationSuccess) {
        return FlyAddScreenResult(
          success: false,
          message: 'Unexpected generation result',
        );
      }

      return FlyAddScreenResult(
        success: true,
        message: 'Screen added successfully',
        filesGenerated: result.filesGenerated,
        screenPath: result.targetDirectory,
      );
    };
  }
}
