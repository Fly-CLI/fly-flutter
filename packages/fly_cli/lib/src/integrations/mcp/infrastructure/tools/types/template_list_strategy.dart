import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/integrations/mcp/application/mcp_tool_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/tools/types/template_list_params.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/tools/types/template_list_result.dart';
import 'package:fly_mcp/fly_mcp.dart';

/// Strategy for fly.template.list tool
class TemplateListStrategy
    extends McpToolStrategy<TemplateListParams, TemplateListResult> {
  @override
  String get name => 'fly.template.list';

  @override
  String get description => 'List available Fly templates';

  @override
  ObjectSchema get paramsSchema => ObjectSchema(
    properties: {},
    additionalProperties: false,
  );

  @override
  ObjectSchema get resultSchema => ObjectSchema(
    properties: {
      'templates': Schema.list(
        items: ObjectSchema(
          properties: {
            'name': Schema.string(),
            'description': Schema.string(),
            'version': Schema.string(),
            'features': Schema.list(items: Schema.string()),
          },
          required: ['name', 'description', 'version'],
        ),
      ),
    },
    required: ['templates'],
  );

  @override
  bool get readOnly => true;

  @override
  bool get writesToDisk => false;

  @override
  bool get requiresConfirmation => false;

  @override
  bool get idempotent => true;

  @override
  TemplateListParams paramsFromJson(Map<String, Object?> json) {
    return TemplateListParams.fromJson(json);
  }

  @override
  TypedToolHandler<TemplateListParams, TemplateListResult> createTypedHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return (params, {cancelToken, progressNotifier}) async {
      cancelToken?.throwIfCancelled();
      await progressNotifier?.notify(message: 'Loading templates...');

      final templateManager = context.templateManager;
      final templates = await templateManager.getAvailableTemplates();

      cancelToken?.throwIfCancelled();

      final templateInfos = <TemplateInfo>[];
      for (final t in templates) {
        templateInfos.add(
          TemplateInfo(
            name: t.name,
            description: t.description,
            version: t.version,
            features: t.features,
            minFlutterSdk: t.minFlutterSdk,
            minDartSdk: t.minDartSdk,
          ),
        );
      }

      return TemplateListResult(templates: templateInfos);
    };
  }
}
