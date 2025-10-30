/// Abstract base class for resource strategies
/// 
/// Each resource type implements a concrete strategy that encapsulates
/// all resource-specific implementation details for listing and reading.
abstract class ResourceStrategy {
  /// The URI prefix for this resource type (e.g., 'workspace://', 'logs://run/')
  String get uriPrefix;

  /// Human-readable description of the resource type
  String get description;

  /// Whether this resource type is read-only
  bool get readOnly => true;

  /// List available resources of this type
  /// 
  /// [params] - Request parameters (uri, page, pageSize, etc.)
  /// Returns a map with 'items', 'total', 'page', 'pageSize'
  Map<String, Object?> list(Map<String, Object?> params);

  /// Read a resource by URI
  /// 
  /// [params] - Request parameters (uri, start, length, etc.)
  /// Returns a map with 'content', 'encoding', 'total', 'start', 'length'
  Map<String, Object?> read(Map<String, Object?> params);
}

