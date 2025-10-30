import 'package:dart_mcp/server.dart';
import 'package:fly_cli/src/features/mcp/prompts/prompt_template_registry.dart';
import 'package:fly_mcp_server/src/domain/prompt_strategy.dart';

/// Strategy for the fly.fix.lints prompt
/// 
/// Generates actionable fix suggestions for lint issues with code examples
/// and best practices.
class FixLintsPromptStrategy extends PromptStrategy {
  @override
  String get id => 'fly.fix.lints';

  @override
  String get title => 'Fix lint issues';

  @override
  String get description =>
      'Generate actionable fix suggestions for Dart/Flutter lint issues with code examples';

  @override
  List<PromptArgument> getVariables() {
    return [
      PromptArgument(
        name: 'lintFile',
        description: 'Specific file path to fix (optional, if not provided, fixes all files)',
        required: false,
      ),
      PromptArgument(
        name: 'severity',
        description: 'Minimum severity to fix (error, warning, info)',
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
    
    final lintFile = arguments?['lintFile'] as String?;
    final severity = (arguments?['severity'] as String?) ?? 'warning';
    
    // Prepare template variables
    final templateVariables = <String, dynamic>{
      'lintFile': lintFile,
      'severity': severity,
    };

    // Render template using DotPrompt
    final renderedPrompt = await promptTemplateRegistry.render(
      'fix_lints',
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

