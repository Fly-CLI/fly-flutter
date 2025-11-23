import 'dart:io';

import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/scaffolding/foundation/foundation_enums.dart';
import 'package:fly_cli/src/core/scaffolding/generation/generation_service.dart';
import 'package:fly_cli/src/integrations/mcp/errors/mcp_error.dart';
import 'package:fly_cli/src/integrations/mcp/mcp_tool_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/types/fly_generate_screen_params.dart';
import 'package:fly_cli/src/integrations/mcp/tools/types/fly_generate_screen_result.dart';
import 'package:fly_mcp/fly_mcp.dart';

/// Strategy for fly.generate.screen tool
class FlyGenerateFeatureStrategy
    extends McpToolStrategy<FlyGenerateScreenParams, FlyGenerateScreenResult> {
  @override
  String get name => 'fly.generate.screen';

  @override
  String get description =>
      'Generate a new screen component to the current Flutter project. '
      'Screen names must be lowercase (e.g., "home" not "Home"). '
      'The tool generates a screen widget with optional view model, tests, validation, and navigation setup.';

  @override
  ObjectSchema get paramsSchema => ObjectSchema(
        description:
            'Parameters for generating a screen. Screen names follow Fly conventions: lowercase with snake_case for multi-word names.',
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
            'Result from generating a screen. Contains success status, generated files count, and screen path.',
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
  FlyGenerateScreenParams paramsFromJson(Map<String, Object?> json) {
    return FlyGenerateScreenParams.fromJson(json);
  }

  @override
  TypedToolHandler<FlyGenerateScreenParams, FlyGenerateScreenResult>
      createTypedHandler(
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

      // Convert MCP params to raw variables
      final rawVars = <String, dynamic>{
        'name': params.screenName,
        'generation_mode': 'feature',
        'feature': params.feature ?? 'home',
        'screen_type': params.screenType ?? 'list',
        'with_viewmodel': params.withViewModel ?? false,
        'with_tests': params.withTests ?? false,
        'with_validation': params.withValidation ?? false,
        'with_navigation': params.withNavigation ?? true,
      };

      // Create unified generation service
      final generationService = GenerationService(
        templateManager: context.templateManager,
        logger: context.logger,
      );

      // Generate feature using unified service
      final result = await generationService.generate(
        mode: GenerationMode.feature,
        rawVars: rawVars,
        outputDirectory: Directory.current.path,
        dryRun: false,
      );

      cancelToken?.throwIfCancelled();

      if (!result.success) {
        throw McpError.templateError(
          templateId: 'screen',
          error: result.error ?? 'Screen generation failed',
          variables: rawVars,
          context: {
            'screen_name': params.screenName,
            'feature': params.feature ?? 'home',
            'screen_type': params.screenType ?? 'list',
          },
        );
      }

      return FlyGenerateScreenResult(
        success: true,
        message: 'Screen generated successfully',
        filesGenerated: result.filesGenerated,
        screenPath: result.targetDirectory ?? Directory.current.path,
      );
    };
  }
}
