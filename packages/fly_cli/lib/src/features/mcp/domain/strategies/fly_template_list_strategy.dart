import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/features/mcp/domain/mcp_tool_strategy.dart';
import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Strategy for fly.template.list tool
class FlyTemplateListStrategy extends McpToolStrategy {
  @override
  String get name => 'fly.template.list';

  @override
  String get description => 'List available Fly templates';

  @override
  Map<String, Object?> get paramsSchema => {
        'type': 'object',
        'properties': {},
        'additionalProperties': false,
      };

  @override
  Map<String, Object?> get resultSchema => {
        'type': 'object',
        'properties': {
          'templates': {
            'type': 'array',
            'items': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
                'description': {'type': 'string'},
                'version': {'type': 'string'},
                'features': {'type': 'array', 'items': {'type': 'string'}},
              },
              'required': ['name', 'description', 'version'],
            },
          },
        },
        'required': ['templates'],
      };

  @override
  bool get readOnly => true;

  @override
  bool get writesToDisk => false;

  @override
  bool get requiresConfirmation => false;

  @override
  bool get idempotent => true;

  @override
  ToolHandler createHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return (params, {cancelToken, progressNotifier}) async {
      cancelToken?.throwIfCancelled();
      await progressNotifier?.notify(message: 'Loading templates...');

      final templateManager = context.templateManager;
      final templates = await templateManager.getAvailableTemplates();

      cancelToken?.throwIfCancelled();

      return {
        'templates': templates.map((t) => {
              'name': t.name,
              'description': t.description,
              'version': t.version,
              'features': t.features,
              'minFlutterSdk': t.minFlutterSdk,
              'minDartSdk': t.minDartSdk,
            }).toList(),
      };
    };
  }
}

