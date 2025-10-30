import 'package:dart_mcp/server.dart';
import 'package:fly_cli/src/features/mcp/prompts/prompt_template_registry.dart';
import 'package:fly_mcp_server/src/domain/prompt_strategy.dart';

/// Strategy for the fly.scaffold.api_client prompt
///
/// Generates a prompt for creating an API client with error handling,
/// serialization, and networking patterns following Fly conventions.
class ScaffoldApiClientPromptStrategy extends PromptStrategy {
  @override
  String get id => 'fly.scaffold.api_client';

  @override
  String get title => 'Scaffold an API client';

  @override
  String get description =>
      'Generate API client code with error handling, serialization, and networking patterns using Fly conventions';

  @override
  List<PromptArgument> getVariables() {
    return [
      PromptArgument(
        name: 'baseUrl',
        description: 'The API base URL (required)',
        required: true,
      ),
      PromptArgument(
        name: 'endpoints',
        description: 'Array of API endpoints to generate',
        required: false,
      ),
      PromptArgument(
        name: 'authentication',
        description: 'Authentication type (bearer, basic, none)',
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

    final baseUrl = arguments?['baseUrl'] as String?;
    if (baseUrl == null || baseUrl.isEmpty) {
      throw StateError('Missing required parameter: baseUrl');
    }

    final auth = (arguments?['authentication'] as String?) ?? 'bearer';
    final endpoints = arguments?['endpoints'] as List?;

    // Prepare template variables
    final templateVariables = <String, dynamic>{
      'baseUrl': baseUrl,
      'authentication': auth,
      'isBearerAuth': auth == 'bearer',
      'isBasicAuth': auth == 'basic',
      'endpoints': endpoints ?? [],
    };

    // Render template using DotPrompt
    final renderedPrompt = await promptTemplateRegistry.render(
      'scaffold_api_client',
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

