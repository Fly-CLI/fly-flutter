import 'package:fly_mcp_server/src/domain/prompt_strategy.dart';
import 'package:fly_mcp_server/src/domain/prompt_type.dart';
import 'package:fly_mcp_server/src/domain/strategies/prompt/scaffold_page_prompt_strategy.dart';

/// Registry for prompt strategies
/// 
/// Maps PromptType enum values to their corresponding strategy instances.
/// Strategies are created lazily on demand and cached for reuse.
class PromptStrategyRegistry {
  final Map<PromptType, PromptStrategy> _strategies = {};

  /// Gets the strategy for the given prompt type
  /// 
  /// Creates and caches the strategy instance on first access.
  PromptStrategy getStrategy(PromptType promptType) {
    return _strategies.putIfAbsent(
      promptType,
      () => _createStrategy(promptType),
    );
  }

  /// Creates a strategy instance for the given prompt type
  PromptStrategy _createStrategy(PromptType promptType) {
    switch (promptType) {
      case PromptType.scaffoldPage:
        return ScaffoldPagePromptStrategy();
    }
  }
}

/// Global prompt strategy registry instance
final promptStrategyRegistry = PromptStrategyRegistry();

