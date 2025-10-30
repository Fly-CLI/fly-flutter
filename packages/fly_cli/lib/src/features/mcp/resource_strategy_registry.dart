import 'package:fly_cli/src/features/mcp/resources/dependencies_resource_strategy.dart';
import 'package:fly_cli/src/features/mcp/resources/logs_build_resource_strategy.dart';
import 'package:fly_cli/src/features/mcp/resources/logs_run_resource_strategy.dart';
import 'package:fly_cli/src/features/mcp/resources/manifest_resource_strategy.dart';
import 'package:fly_cli/src/features/mcp/resources/tests_resource_strategy.dart';
import 'package:fly_cli/src/features/mcp/resources/workspace_resource_strategy.dart';
import 'package:fly_mcp_server/src/domain/resource_strategy.dart';
import 'package:fly_mcp_server/src/domain/resource_type.dart';

/// Registry for resource strategies
/// 
/// Maps ResourceType enum values to their corresponding strategy instances.
/// Strategies are created lazily on demand and cached for reuse.
/// 
/// **Note:** This is an optional convenience class. For complete control,
/// users should create ResourceStrategy instances directly and pass them to
/// ResourceRegistry. This registry is only provided as a convenience for
/// common use cases with the ResourceType enum.
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
      case ResourceType.manifest:
        return ManifestResourceStrategy();
      case ResourceType.dependencies:
        return DependenciesResourceStrategy();
      case ResourceType.tests:
        return TestsResourceStrategy();
    }
  }
}

/// Global resource strategy registry instance
final resourceStrategyRegistry = ResourceStrategyRegistry();

