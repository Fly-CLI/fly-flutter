import 'package:dart_mcp/server.dart';

import '../domain/prompt_type.dart';
import 'registry.dart';

/// Registry for MCP prompts
class PromptRegistry implements IPromptRegistry {
  @override
  List<Prompt> list() {
    return PromptType.values
        .map((type) => type.strategy.getListEntry())
        .toList();
  }

  @override
  Future<GetPromptResult> getPrompt(Map<String, Object?> params) async {
    final id = params['id'] as String?;
    if (id == null) {
      throw StateError('Missing required parameter: id');
    }

    // Find prompt type by ID
    for (final promptType in PromptType.values) {
      if (promptType.id == id) {
        return await promptType.strategy.getPrompt(params);
      }
    }

    throw StateError('Unknown prompt id: $id');
  }
}
