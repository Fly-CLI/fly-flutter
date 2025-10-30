import 'package:dart_mcp/server.dart';
import 'package:fly_cli/src/features/mcp/prompts/prompt_template_registry.dart';
import 'package:fly_mcp_server/src/domain/prompt_strategy.dart';

/// Strategy for the fly.scaffold.page prompt
class ScaffoldPagePromptStrategy extends PromptStrategy {
  @override
  String get id => 'fly.scaffold.page';

  @override
  String get title => 'Scaffold a Flutter page';

  @override
  String get description =>
      'Generate a new Flutter page (widget + route) with Fly conventions';

  @override
  List<PromptArgument> getVariables() {
    return [
      PromptArgument(
        name: 'name',
        description: 'The name of the page to scaffold',
        required: true,
      ),
      PromptArgument(
        name: 'stateManagement',
        description: 'State management approach (default: riverpod)',
        required: false,
      ),
    ];
  }

  @override
  Future<GetPromptResult> getPrompt(Map<String, Object?> params) async {
    final id = params['id'] as String?;
    if (id != this.id) {
      throw StateError('Unknown prompt id');
    }
    // Support both 'arguments' (MCP protocol) and 'variables' (backward compatibility)
    Map<String, Object?>? arguments;
    final argumentsValue = params['arguments'] ?? params['variables'];
    if (argumentsValue != null) {
      if (argumentsValue is Map) {
        arguments = Map<String, Object?>.from(argumentsValue);
      }
    }
    final name = arguments?['name'] as String?;
    if (name == null || name.isEmpty) {
      throw StateError('Missing required parameter: name');
    }
    final state = (arguments?['stateManagement'] as String?) ?? 'riverpod';
    
    // Prepare template variables
    final templateVariables = <String, dynamic>{
      'name': name,
      'stateManagement': state,
    };

    // Render template using DotPrompt
    final renderedPrompt = await promptTemplateRegistry.render(
      'scaffold_page',
      templateVariables,
    );
    
    return GetPromptResult(
      messages: [
        PromptMessage(
          role: Role.user,
          content: TextContent(text: renderedPrompt),
        ),
      ],
    );
  }
}

