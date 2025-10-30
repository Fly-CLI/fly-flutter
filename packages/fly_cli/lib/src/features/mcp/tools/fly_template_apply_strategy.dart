import 'package:fly_cli/src/core/command_foundation/command_context.dart';
import 'package:fly_cli/src/core/templates/template_manager.dart';
import 'package:fly_cli/src/features/mcp/mcp_tool_strategy.dart';
import 'package:fly_cli/src/features/mcp/tools/types/fly_template_apply_params.dart';
import 'package:fly_cli/src/features/mcp/tools/types/fly_template_apply_result.dart';
import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Strategy for fly.template.apply tool
class FlyTemplateApplyStrategy extends
    McpToolStrategy<FlyTemplateApplyParams, FlyTemplateApplyResult> {
  @override
  String get name => 'fly.template.apply';

  @override
  String get description => 'Apply a Fly template to the workspace';

  @override
  ObjectSchema get paramsSchema => ObjectSchema(
        properties: {
          'templateId': Schema.string(),
          'outputDirectory': Schema.string(),
          'variables': ObjectSchema(additionalProperties: true),
          'dryRun': Schema.bool(),
          'confirm': Schema.bool(),
        },
        required: ['templateId', 'outputDirectory'],
        additionalProperties: false,
      );

  @override
  ObjectSchema get resultSchema => ObjectSchema(
        properties: {
          'success': Schema.bool(),
          'targetDirectory': Schema.string(),
          'filesGenerated': Schema.int(),
          'duration_ms': Schema.int(),
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
  Duration? get timeout => const Duration(minutes: 15);

  @override
  FlyTemplateApplyParams paramsFromJson(Map<String, Object?> json) {
    return FlyTemplateApplyParams.fromJson(json);
  }

  @override
  TypedToolHandler<FlyTemplateApplyParams, FlyTemplateApplyResult>
      createTypedHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return (params, {cancelToken, progressNotifier}) async {
      cancelToken?.throwIfCancelled();

      if (params.templateId.isEmpty || params.outputDirectory.isEmpty) {
        return FlyTemplateApplyResult(
          success: false,
          message:
              'Missing required parameters: templateId and outputDirectory',
        );
      }

      final variablesMap = params.variables ?? <String, dynamic>{};
      final dryRun = params.dryRun ?? false;

      await progressNotifier?.notify(
          message: 'Loading template ${params.templateId}...');

      final templateManager = context.templateManager;
      final template =
          await templateManager.getTemplate(params.templateId);

      cancelToken?.throwIfCancelled();

      if (template == null) {
        return FlyTemplateApplyResult(
          success: false,
          message: 'Template "${params.templateId}" not found',
        );
      }

      await progressNotifier?.notify(
          message: 'Generating template...', percent: 50);

      // Convert variables to TemplateVariables
      final templateVariables = TemplateVariables.fromJson({
        'projectName':
            variablesMap['projectName'] ?? params.templateId,
        'organization':
            variablesMap['organization'] ?? 'com.example',
        'platforms': variablesMap['platforms'] ?? ['ios', 'android'],
        ...variablesMap,
      });

      final result = await templateManager.generateProject(
        templateName: params.templateId,
        projectName:
            variablesMap['projectName'] as String? ?? params.templateId,
        outputDirectory: params.outputDirectory,
        variables: templateVariables,
        dryRun: dryRun,
      );

      cancelToken?.throwIfCancelled();

      if (result is TemplateGenerationFailure) {
        return FlyTemplateApplyResult(
          success: false,
          message: result.error,
        );
      }

      if (result is TemplateGenerationSuccess) {
        return FlyTemplateApplyResult(
          success: true,
          targetDirectory: result.targetDirectory,
          filesGenerated: result.filesGenerated,
          durationMs: result.duration.inMilliseconds,
          message: 'Template applied successfully',
        );
      }

      if (result is TemplateGenerationDryRun) {
        return FlyTemplateApplyResult(
          success: true,
          targetDirectory: null,
          filesGenerated: 0,
          durationMs: 0,
          message: 'Dry run completed - preview generated',
        );
      }

      return FlyTemplateApplyResult(
        success: false,
        message: 'Unexpected generation result',
      );
    };
  }
}


