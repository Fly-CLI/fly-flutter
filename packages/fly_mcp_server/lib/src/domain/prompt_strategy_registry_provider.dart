import 'package:fly_mcp_server/src/domain/prompt_strategy.dart';
import 'package:fly_mcp_server/src/domain/prompt_type.dart';

/// Abstract interface for prompt strategy registry accessor
/// 
/// This allows fly_mcp_server to access strategies without directly depending
/// on concrete implementations, which live in fly_cli.
abstract class PromptStrategyRegistryProvider {
  /// Gets the strategy for the given prompt type
  PromptStrategy getStrategy(PromptType promptType);
}

/// Global registry provider instance
/// 
/// This should be set by fly_cli when initializing the MCP server.
PromptStrategyRegistryProvider? _globalRegistryProvider;

/// Sets the global prompt strategy registry provider
/// 
/// This should be called by fly_cli during initialization.
void setPromptStrategyRegistryProvider(PromptStrategyRegistryProvider provider) {
  _globalRegistryProvider = provider;
}

/// Gets the strategy for the given prompt type from the global provider
/// 
/// Throws a [StateError] if no provider has been set.
PromptStrategy getPromptStrategy(PromptType promptType) {
  final provider = _globalRegistryProvider;
  if (provider == null) {
    throw StateError(
      'Prompt strategy registry provider has not been set. '
      'Call setPromptStrategyRegistryProvider() during initialization.',
    );
  }
  return provider.getStrategy(promptType);
}

