import 'package:dart_mcp/server.dart';
import 'package:fly_mcp_server/src/cancellation.dart';
import 'package:fly_mcp_server/src/progress.dart';

/// Handler function for tool execution
/// 
/// [params] - Tool parameters extracted from the request
/// [cancelToken] - Cancellation token to check for cancellation requests
/// [progressNotifier] - Progress notifier for sending progress updates
/// 
/// Returns the tool execution result, typically a Map with the results.
typedef ToolHandler = Future<Object?> Function(
  Map<String, Object?> params, {
  CancellationToken? cancelToken,
  ProgressNotifier? progressNotifier,
});

/// Helper function to create a [Tool] from individual parameters
/// 
/// This provides a convenient way to create [Tool] objects similar to
/// how ToolDefinition was previously used. The [Tool] type is from
/// `dart_mcp/src/api/tools.dart`.
/// 
/// Example:
/// ```dart
/// final tool = createTool(
///   name: 'example.tool',
///   description: 'Example tool',
///   inputSchema: ObjectSchema(),
/// );
/// final handler = (params, {cancelToken, progressNotifier}) async {
///   return {'result': 'success'};
/// };
/// registry.register(tool, handler);
/// ```
Tool createTool({
  required String name,
  required String description,
  ObjectSchema? inputSchema,
  ObjectSchema? outputSchema,
  bool readOnly = false,
  bool writesToDisk = false,
  bool requiresConfirmation = false,
  bool idempotent = false,
}) {
  // Convert input schema
  final toolInputSchema = inputSchema ?? ObjectSchema();

  // Create annotations from tool metadata
  ToolAnnotations? annotations;
  if (readOnly || writesToDisk || requiresConfirmation || idempotent) {
    annotations = ToolAnnotations(
      readOnlyHint: readOnly ? true : null,
      destructiveHint: writesToDisk ? true : null,
      idempotentHint: idempotent ? true : null,
    );
  }

  return Tool(
    name: name,
    description: description,
    inputSchema: toolInputSchema,
    outputSchema: outputSchema,
    annotations: annotations,
  );
}

/// Base interfaces and abstractions for registries
///
/// These interfaces define the contract for MCP protocol registries.
/// Types such as [Resource], [ListResourcesResult], and [ReadResourceResult]
/// are from `dart_mcp/src/api/resources.dart`.

/// Interface for tool registries
///
/// Handles registration and execution of MCP tools. The [list] method returns
/// [Tool] objects from `dart_mcp/src/api/tools.dart` representing MCP protocol tools.
abstract class IToolRegistry {
  /// Registers a tool with its handler
  ///
  /// If a tool with the same name already exists, it will be overwritten.
  ///
  /// [tool] - The [Tool] object from `dart_mcp/src/api/tools.dart` to register
  /// [handler] - The handler function that executes the tool
  /// [requiresConfirmation] - Whether this tool requires explicit confirmation (default: false)
  void register(
    Tool tool,
    ToolHandler handler, {
    bool requiresConfirmation = false,
  });
  
  /// Lists all registered tools
  ///
  /// Returns a list of [Tool] objects from `dart_mcp/src/api/tools.dart`
  /// representing MCP protocol tools.
  ///
  /// Returns a list of [Tool] objects
  List<Tool> list();

  /// Calls a registered tool by name
  ///
  /// [name] - The name of the tool to call
  /// [params] - Parameters to pass to the tool handler
  /// [cancelToken] - Optional cancellation token for cancellation support
  /// [progressNotifier] - Optional progress notifier for progress updates
  ///
  /// Returns the result from the tool handler.
  ///
  /// Throws [StateError] if the tool is not found.
  Future<Object?> call(
      String name,
      Map<String, Object?> params, {
        CancellationToken? cancelToken,
        ProgressNotifier? progressNotifier,
      });
  /// Gets a tool by name
  ///
  /// [name] - The name of the tool to retrieve
  ///
  /// Returns the [Tool] object from `dart_mcp/src/api/tools.dart`, or null if not found.
  Tool? getTool(String name);
}

/// Registry for MCP tools
/// 
/// Maintains a collection of [Tool] objects from `dart_mcp/src/api/tools.dart`
/// and their associated handlers. Provides methods to register, list, and call tools.
/// Tools are identified by their name.
/// 
/// Example:
/// ```dart
/// final registry = ToolRegistry();
/// final tool = createTool(
///   name: 'example.tool',
///   description: 'Example tool',
///   inputSchema: ObjectSchema(),
/// );
/// final handler = (params, {cancelToken, progressNotifier}) async {
///   return {'result': 'success'};
/// };
/// registry.register(tool, handler);
/// final tools = registry.list();
/// final result = await registry.call('example.tool', {...});
/// ```
/// Metadata about a tool that's not part of the MCP Tool type
class ToolMetadata {
  const ToolMetadata({this.requiresConfirmation = false});
  
  /// Whether this tool requires explicit confirmation before execution
  final bool requiresConfirmation;
}

class ToolRegistry implements IToolRegistry {
  final Map<String, Tool> _tools = {};
  final Map<String, ToolHandler> _handlers = {};
  final Map<String, ToolMetadata> _metadata = {};

  /// Registers a tool with its handler
  /// 
  /// If a tool with the same name already exists, it will be overwritten.
  /// 
  /// [tool] - The [Tool] object from `dart_mcp/src/api/tools.dart` to register
  /// [handler] - The handler function that executes the tool
  /// [requiresConfirmation] - Whether this tool requires explicit confirmation (default: false)
  @override
  void register(
    Tool tool,
    ToolHandler handler, {
    bool requiresConfirmation = false,
  }) {
    _tools[tool.name] = tool;
    _handlers[tool.name] = handler;
    _metadata[tool.name] = ToolMetadata(
      requiresConfirmation: requiresConfirmation,
    );
  }

  /// Gets metadata for a tool by name
  ToolMetadata? getMetadata(String name) => _metadata[name];

  /// Lists all registered tools
  /// 
  /// Returns a list of [Tool] objects from `dart_mcp/src/api/tools.dart`
  /// representing MCP protocol tools.
  /// 
  /// Returns a list of [Tool] objects
  @override
  List<Tool> list() {
    return _tools.values.toList();
  }

  /// Calls a registered tool by name
  /// 
  /// [name] - The name of the tool to call
  /// [params] - Parameters to pass to the tool handler
  /// [cancelToken] - Optional cancellation token for cancellation support
  /// [progressNotifier] - Optional progress notifier for progress updates
  /// 
  /// Returns the result from the tool handler.
  /// 
  /// Throws [StateError] if the tool is not found.
  @override
  Future<Object?> call(
    String name,
    Map<String, Object?> params, {
    CancellationToken? cancelToken,
    ProgressNotifier? progressNotifier,
  }) async {
    final handler = _handlers[name];
    if (handler == null) {
      throw StateError('Unknown tool: $name');
    }
    return handler(
      params,
      cancelToken: cancelToken,
      progressNotifier: progressNotifier,
    );
  }

  /// Gets a tool by name
  /// 
  /// [name] - The name of the tool to retrieve
  /// 
  /// Returns the [Tool] object from `dart_mcp/src/api/tools.dart`, or null if not found.
  @override
  Tool? getTool(String name) => _tools[name];
}

