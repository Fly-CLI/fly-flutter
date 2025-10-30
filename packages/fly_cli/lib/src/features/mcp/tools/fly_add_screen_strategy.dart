import 'dart:io';

import 'package:fly_cli/src/core/command_foundation/command_context.dart';
import 'package:fly_cli/src/core/templates/brick_info.dart';
import 'package:fly_cli/src/core/templates/template_manager.dart';
import 'package:fly_cli/src/features/mcp/mcp_tool_strategy.dart';
import 'package:fly_cli/src/features/mcp/tools/types/fly_add_screen_params.dart';
import 'package:fly_cli/src/features/mcp/tools/types/fly_add_screen_result.dart';
import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Strategy for fly.add.screen tool
class FlyAddScreenStrategy
    extends McpToolStrategy<FlyAddScreenParams, FlyAddScreenResult> {
  @override
  String get name => 'fly.add.screen';

  @override
  String get description => 'Add a new screen component to the current project';

  @override
  ObjectSchema get paramsSchema => ObjectSchema(
        properties: {
          'screenName': Schema.string(),
          'feature': Schema.string(),
          'screenType': Schema.string(
              enumValues: ['list', 'detail', 'form', 'auth', 'settings']),
          'withViewModel': Schema.bool(),
          'withTests': Schema.bool(),
          'withValidation': Schema.bool(),
          'withNavigation': Schema.bool(),
        },
        required: ['screenName'],
        additionalProperties: false,
      );

  @override
  ObjectSchema get resultSchema => ObjectSchema(
        properties: {
          'success': Schema.bool(),
          'message': Schema.string(),
          'filesGenerated': Schema.int(),
          'screenPath': Schema.string(),
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

      if (params.screenName.isEmpty) {
        return FlyAddScreenResult(
          success: false,
          message: 'Missing required parameter: screenName',
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
        return FlyAddScreenResult(
          success: false,
          message: 'Failed to generate screen: ${result.error}',
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
