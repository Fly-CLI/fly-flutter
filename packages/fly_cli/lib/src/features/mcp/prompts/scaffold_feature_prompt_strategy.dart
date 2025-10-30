import 'package:dart_mcp/server.dart';
import 'package:fly_cli/src/features/mcp/prompts/prompt_template_registry.dart';
import 'package:fly_mcp_server/src/domain/prompt_strategy.dart';

/// Strategy for the fly.scaffold.feature prompt
///
/// Generates a prompt for scaffolding a complete feature module with
/// screens, services, routing, and state management.
class ScaffoldFeaturePromptStrategy extends PromptStrategy {
  @override
  String get id => 'fly.scaffold.feature';

  @override
  String get title => 'Scaffold a feature module';

  @override
  String get description =>
      'Generate a complete Flutter feature module with screens, services, and routing using Fly conventions';

  @override
  List<PromptArgument> getVariables() {
    return [
      PromptArgument(
        name: 'featureName',
        description: 'The name of the feature to scaffold',
        required: true,
      ),
      PromptArgument(
        name: 'screens',
        description: 'Array of screen names to include in the feature',
        required: false,
      ),
      PromptArgument(
        name: 'services',
        description: 'Array of service names to include in the feature',
        required: false,
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

    final featureName = arguments?['featureName'] as String?;
    if (featureName == null || featureName.isEmpty) {
      throw StateError('Missing required parameter: featureName');
    }

    final stateManagement =
        (arguments?['stateManagement'] as String?) ?? 'riverpod';
    final screens = arguments?['screens'] as List?;
    final services = arguments?['services'] as List?;

    // Prepare template variables
    final templateVariables = <String, dynamic>{
      'featureName': featureName,
      'featureNameLowerCase': featureName.toLowerCase(),
      'stateManagement': stateManagement,
      'screens': screens ?? [],
      'services': services ?? [],
    };

    // Render template using DotPrompt
    final renderedPrompt = await promptTemplateRegistry.render(
      'scaffold_feature',
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

