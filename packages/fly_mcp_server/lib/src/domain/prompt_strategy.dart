/// Abstract base class for prompt strategies
/// 
/// Each prompt type implements a concrete strategy that encapsulates
/// all prompt-specific implementation details for listing and getting.
abstract class PromptStrategy {
  /// The prompt ID as it appears in MCP (e.g., 'fly.scaffold.page')
  String get id;

  /// Human-readable title of the prompt
  String get title;

  /// Human-readable description of the prompt
  String get description;

  /// Get the prompt list entry (for prompts/list)
  Map<String, Object?> getListEntry() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'variables': getVariables(),
    };
  }

  /// Get the variable definitions for this prompt
  List<Map<String, Object?>> getVariables();

  /// Get the prompt content (for prompts/get)
  /// 
  /// [params] - Request parameters (id, variables, etc.)
  /// Returns a map with 'id', 'text', or 'variablesNeeded'
  Map<String, Object?> getPrompt(Map<String, Object?> params);
}

