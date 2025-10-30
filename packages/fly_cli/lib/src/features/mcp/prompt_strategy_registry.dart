import 'package:fly_cli/src/features/mcp/prompts/fix_lints_prompt_strategy.dart';
import 'package:fly_cli/src/features/mcp/prompts/scaffold_api_client_prompt_strategy.dart';
import 'package:fly_cli/src/features/mcp/prompts/scaffold_feature_prompt_strategy.dart';
import 'package:fly_cli/src/features/mcp/prompts/scaffold_page_prompt_strategy.dart';
import 'package:fly_mcp_server/src/domain/prompt_strategy.dart';
import 'package:fly_mcp_server/src/domain/prompt_type.dart';

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
      case PromptType.scaffoldFeature:
        return ScaffoldFeaturePromptStrategy();
      case PromptType.scaffoldApiClient:
        return ScaffoldApiClientPromptStrategy();
      case PromptType.fixLints:
        return FixLintsPromptStrategy();
    }
  }
}

/// Global prompt strategy registry instance
final promptStrategyRegistry = PromptStrategyRegistry();

