import 'package:fly_mcp_server/src/cancellation.dart';
import 'package:fly_mcp_server/src/progress.dart';
import 'package:fly_mcp_server/src/registries/registry.dart';

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

/// Definition of an MCP tool
/// 
/// Contains all metadata about a tool including its name, description,
/// parameter and result schemas, and the handler function.
/// 
/// Example:
/// ```dart
/// ToolDefinition(
///   name: 'example.tool',
///   description: 'Example tool',
///   paramsSchema: {'type': 'object'},
///   handler: (params, {cancelToken, progressNotifier}) async {
///     return {'result': 'success'};
///   },
/// )
/// ```
class ToolDefinition {
  /// Creates a tool definition
  /// 
  /// [name] - Tool name (e.g., 'example.tool')
  /// [description] - Human-readable description
  /// [handler] - Function that executes the tool
  /// [paramsSchema] - JSON schema for validating input parameters
  /// [resultSchema] - JSON schema for validating output results
  /// [readOnly] - Whether the tool only reads data (does not modify state)
  /// [writesToDisk] - Whether the tool writes to the file system
  /// [requiresConfirmation] - Whether the tool requires explicit confirmation
  /// [idempotent] - Whether the tool can be safely called multiple times
  const ToolDefinition({
    required this.name,
    required this.description,
    required this.handler,
    this.paramsSchema,
    this.resultSchema,
    this.readOnly = false,
    this.writesToDisk = false,
    this.requiresConfirmation = false,
    this.idempotent = false,
  });

  /// Tool name as it appears in MCP protocol
  final String name;

  /// Human-readable description of the tool
  final String description;

  /// JSON schema for validating input parameters
  final Map<String, Object?>? paramsSchema;

  /// JSON schema for validating output results
  final Map<String, Object?>? resultSchema;

  /// Function that executes the tool
  final ToolHandler handler;

  /// Whether the tool only reads data (does not modify state)
  final bool readOnly;

  /// Whether the tool writes to the file system
  final bool writesToDisk;

  /// Whether the tool requires explicit confirmation before execution
  final bool requiresConfirmation;

  /// Whether the tool can be safely called multiple times with same result
  final bool idempotent;
}

/// Registry for MCP tools
/// 
/// Maintains a collection of tool definitions and provides methods
/// to register, list, and call tools. Tools are identified by their name.
/// 
/// Example:
/// ```dart
/// final registry = ToolRegistry();
/// registry.register(ToolDefinition(...));
/// final tools = registry.list();
/// final result = await registry.call('tool.name', {...});
/// ```
class ToolRegistry implements IToolRegistry {
  final Map<String, ToolDefinition> _tools = {};

  /// Registers a tool definition
  /// 
  /// If a tool with the same name already exists, it will be overwritten.
  /// 
  /// [tool] - The tool definition to register
  @override
  void register(ToolDefinition tool) {
    _tools[tool.name] = tool;
  }

  /// Lists all registered tools
  /// 
  /// Returns a list of tool metadata maps suitable for JSON-RPC responses.
  /// Each map includes name, description, schemas, and safety metadata.
  /// 
  /// Returns a list of tool metadata maps
  @override
  List<Map<String, Object?>> list() {
    return _tools.values
        .map((t) => {
              'name': t.name,
              'description': t.description,
              if (t.paramsSchema != null) 'inputSchema': t.paramsSchema,
              if (t.resultSchema != null) 'resultSchema': t.resultSchema,
              // Include safety metadata
              if (t.readOnly) 'readOnly': true,
              if (t.writesToDisk) 'writesToDisk': true,
              if (t.requiresConfirmation) 'requiresConfirmation': true,
              if (t.idempotent) 'idempotent': true,
            })
        .toList();
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
    final tool = _tools[name];
    if (tool == null) {
      throw StateError('Unknown tool: $name');
    }
    return tool.handler(
      params,
      cancelToken: cancelToken,
      progressNotifier: progressNotifier,
    );
  }

  /// Gets a tool definition by name
  /// 
  /// [name] - The name of the tool to retrieve
  /// 
  /// Returns the tool definition, or null if not found.
  @override
  ToolDefinition? getTool(String name) => _tools[name];
}

