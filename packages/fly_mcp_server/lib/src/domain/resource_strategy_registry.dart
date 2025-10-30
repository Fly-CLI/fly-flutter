import 'package:fly_mcp_server/src/domain/resource_strategy.dart';
import 'package:fly_mcp_server/src/domain/resource_type.dart';
import 'package:fly_mcp_server/src/domain/strategies/resource/logs_build_resource_strategy.dart';
import 'package:fly_mcp_server/src/domain/strategies/resource/logs_run_resource_strategy.dart';
import 'package:fly_mcp_server/src/domain/strategies/resource/workspace_resource_strategy.dart';

/// Registry for resource strategies
/// 
/// Maps ResourceType enum values to their corresponding strategy instances.
/// Strategies are created lazily on demand and cached for reuse.
class ResourceStrategyRegistry {
  final Map<ResourceType, ResourceStrategy> _strategies = {};

  /// Gets the strategy for the given resource type
  /// 
  /// Creates and caches the strategy instance on first access.
  ResourceStrategy getStrategy(ResourceType resourceType) {
    return _strategies.putIfAbsent(
      resourceType,
      () => _createStrategy(resourceType),
    );
  }

  /// Creates a strategy instance for the given resource type
  ResourceStrategy _createStrategy(ResourceType resourceType) {
    switch (resourceType) {
      case ResourceType.workspace:
        return WorkspaceResourceStrategy();
      case ResourceType.logsRun:
        return LogsRunResourceStrategy();
      case ResourceType.logsBuild:
        return LogsBuildResourceStrategy();
    }
  }
}

/// Global resource strategy registry instance
final resourceStrategyRegistry = ResourceStrategyRegistry();

