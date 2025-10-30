import 'package:dart_mcp/server.dart';
import 'package:fly_mcp_server/src/cancellation.dart';
import 'package:fly_mcp_server/src/progress.dart';
import 'package:fly_mcp_server/src/registries/tool_registry.dart';



/// Interface for resource registries
/// 
/// Handles listing and reading MCP resources. The [list] method returns
/// [ListResourcesResult] which contains a list of [Resource] objects from
/// `dart_mcp/src/api/resources.dart`. The [read] method returns
/// [ReadResourceResult] which contains [ResourceContents].
abstract class IResourceRegistry {
  /// List available resources
  /// 
  /// Returns [ListResourcesResult] containing [Resource] objects that represent
  /// available MCP protocol resources.
  ListResourcesResult list(ListResourcesRequest request);

  /// Read a resource by URI
  /// 
  /// Returns [ReadResourceResult] containing [ResourceContents] (either
  /// [TextResourceContents] or [BlobResourceContents]) from the MCP protocol.
  ReadResourceResult read(ReadResourceRequest request);
}

/// Interface for prompt registries
/// 
/// Handles listing and retrieving MCP prompts.
abstract class IPromptRegistry {
  List<Prompt> list();
  Future<GetPromptResult> getPrompt(Map<String, Object?> params);
}

