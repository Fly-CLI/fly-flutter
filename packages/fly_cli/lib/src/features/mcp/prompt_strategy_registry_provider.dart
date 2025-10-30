import 'package:fly_mcp_server/src/domain/prompt_strategy.dart';
import 'package:fly_mcp_server/src/domain/prompt_strategy_registry_provider.dart';
import 'package:fly_mcp_server/src/domain/prompt_type.dart';
import 'package:fly_cli/src/features/mcp/prompt_strategy_registry.dart';

/// Concrete implementation of PromptStrategyRegistryProvider
/// 
/// This bridges the fly_cli registry with the fly_mcp_server abstraction.
class FlyCliPromptStrategyRegistryProvider
    implements PromptStrategyRegistryProvider {
  final PromptStrategyRegistry _registry;

  FlyCliPromptStrategyRegistryProvider(this._registry);

  @override
  PromptStrategy getStrategy(PromptType promptType) {
    return _registry.getStrategy(promptType);
  }
}

/// Initialize the prompt strategy registry provider
/// 
/// This should be called during MCP server initialization in fly_cli.
void initializePromptStrategyRegistry() {
  final provider = FlyCliPromptStrategyRegistryProvider(promptStrategyRegistry);
  setPromptStrategyRegistryProvider(provider);
}

