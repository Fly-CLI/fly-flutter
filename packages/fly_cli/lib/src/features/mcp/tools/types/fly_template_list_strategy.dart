import 'package:fly_cli/src/core/command_foundation/command_context.dart';
import 'package:fly_cli/src/core/templates/template_info.dart' as core;
import 'package:fly_cli/src/features/mcp/mcp_tool_strategy.dart';
import 'package:fly_cli/src/features/mcp/tools/types/fly_template_list_params.dart';
import 'package:fly_cli/src/features/mcp/tools/types/fly_template_list_result.dart';
import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Strategy for fly.template.list tool
class FlyTemplateListStrategy extends
    McpToolStrategy<FlyTemplateListParams, FlyTemplateListResult> {
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
  FlyTemplateListParams paramsFromJson(Map<String, Object?> json) {
    return FlyTemplateListParams.fromJson(json);
  }

  @override
  TypedToolHandler<FlyTemplateListParams, FlyTemplateListResult>
      createTypedHandler(
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
        templateInfos.add(TemplateInfo(
          name: t.name,
          description: t.description,
          version: t.version,
          features: t.features,
          minFlutterSdk: t.minFlutterSdk,
          minDartSdk: t.minDartSdk,
        ));
      }

      return FlyTemplateListResult(templates: templateInfos);
    };
  }
}


