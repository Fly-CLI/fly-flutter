import 'package:dart_mcp/server.dart';

/// Abstract base class for resource strategies
/// 
/// Each resource type implements a concrete strategy that encapsulates
/// all resource-specific implementation details for listing and reading.
/// 
/// Strategies return intermediate data structures (Maps) that are converted
/// to [Resource] objects by [ResourceRegistry]. The [Resource] type is from
/// `dart_mcp/src/api/resources.dart` and represents MCP protocol resources.
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
  /// 
  /// Returns a map with:
  /// - 'items': List<Map<String, Object?>> where each map contains:
  ///   - 'uri': String (required) - The resource URI
  ///   - 'size': int? (optional) - The resource size in bytes
  ///   These items are converted to [Resource] objects by [ResourceRegistry].
  /// - 'total': int - Total number of items
  /// - 'page': int - Current page number
  /// - 'pageSize': int - Items per page
  Map<String, Object?> list(Map<String, Object?> params);

  /// Read a resource by URI
  /// 
  /// [params] - Request parameters (uri, start, length, etc.)
  /// 
  /// Returns a map with:
  /// - 'content': String? (required) - The resource content
  /// - 'encoding': String? (optional) - Content encoding, defaults to 'utf-8'
  /// - 'mimeType': String? (optional) - MIME type of the content
  /// - 'total': int? (optional) - Total size of the resource
  /// - 'start': int? (optional) - Start position for partial reads
  /// - 'length': int? (optional) - Length of content read
  /// 
  /// The content is used to create [TextResourceContents] or [BlobResourceContents]
  /// by [ResourceRegistry] which implements the MCP protocol.
  Map<String, Object?> read(Map<String, Object?> params);
}

