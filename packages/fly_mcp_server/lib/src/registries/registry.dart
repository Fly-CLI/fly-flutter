import 'package:fly_mcp_server/src/cancellation.dart';
import 'package:fly_mcp_server/src/progress.dart';
import 'package:fly_mcp_server/src/registries/tool_registry.dart';

/// Base interfaces and abstractions for registries

/// Interface for tool registries
abstract class IToolRegistry {
  void register(ToolDefinition tool);
  List<Map<String, Object?>> list();
  Future<Object?> call(
    String name,
    Map<String, Object?> params, {
    CancellationToken? cancelToken,
    ProgressNotifier? progressNotifier,
  });
  ToolDefinition? getTool(String name);
}

/// Interface for resource registries
abstract class IResourceRegistry {
  Map<String, Object?> list(Map<String, Object?> params);
  Map<String, Object?> read(Map<String, Object?> params);
}

/// Interface for prompt registries
abstract class IPromptRegistry {
  List<Map<String, Object?>> list();
  Map<String, Object?> getPrompt(Map<String, Object?> params);
}

