import 'dart:io';

import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/templates/template_manager.dart';
import 'package:fly_cli/src/features/mcp/domain/mcp_tool_strategy.dart';
import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Strategy for flutter.create tool
class FlutterCreateStrategy extends McpToolStrategy {
  @override
  String get name => 'flutter.create';

  @override
  String get description => 'Create a new Flutter project using Fly templates';

  @override
  Map<String, Object?> get paramsSchema => {
        'type': 'object',
        'properties': {
          'projectName': {'type': 'string'},
          'template': {'type': 'string', 'default': 'riverpod'},
          'organization': {'type': 'string', 'default': 'com.example'},
          'platforms': {
            'type': 'array',
            'items': {'type': 'string'},
            'default': ['ios', 'android'],
          },
          'outputDirectory': {'type': 'string'},
          'confirm': {'type': 'boolean'},
        },
        'required': ['projectName'],
        'additionalProperties': false,
      };

  @override
  Map<String, Object?> get resultSchema => {
        'type': 'object',
        'properties': {
          'success': {'type': 'boolean'},
          'projectPath': {'type': 'string'},
          'filesGenerated': {'type': 'integer'},
          'message': {'type': 'string'},
        },
        'required': ['success', 'message'],
      };

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
  ToolHandler createHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return (params, {cancelToken, progressNotifier}) async {
      cancelToken?.throwIfCancelled();

      final projectName = params['projectName'] as String?;
      if (projectName == null || projectName.isEmpty) {
        return {
          'success': false,
          'message': 'Missing required parameter: projectName',
        };
      }

      final template = params['template'] as String? ?? 'riverpod';
      final organization = params['organization'] as String? ?? 'com.example';
      final platforms = (params['platforms'] as List?)?.cast<String>() ?? ['ios', 'android'];
      final outputDir = params['outputDirectory'] as String? ?? Directory.current.path;

      await progressNotifier?.notify(message: 'Creating Flutter project: $projectName...');

      final templateManager = context.templateManager;

      // Check if template exists
      final templateInfo = await templateManager.getTemplate(template);
      cancelToken?.throwIfCancelled();

      if (templateInfo == null) {
        return {
          'success': false,
          'message': 'Template "$template" not found. Available templates: ${(await templateManager.getAvailableTemplates()).map((t) => t.name).join(", ")}',
        };
      }

      await progressNotifier?.notify(message: 'Generating project structure...', percent: 30);

      final projectPath = outputDir.isEmpty || outputDir == Directory.current.path
          ? Directory.current.path
          : outputDir;

      final templateVariables = TemplateVariables(
        projectName: projectName,
        organization: organization,
        platforms: platforms,
      );

      await progressNotifier?.notify(message: 'Applying template...', percent: 60);

      final result = await templateManager.generateProject(
        templateName: template,
        projectName: projectName,
        outputDirectory: projectPath,
        variables: templateVariables,
      );

      cancelToken?.throwIfCancelled();

      if (result is TemplateGenerationFailure) {
        return {
          'success': false,
          'message': result.error,
        };
      }

      if (result is TemplateGenerationSuccess) {
        return {
          'success': true,
          'projectPath': result.targetDirectory,
          'filesGenerated': result.filesGenerated,
          'message': 'Flutter project created successfully',
        };
      }

      return {
        'success': false,
        'message': 'Unexpected generation result',
      };
    };
  }
}

