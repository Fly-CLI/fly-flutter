import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/templates/template_manager.dart';
import 'package:fly_cli/src/features/mcp/domain/mcp_tool_strategy.dart';
import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Strategy for fly.template.apply tool
class FlyTemplateApplyStrategy extends McpToolStrategy {
  @override
  String get name => 'fly.template.apply';

  @override
  String get description => 'Apply a Fly template to the workspace';

  @override
  Map<String, Object?> get paramsSchema => {
        'type': 'object',
        'properties': {
          'templateId': {'type': 'string'},
          'outputDirectory': {'type': 'string'},
          'variables': {
            'type': 'object',
            'additionalProperties': true,
          },
          'dryRun': {'type': 'boolean'},
          'confirm': {'type': 'boolean'},
        },
        'required': ['templateId', 'outputDirectory'],
        'additionalProperties': false,
      };

  @override
  Map<String, Object?> get resultSchema => {
        'type': 'object',
        'properties': {
          'success': {'type': 'boolean'},
          'targetDirectory': {'type': 'string'},
          'filesGenerated': {'type': 'integer'},
          'duration_ms': {'type': 'integer'},
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
  Duration? get timeout => const Duration(minutes: 15);

  @override
  ToolHandler createHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return (params, {cancelToken, progressNotifier}) async {
      cancelToken?.throwIfCancelled();

      final templateId = params['templateId'] as String?;
      final outputDir = params['outputDirectory'] as String?;
      final variablesMap = (params['variables'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      final dryRun = params['dryRun'] as bool? ?? false;

      if (templateId == null || outputDir == null) {
        return {
          'success': false,
          'message': 'Missing required parameters: templateId and outputDirectory',
        };
      }

      await progressNotifier?.notify(message: 'Loading template $templateId...');

      final templateManager = context.templateManager;
      final template = await templateManager.getTemplate(templateId);

      cancelToken?.throwIfCancelled();

      if (template == null) {
        return {
          'success': false,
          'message': 'Template "$templateId" not found',
        };
      }

      await progressNotifier?.notify(message: 'Generating template...', percent: 50);

      // Convert variables to TemplateVariables
      final templateVariables = TemplateVariables.fromJson({
        'projectName': variablesMap['projectName'] ?? templateId,
        'organization': variablesMap['organization'] ?? 'com.example',
        'platforms': variablesMap['platforms'] ?? ['ios', 'android'],
        ...variablesMap,
      });

      final result = await templateManager.generateProject(
        templateName: templateId,
        projectName: variablesMap['projectName'] as String? ?? templateId,
        outputDirectory: outputDir,
        variables: templateVariables,
        dryRun: dryRun,
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
          'targetDirectory': result.targetDirectory,
          'filesGenerated': result.filesGenerated,
          'duration_ms': result.duration.inMilliseconds,
          'message': 'Template applied successfully',
        };
      }

      if (result is TemplateGenerationDryRun) {
        return {
          'success': true,
          'targetDirectory': result.targetDirectory,
          'filesGenerated': 0,
          'duration_ms': 0,
          'message': 'Dry run completed - preview generated',
        };
      }

      return {
        'success': false,
        'message': 'Unexpected generation result',
      };
    };
  }
}

