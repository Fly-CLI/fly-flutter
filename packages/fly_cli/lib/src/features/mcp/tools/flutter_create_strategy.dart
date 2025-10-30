import 'dart:io';

import 'package:fly_cli/src/core/command_foundation/command_context.dart';
import 'package:fly_cli/src/core/templates/template_info.dart';
import 'package:fly_cli/src/core/templates/template_manager.dart';
import 'package:fly_cli/src/features/mcp/mcp_tool_strategy.dart';
import 'package:fly_cli/src/features/mcp/tools/types/flutter_create_params.dart';
import 'package:fly_cli/src/features/mcp/tools/types/flutter_create_result.dart';
import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Strategy for flutter.create tool
class FlutterCreateStrategy
    extends McpToolStrategy<FlutterCreateParams, FlutterCreateResult> {
  @override
  String get name => 'flutter.create';

  @override
  String get description => 'Create a new Flutter project using Fly templates';

  @override
  ObjectSchema get paramsSchema => ObjectSchema(
        properties: {
          'projectName': Schema.string(),
          'template': Schema.string(),
          'organization': Schema.string(),
          'platforms': Schema.list(items: Schema.string()),
          'outputDirectory': Schema.string(),
          'confirm': Schema.bool(),
        },
        required: ['projectName'],
        additionalProperties: false,
      );

  @override
  ObjectSchema get resultSchema => ObjectSchema(
        properties: {
          'success': Schema.bool(),
          'projectPath': Schema.string(),
          'filesGenerated': Schema.int(),
          'message': Schema.string(),
        },
        required: ['success', 'message'],
      );

  @override
  bool get readOnly => false;

  @override
  bool get writesToDisk => true;

  @override
  bool get requiresConfirmation => true;

  @override
  bool get idempotent => false;

  @override
  Duration? get timeout => const Duration(minutes: 10);

  @override
  FlutterCreateParams paramsFromJson(Map<String, Object?> json) {
    return FlutterCreateParams.fromJson(json);
  }

  @override
  TypedToolHandler<FlutterCreateParams, FlutterCreateResult>
      createTypedHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return (params, {cancelToken, progressNotifier}) async {
      cancelToken?.throwIfCancelled();

      if (params.projectName.isEmpty) {
        return FlutterCreateResult(
          success: false,
          message: 'Missing required parameter: projectName',
        );
      }

      final template = params.template ?? 'riverpod';
      final organization = params.organization ?? 'com.example';
      final platforms =
          params.platforms ?? ['ios', 'android'];
      final outputDir =
          params.outputDirectory ?? Directory.current.path;

      await progressNotifier?.notify(
          message: 'Creating Flutter project: ${params.projectName}...');

      final templateManager = context.templateManager;

      // Check if template exists
      final templateInfo = await templateManager.getTemplate(template);
      cancelToken?.throwIfCancelled();

      if (templateInfo == null) {
        final availableTemplates =
            await templateManager.getAvailableTemplates();
        return FlutterCreateResult(
          success: false,
          message:
              'Template "$template" not found. Available templates: ${availableTemplates.map((TemplateInfo t) => t.name).join(", ")}',
        );
      }

      await progressNotifier?.notify(
          message: 'Generating project structure...', percent: 30);

      final projectPath = outputDir.isEmpty ||
              outputDir == Directory.current.path
          ? Directory.current.path
          : outputDir;

      final templateVariables = TemplateVariables(
        projectName: params.projectName,
        organization: organization,
        platforms: platforms,
      );

      await progressNotifier?.notify(message: 'Applying template...', percent: 60);

      final result = await templateManager.generateProject(
        templateName: template,
        projectName: params.projectName,
        outputDirectory: projectPath,
        variables: templateVariables,
      );

      cancelToken?.throwIfCancelled();

      if (result is TemplateGenerationFailure) {
        return FlutterCreateResult(
          success: false,
          message: result.error,
        );
      }

      if (result is TemplateGenerationSuccess) {
        return FlutterCreateResult(
          success: true,
          projectPath: result.targetDirectory,
          filesGenerated: result.filesGenerated,
          message: 'Flutter project created successfully',
        );
      }

      return FlutterCreateResult(
        success: false,
        message: 'Unexpected generation result',
      );
    };
  }
}


