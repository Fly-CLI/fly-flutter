import 'package:fly_cli/src/integrations/mcp/prompt_strategy_registry.dart';
import 'package:fly_mcp/fly_mcp.dart';

/// Concrete implementation of PromptStrategyRegistryProvider
///
/// This bridges the fly_cli registry with the fly_mcp abstraction.
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
