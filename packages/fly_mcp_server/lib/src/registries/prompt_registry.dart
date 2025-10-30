import 'package:fly_mcp_server/src/domain/prompt_type.dart';
import 'package:fly_mcp_server/src/registries/registry.dart';

/// Registry for MCP prompts
class PromptRegistry implements IPromptRegistry {
  @override
  List<Map<String, Object?>> list() {
    return PromptType.values
        .map((type) => type.strategy.getListEntry())
        .toList();
  }

  @override
  Map<String, Object?> getPrompt(Map<String, Object?> params) {
    final id = params['id'] as String?;
    if (id == null) {
      throw StateError('Missing required parameter: id');
    }

    // Find prompt type by ID
    for (final promptType in PromptType.values) {
      if (promptType.id == id) {
        return promptType.strategy.getPrompt(params);
      }
    }

    throw StateError('Unknown prompt id: $id');
  }
}

