import 'package:dart_mcp/server.dart';
import 'package:fly_mcp_server/src/domain/resource_strategy.dart';
import 'package:fly_mcp_server/src/log_resource_provider.dart';
import 'package:fly_mcp_server/src/registries/registry.dart';

/// Registry for MCP resources
/// 
/// Accepts a list of [ResourceStrategy] instances that define what resources
/// are available. Users have complete control over which strategies to use.
/// 
/// This registry converts intermediate data structures returned by strategies
/// to [Resource] objects from `dart_mcp/src/api/resources.dart`, which
/// represent MCP protocol resources.
class ResourceRegistry implements IResourceRegistry {
  /// Creates a ResourceRegistry with the given strategies
  /// 
  /// [strategies] - List of ResourceStrategy instances to handle resource requests.
  /// Strategies are matched by their URI prefix when reading resources.
  ResourceRegistry({required List<ResourceStrategy> strategies})
      : _strategies = strategies;

  final List<ResourceStrategy> _strategies;

  @override
  ListResourcesResult list(ListResourcesRequest request) {
    // List resources from all strategies and combine them
    // Note: cursor is for pagination, not filtering by resource type
    final params = <String, Object?>{};
    
    // Get resources from all strategies
    final allResources = <Resource>[];
    
    // Iterate over all strategies and collect resources
    for (final strategy in _strategies) {
      final result = strategy.list(params);
      allResources.addAll(_convertStrategyItemsToResources(
        result['items'] as List<dynamic>? ?? [],
      ));
    }

    // Sort resources by URI for consistent ordering
    allResources.sort((a, b) => a.uri.compareTo(b.uri));

    return ListResourcesResult(resources: allResources);
  }

  /// Get strategy from URI by matching against URI prefixes
  ResourceStrategy? _getStrategyFromUri(String uri) {
    for (final strategy in _strategies) {
      if (uri.startsWith(strategy.uriPrefix)) {
        return strategy;
      }
    }
    return null;
  }

  /// Convert strategy result items to [Resource] objects
  /// 
  /// Takes intermediate map data from [ResourceStrategy.list()] and converts
  /// each item to a [Resource] object from `dart_mcp/src/api/resources.dart`.
  /// Each item map must contain at least a 'uri' field.
  List<Resource> _convertStrategyItemsToResources(List<dynamic> items) {
    return items.map<Resource>((item) {
      final itemMap = item as Map<String, Object?>;
      final uri = itemMap['uri'] as String? ?? '';
      final size = itemMap['size'] as int?;
      
      // Extract name from URI
      String name = uri.split('/').last;
      if (name.isEmpty || name == uri) {
        // If no path separator or URI is the name, try to extract meaningful name
        final strategy = _getStrategyFromUri(uri);
        if (strategy != null) {
          final prefix = strategy.uriPrefix;
          final suffix = uri.replaceFirst(prefix, '');
          if (suffix.isNotEmpty) {
            // Use the suffix as the name, prefixed with strategy description if helpful
            final suffixParts = suffix.split('/');
            name = suffixParts.last.isNotEmpty ? suffixParts.last : suffix;
          } else {
            // Fallback to strategy description or URI itself
            name = strategy.description;
          }
        } else {
          name = uri;
        }
      }
      
      // Determine MIME type from URI extension or use text/plain default
      final mimeType = _guessMimeType(uri);
      
      return Resource(
        uri: uri,
        name: name,
        mimeType: mimeType,
        size: size,
      );
    }).toList();
  }

  @override
  ReadResourceResult read(ReadResourceRequest request) {
    final uri = request.uri;

    // Convert ReadResourceRequest to params map for strategies
    final params = <String, Object?>{'uri': uri};

    // Determine strategy from URI by matching prefix
    final strategy = _getStrategyFromUri(uri);
    if (strategy == null) {
      throw StateError('Invalid or unsupported resource URI: $uri');
    }

    final strategyResult = strategy.read(params);

    // Convert strategy result to ReadResourceResult
    final content = strategyResult['content'] as String?;
    final mimeType = strategyResult['mimeType'] as String?;

    if (content == null) {
      throw StateError('Resource content is null');
    }

    // Strategies return text content, so use TextResourceContents
    // If encoding is base64, the content string would already be decoded
    final resourceContents = TextResourceContents(
      uri: uri,
      text: content,
      mimeType: mimeType ?? _guessMimeType(uri),
    );

    return ReadResourceResult(contents: [resourceContents]);
  }

  /// Guess MIME type from URI extension
  String? _guessMimeType(String uri) {
    if (uri.contains('.')) {
      final ext = uri.split('.').last.toLowerCase();
      switch (ext) {
        case 'dart':
          return 'text/x-dart';
        case 'md':
          return 'text/markdown';
        case 'json':
          return 'application/json';
        case 'yaml':
        case 'yml':
          return 'text/yaml';
        case 'txt':
          return 'text/plain';
        default:
          return 'text/plain';
      }
    }
    return 'text/plain';
  }

  /// Get log provider from log strategies (for tools that need to store logs)
  /// 
  /// Returns the LogResourceProvider from any strategy that has a logProvider
  /// getter, or null if not found. Uses dynamic property access to avoid
  /// depending on specific strategy types.
  LogResourceProvider? get logProvider {
    for (final strategy in _strategies) {
      // Use dynamic access to check for logProvider property
      // This allows any strategy with a logProvider getter to be used
      final dynamic strategyDynamic = strategy;
      try {
        final provider = strategyDynamic.logProvider;
        if (provider is LogResourceProvider) {
          return provider;
        }
      } catch (_) {
        // Strategy doesn't have logProvider property, continue
      }
    }
    return null;
  }
}

