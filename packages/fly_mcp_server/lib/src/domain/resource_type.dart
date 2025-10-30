import 'package:fly_mcp_server/src/domain/resource_strategy.dart';
import 'package:fly_mcp_server/src/domain/resource_strategy_registry.dart';

/// Enum representing all available resource types
enum ResourceType {
  workspace,
  logsRun,
  logsBuild,
}

/// Extension providing resource metadata and strategy delegation
/// 
/// Delegates to strategy classes for resource-specific implementation details,
/// maintaining enum exhaustiveness while leveraging the Strategy pattern
/// for flexibility and extensibility.
extension ResourceTypeExtension on ResourceType {
  /// Gets the strategy for this resource type
  ResourceStrategy get strategy =>
      resourceStrategyRegistry.getStrategy(this);

  /// The URI prefix for this resource type
  String get uriPrefix => strategy.uriPrefix;

  /// Human-readable description of the resource type
  String get description => strategy.description;

  /// Whether this resource type is read-only
  bool get readOnly => strategy.readOnly;
}

