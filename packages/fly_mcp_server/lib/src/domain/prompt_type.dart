import 'package:fly_mcp_server/src/domain/prompt_strategy.dart';
import 'package:fly_mcp_server/src/domain/prompt_strategy_registry.dart';

/// Enum representing all available prompt types
enum PromptType {
  scaffoldPage,
}

/// Extension providing prompt metadata and strategy delegation
/// 
/// Delegates to strategy classes for prompt-specific implementation details,
/// maintaining enum exhaustiveness while leveraging the Strategy pattern
/// for flexibility and extensibility.
extension PromptTypeExtension on PromptType {
  /// Gets the strategy for this prompt type
  PromptStrategy get strategy =>
      promptStrategyRegistry.getStrategy(this);

  /// The prompt ID as it appears in MCP
  String get id => strategy.id;

  /// Human-readable title of the prompt
  String get title => strategy.title;

  /// Human-readable description of the prompt
  String get description => strategy.description;
}

