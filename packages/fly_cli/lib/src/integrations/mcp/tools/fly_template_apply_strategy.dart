import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/scaffolding/foundation/foundation_orchestrator.dart';
import 'package:fly_cli/src/integrations/mcp/errors/mcp_error.dart';
import 'package:fly_cli/src/integrations/mcp/mcp_tool_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/types/fly_template_apply_params.dart';
import 'package:fly_cli/src/integrations/mcp/tools/types/fly_template_apply_result.dart';
import 'package:fly_cli/src/integrations/mcp/utils/progress_helpers.dart';
import 'package:fly_mcp/fly_mcp.dart';

/// Strategy for fly.template.apply tool
class FlyTemplateApplyStrategy
    extends McpToolStrategy<FlyTemplateApplyParams, FlyTemplateApplyResult> {
  @override
  String get name => 'fly.template.apply';

  @override
  String get description =>
      'Apply a Fly template to the workspace. This tool generates code from a template with the specified variables. '
      'Use dryRun: true to preview changes before applying. Requires confirmation for destructive operations.';

  @override
  ObjectSchema get paramsSchema => ObjectSchema(
        description:
            'Parameters for applying a Fly template. Template variables are passed in the variables object.',
        properties: {
          'templateId': Schema.string(
            description:
                'The identifier of the template to apply (e.g., "fly_foundation"). '
                'Use fly.template.list to see available templates.',
          ),
          'outputDirectory': Schema.string(
            description:
                'The target directory where the template should be applied. Must be a valid path within the workspace.',
          ),
          'variables': ObjectSchema(
            description:
                'Template variables as key-value pairs. Common variables include: '
                'projectName (string), organization (string), platforms (array of strings). '
                'Available variables depend on the template being used.',
            additionalProperties: true,
          ),
          'dryRun': Schema.bool(
            description:
                'If true, preview the template application without actually creating files. '
                'Recommended for testing template parameters before applying.',
          ),
          'confirm': Schema.bool(
            description:
                'Explicit confirmation required for writes-to-disk operations. Must be true to apply template.',
          ),
        },
        required: ['templateId', 'outputDirectory'],
        additionalProperties: false,
      );

  @override
  ObjectSchema get resultSchema => ObjectSchema(
        description:
            'Result from template application. Contains success status, generated files count, and execution details.',
        properties: {
          'success': Schema.bool(
            description: 'Whether the template was applied successfully',
          ),
          'targetDirectory': Schema.string(
            description:
                'The directory where files were generated (null for dry-run)',
          ),
          'filesGenerated': Schema.int(
            description: 'Number of files generated from the template',
          ),
          'duration_ms': Schema.int(
            description: 'Time taken to apply the template in milliseconds',
          ),
          'message': Schema.string(
            description:
                'Human-readable message describing the operation result',
          ),
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

      // Validate required parameters with structured errors
      final validationErrors = <String>[];
      if (params.templateId.isEmpty) {
        validationErrors.add('Missing required parameter: templateId');
      }
      if (params.outputDirectory.isEmpty) {
        validationErrors.add('Missing required parameter: outputDirectory');
      }
      if (validationErrors.isNotEmpty) {
        throw McpError.invalidParams(
          tool: name,
          errors: validationErrors,
          context: {
            'template_id': params.templateId,
            'output_directory': params.outputDirectory,
          },
        );
      }

      final variablesMap = params.variables ?? <String, dynamic>{};
      final dryRun = params.dryRun ?? false;

      // Progress: Loading template
      await ProgressHelpers.notifyTemplateProgress(
        progressNotifier,
        TemplateProgressStage.loading,
      );

      final templateManager = context.templateManager;
      final template = await templateManager.getTemplate(params.templateId);

      cancelToken?.throwIfCancelled();

      if (template == null) {
        // Get available templates for suggestion
        final availableTemplates =
            await templateManager.getAvailableTemplates();
        final availableNames = availableTemplates.map((t) => t.name).toList();
        throw McpError.templateError(
          templateId: params.templateId,
          error: 'Template not found',
          variables: variablesMap,
          context: {
            'available_templates': availableNames,
            'hint':
                'Available templates: ${availableNames.join(", ")}. Use fly.template.list to see all templates',
          },
        );
      }

      // Progress: Template loaded
      await ProgressHelpers.notifyTemplateProgress(
        progressNotifier,
        TemplateProgressStage.loaded,
      );

      // Progress: Validating template variables
      await ProgressHelpers.notifyTemplateProgress(
        progressNotifier,
        TemplateProgressStage.validating,
      );

      // Validate template variables if needed
      // (TemplateManager handles this, but we can add pre-validation here)

      // Progress: Variables validated
      await ProgressHelpers.notifyTemplateProgress(
        progressNotifier,
        TemplateProgressStage.validated,
      );

      // Progress: Generating template
      await ProgressHelpers.notifyTemplateProgress(
        progressNotifier,
        TemplateProgressStage.generating,
      );

      // Prepare raw variables for orchestrator
      final projectName =
          variablesMap['projectName'] as String? ?? params.templateId;
      final rawVars = <String, dynamic>{
        'name': projectName,
        'template': params.templateId,
        'organization':
            variablesMap['organization'] as String? ?? 'com.example',
        'description':
            variablesMap['description'] as String? ?? 'A new Flutter project',
        'platforms':
            variablesMap['platforms'] as List<dynamic>? ?? ['ios', 'android'],
        'generation_mode': 'project',
        'preset': variablesMap['preset'] as String? ?? 'starter',
        'features': variablesMap['features'] as List<dynamic>? ?? [],
        'services': variablesMap['services'] as List<dynamic>? ?? [],
        ...variablesMap,
      };

      // Progress: Generating files
      await ProgressHelpers.notifyTemplateProgress(
        progressNotifier,
        TemplateProgressStage.generatingFiles,
      );

      // Progress: Applying template
      await ProgressHelpers.notifyTemplateProgress(
        progressNotifier,
        TemplateProgressStage.applying,
      );

      // Create orchestrator
      final orchestrator = TemplateGenerationOrchestrator(
        templateManager: templateManager,
        logger: context.logger,
      );

      final stopwatch = Stopwatch()..start();
      final result = await orchestrator.generate(
        rawVars: rawVars,
        outputDirectory: params.outputDirectory,
      );
      stopwatch.stop();

      cancelToken?.throwIfCancelled();

      // Progress: Processing template files
      await ProgressHelpers.notifyTemplateProgress(
        progressNotifier,
        TemplateProgressStage.processing,
      );

      if (!result.success) {
        throw McpError.templateError(
          templateId: params.templateId,
          error: result.error ?? 'Template generation failed',
          variables: variablesMap,
          context: {
            'output_directory': params.outputDirectory,
            'dry_run': dryRun,
          },
        );
      }

      // Progress: Finalizing
      await ProgressHelpers.notifyTemplateProgress(
        progressNotifier,
        TemplateProgressStage.finalizing,
      );

      // Progress: Complete
      await ProgressHelpers.notifyTemplateProgress(
        progressNotifier,
        TemplateProgressStage.complete,
      );

      return FlyTemplateApplyResult(
        success: true,
        targetDirectory: result.targetDirectory,
        filesGenerated: result.files?.length ?? 0,
        durationMs: stopwatch.elapsedMilliseconds,
        message: dryRun
            ? 'Dry run completed - preview generated'
            : 'Template applied successfully',
      );
    };
  }
}
