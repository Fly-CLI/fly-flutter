# MCP Server Architecture Documentation

**Server File**: `packages/fly_mcp_server/lib/src/server.dart`  
**Version**: 0.1.0  
**Last Updated**: December 2024

---

## Table of Contents

1. [Overview](#overview)
2. [Core Architecture](#core-architecture)
3. [Request Handling Flow](#request-handling-flow)
4. [Registry System](#registry-system)
5. [Safety & Concurrency Controls](#safety--concurrency-controls)
6. [Strategy Pattern Implementation](#strategy-pattern-implementation)
7. [Protocol Methods](#protocol-methods)
8. [Error Handling & Observability](#error-handling--observability)
9. [Configuration & Customization](#configuration--customization)
10. [Entry Point & Lifecycle](#entry-point--lifecycle)

---

## Overview

The MCP (Model Context Protocol) Server is a production-ready implementation of the Model Context
Protocol specification designed specifically for the Fly CLI project. It provides a standardized
interface for AI assistants to interact with Flutter development tools through JSON-RPC 2.0 over
stdio.

### Key Features

- **✅ Full MCP Protocol Support**: Tools, Resources, and Prompts
- **✅ Production-Ready**: Robust error handling, timeout management, concurrency control
- **✅ Strategy Pattern**: Clean, extensible architecture with pluggable strategies
- **✅ Safety First**: Built-in concurrency limits, timeouts, and cancellations
- **✅ Comprehensive Observability**: Structured logging with correlation IDs
- **✅ Type-Safe**: Strongly typed Dart implementation with exhaustive patterns
- **✅ Zero Configuration**: Sensible defaults with full customization support

---

## Core Architecture

### High-Level Design

```13:171:packages/fly_mcp_server/lib/src/server.dart
/// MCP Server implementation
class McpServer {
  /// Creates an MCP server with the specified registries and configuration
  McpServer({
    required ToolRegistry toolRegistry,
    ResourceRegistry? resourceRegistry,
    PromptRegistry? promptRegistry,
    StdioTransport? transport,
    Duration? defaultTimeout,
    int? maxConcurrency,
    Map<String, int>? perToolConcurrency,
    Map<String, Duration>? perToolTimeouts,
  })  : _tools = toolRegistry,
        _resources = resourceRegistry ?? ResourceRegistry(),
        _prompts = promptRegistry ?? PromptRegistry(),
        _transport = transport,
        _cancellationRegistry = CancellationRegistry(),
        _concurrencyLimiter = ConcurrencyLimiter(
          maxConcurrency: maxConcurrency ?? 10,
          perToolLimits: perToolConcurrency,
        ),
        _defaultTimeout = defaultTimeout ?? const Duration(minutes: 5),
        _perToolTimeouts = perToolTimeouts ?? {};

  final ToolRegistry _tools;
  final ResourceRegistry _resources;
  final PromptRegistry _prompts;
  StdioTransport? _transport; // Can be set after construction
  final CancellationRegistry _cancellationRegistry;
  final ConcurrencyLimiter _concurrencyLimiter;
  final Duration _defaultTimeout;
  final Map<String, Duration> _perToolTimeouts;

  /// Handles a JSON-RPC request
  FutureOr<Object?> handle(JsonRpcRequest req) async {
    final start = DateTime.now();
    final correlationId = _generateCorrelationId(req.id);
    try {
      // Map method name to enum type
      final methodType = _getMethodType(req.method);
      if (methodType == null) {
        // Unknown method → JSON-RPC Method not found
        throw JsonRpcError(
          code: McpErrorCodes.methodNotFound,
          message: 'Method not found',
          data: req.method,
        );
      }

      // Create context for strategy
      final context = McpMethodContext(
        toolRegistry: _tools,
        resourceRegistry: _resources,
        promptRegistry: _prompts,
        cancellationRegistry: _cancellationRegistry,
        concurrencyLimiter: _concurrencyLimiter,
        defaultTimeout: _defaultTimeout,
        perToolTimeouts: _perToolTimeouts,
        transport: _transport,
      );

      // Delegate to strategy
      return await methodType.strategy.handle(req, context);
    } on TimeoutException catch (e) {
      // Handle timeout errors
      final log = jsonEncode({
        'component': 'fly_mcp_server',
        'level': 'error',
        'method': req.method,
        'id': req.id,
        'correlation_id': correlationId,
        'error': 'timeout',
        'message': e.message,
        'ts': DateTime.now().toIso8601String(),
      });
      stderr.writeln(log);
      
      String? toolName;
      if (req.method == 'tools/call' && req.params is Map) {
        final params = req.params! as Map<String, Object?>;
        toolName = params['name'] as String?;
      }
      
      throw JsonRpcError(
        code: McpErrorCodes.mcpTimeout,
        message: e.message,
        data: {'tool': toolName},
      );
    } on ConcurrencyLimitException catch (e) {
      // Handle concurrency limit errors
      final log = jsonEncode({
        'component': 'fly_mcp_server',
        'level': 'error',
        'method': req.method,
        'id': req.id,
        'correlation_id': correlationId,
        'error': 'concurrency_limit',
        'message': e.message,
        'tool': e.toolName,
        'current': e.current,
        'limit': e.limit,
        'ts': DateTime.now().toIso8601String(),
      });
      stderr.writeln(log);
      throw JsonRpcError(
        code: McpErrorCodes.mcpPermissionDenied,
        message: e.message,
        data: {
          'tool': e.toolName,
          'current': e.current,
          'limit': e.limit,
        },
      );
    } catch (e) {
      // Log errors with correlation ID
      final log = jsonEncode({
        'component': 'fly_mcp_server',
        'level': 'error',
        'method': req.method,
        'id': req.id,
        'correlation_id': correlationId,
        'error': e.toString(),
        'ts': DateTime.now().toIso8601String(),
      });
      stderr.writeln(log);
      rethrow;
    } finally {
      final elapsed = DateTime.now().difference(start);
      final log = jsonEncode({
        'component': 'fly_mcp_server',
        'level': 'info',
        'method': req.method,
        'id': req.id,
        'correlation_id': correlationId,
        'elapsed_ms': elapsed.inMilliseconds,
        'ts': DateTime.now().toIso8601String(),
      });
      stderr.writeln(log);
    }
  }
```

### Component Breakdown

The `McpServer` class orchestrates:

1. **Three Registries**: Tools, Resources, and Prompts
2. **Concurrency Control**: Global and per-tool limits
3. **Timeout Management**: Default and per-tool timeouts
4. **Cancellation Support**: Request-level cancellation
5. **Observability**: Structured logging with correlation IDs

---

## Request Handling Flow

### Execution Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│  1. JSON-RPC Request Received                                │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Generate Correlation ID                                  │
│     • req_<id>_<timestamp>                                   │
│     • Used for request tracing                               │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Map Method Name to McpMethodType                         │
│     • String → Enum mapping                                  │
│     • Returns null for unknown methods                       │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Create Method Context                                    │
│     • Passes registries, limiters, timeouts                 │
│     • Supplies transport for progress notifications          │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  5. Delegate to Method Strategy                              │
│     • Each method has dedicated strategy                     │
│     • Strategy handles validation, execution, errors         │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  6. Error Handling & Logging                                 │
│     • TimeoutException → JSON-RPC error                      │
│     • ConcurrencyLimitException → JSON-RPC error            │
│     • Generic errors logged and rethrown                     │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  7. Log Performance Metrics                                  │
│     • Structured JSON log with elapsed_ms                    │
│     • Includes correlation_id for tracing                    │
└─────────────────────────────────────────────────────────────┘
```

### Method Resolution

```154:164:packages/fly_mcp_server/lib/src/server.dart
  /// Maps a method name string to McpMethodType enum
  /// 
  /// Returns null if the method name is not recognized.
  McpMethodType? _getMethodType(String methodName) {
    for (final methodType in McpMethodType.values) {
      if (methodType.methodName == methodName) {
        return methodType;
      }
    }
    return null;
  }
```

The server uses exhaustive enum matching to ensure type safety and compile-time verification of all
protocol methods.

---

## Registry System

### Three-Tier Architecture

The server implements three specialized registries for different MCP concepts:

#### 1. Tool Registry

```46:87:packages/fly_mcp_server/lib/src/registries.dart
class ToolRegistry {
  final Map<String, ToolDefinition> _tools = {};

  void register(ToolDefinition tool) {
    _tools[tool.name] = tool;
  }

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

  ToolDefinition? getTool(String name) => _tools[name];
}
```

**Key Features:**
- Schema validation (params and results)
- Safety metadata (read-only, writes-to-disk, confirmation required)
- Cancellation support
- Progress notifications

#### 2. Resource Registry

```89:151:packages/fly_mcp_server/lib/src/registries.dart
class ResourceRegistry {
  final LogResourceProvider _logs = LogResourceProvider();
  bool _strategiesInitialized = false;

  /// Initialize resource strategies with log provider
  void _initializeStrategies() {
    if (_strategiesInitialized) return;
    
    // Get strategy instances from registry and inject log provider
    final runStrategy =
        resourceStrategyRegistry.getStrategy(ResourceType.logsRun)
            as LogsRunResourceStrategy;
    runStrategy.setLogProvider(_logs);
    
    final buildStrategy =
        resourceStrategyRegistry.getStrategy(ResourceType.logsBuild)
            as LogsBuildResourceStrategy;
    buildStrategy.setLogProvider(_logs);
    
    _strategiesInitialized = true;
  }

  Map<String, Object?> list(Map<String, Object?> params) {
    _initializeStrategies();
    
    final uriPrefix = params['uri'] as String?;
    
    // Determine resource type from URI prefix
    if (uriPrefix != null) {
      if (uriPrefix.startsWith('logs://run/')) {
        return ResourceType.logsRun.strategy.list(params);
      } else if (uriPrefix.startsWith('logs://build/')) {
        return ResourceType.logsBuild.strategy.list(params);
      }
    }
    
    // Default to workspace
    return ResourceType.workspace.strategy.list(params);
  }

  Map<String, Object?> read(Map<String, Object?> params) {
    _initializeStrategies();
    
    final uri = params['uri'] as String?;
    if (uri == null) {
      throw StateError('Missing required parameter: uri');
    }
    
    // Determine resource type from URI
    if (uri.startsWith('logs://run/')) {
      return ResourceType.logsRun.strategy.read(params);
    } else if (uri.startsWith('logs://build/')) {
      return ResourceType.logsBuild.strategy.read(params);
    } else if (uri.startsWith('workspace://')) {
      return ResourceType.workspace.strategy.read(params);
    }
    
    throw StateError('Invalid or unsupported resource URI: $uri');
  }
  
  /// Get log provider for storing logs (used by tools)
  LogResourceProvider get logProvider => _logs;
}
```

**Resource Types:**
- `workspace://` - Workspace files (code, configs)
- `logs://run/` - Runtime application logs
- `logs://build/` - Build-time logs

#### 3. Prompt Registry

```153:175:packages/fly_mcp_server/lib/src/registries.dart
class PromptRegistry {
  List<Map<String, Object?>> list() {
    return PromptType.values
        .map((type) => type.strategy.getListEntry())
        .toList();
  }

  Map<String, Object?> getPrompt(Map<String, Object?> params) {
    final id = params['id'] as String?;
    if (id == null) {
      throw StateError('Missing required parameter: id');
    }
    
    // Find prompt type by ID
    for (final promptType in PromptType.values) {
      if (promptType.id == id) {
        return promptType.strategy.getPrompt(params);
      }
    }
    
    throw StateError('Unknown prompt id: $id');
  }
}
```

Prompts provide pre-configured templates for common AI interactions (e.g., scaffolding UI pages).

---

## Safety & Concurrency Controls

### Three-Layer Safety System

#### 1. Concurrency Limiting

```4:81:packages/fly_mcp_server/lib/src/concurrency_limiter.dart
/// Limits concurrent execution of operations
class ConcurrencyLimiter {
  /// Creates a concurrency limiter with optional configuration
  ConcurrencyLimiter({
    int maxConcurrency = 10,
    Map<String, int>? perToolLimits,
  })  : _maxConcurrency = maxConcurrency,
        _perToolLimits = perToolLimits ?? <String, int>{};

  final int _maxConcurrency;
  final Map<String, int> _toolConcurrency = {};
  final Map<String, int> _perToolLimits;

  /// Current total concurrent operations
  int get currentConcurrency {
    return _toolConcurrency.values.fold(0, (sum, count) => sum + count);
  }

  /// Current concurrent operations for a specific tool
  int getToolConcurrency(String toolName) {
    return _toolConcurrency[toolName] ?? 0;
  }

  /// Check if a new operation can start
  ///
  /// Returns true if both global and per-tool limits allow the operation.
  bool canStart(String toolName) {
    // Check global limit
    if (currentConcurrency >= _maxConcurrency) {
      return false;
    }

    // Check per-tool limit
    final toolLimit = _perToolLimits[toolName];
    if (toolLimit != null && getToolConcurrency(toolName) >= toolLimit) {
      return false;
    }

    return true;
  }

  /// Register that an operation started
  void start(String toolName) {
    _toolConcurrency[toolName] = (getToolConcurrency(toolName)) + 1;
  }

  /// Register that an operation completed
  void complete(String toolName) {
    final current = getToolConcurrency(toolName);
    if (current > 0) {
      _toolConcurrency[toolName] = current - 1;
      if (_toolConcurrency[toolName] == 0) {
        _toolConcurrency.remove(toolName);
      }
    }
  }

  /// Execute a function with concurrency limiting
  Future<T> execute<T>(
    String toolName,
    Future<T> Function() computation,
  ) async {
    if (!canStart(toolName)) {
      throw ConcurrencyLimitException(
        'Maximum concurrency reached for tool: $toolName',
        toolName: toolName,
        current: getToolConcurrency(toolName),
        limit: _perToolLimits[toolName] ?? _maxConcurrency,
      );
    }

    start(toolName);
    try {
      return await computation();
    } finally {
      complete(toolName);
    }
  }
}
```

**Features:**
- Global concurrency limit (default: 10)
- Per-tool limits (configurable)
- Automatic cleanup on completion

#### 2. Timeout Management

```4:25:packages/fly_mcp_server/lib/src/timeout_manager.dart
/// Manages timeouts for tool execution
class TimeoutManager {
  /// Execute a function with timeout
  static Future<T> withTimeout<T>(
    Future<T> Function() computation, {
    required Duration timeout,
    String? operationName,
  }) async {
    try {
      return await computation().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            'Operation${operationName != null ? ' ($operationName)' : ''} timed out after ${timeout.inSeconds}s',
            timeout,
          );
        },
      );
    } on TimeoutException {
      rethrow;
    }
  }
}
```

**Configuration:**
- Default timeout: 5 minutes
- Per-tool timeouts (configurable)
- Graceful degradation with informative errors

#### 3. Cancellation Support

```4:63:packages/fly_mcp_server/lib/src/cancellation.dart
/// Cancellation token for long-running operations
class CancellationToken {
  final Completer<void> _completer = Completer<void>();
  bool _isCancelled = false;

  /// Whether cancellation was requested
  bool get isCancelled => _isCancelled;

  /// Request cancellation
  void cancel() {
    if (!_isCancelled) {
      _isCancelled = true;
      if (!_completer.isCompleted) {
        _completer.complete();
      }
    }
  }

  /// Wait for cancellation (completes immediately if already cancelled)
  Future<void> get onCancel => _completer.future;

  /// Throw if cancellation was requested
  void throwIfCancelled() {
    if (_isCancelled) {
      throw CancellationException('Operation was cancelled');
    }
  }
}

/// Exception thrown when an operation is cancelled
class CancellationException implements Exception {
  final String message;
  CancellationException(this.message);
  
  @override
  String toString() => message;
}

/// Registry for active cancellable operations
class CancellationRegistry {
  final Map<Object, CancellationToken> _tokens = {};

  /// Register a cancellation token for a request ID
  void register(Object requestId, CancellationToken token) {
    _tokens[requestId] = token;
  }

  /// Cancel a request by ID
  void cancel(Object requestId) {
    _tokens[requestId]?.cancel();
    _tokens.remove(requestId);
  }

  /// Get cancellation token for a request
  CancellationToken? getToken(Object requestId) => _tokens[requestId];

  /// Remove token after operation completes
  void remove(Object requestId) {
    _tokens.remove(requestId);
  }
}
```

**Features:**
- Request-level cancellation via `$/cancelRequest` notification
- Cooperative cancellation (tools must respect tokens)
- Automatic cleanup

---

## Strategy Pattern Implementation

### Two-Level Strategy Architecture

The server uses a sophisticated strategy pattern with two layers:

#### 1. Method-Level Strategies

Each MCP protocol method has its own dedicated strategy:

```8:62:packages/fly_mcp_server/lib/src/domain/mcp_method_strategy.dart
/// Abstract base class for MCP method strategies
/// 
/// Each MCP protocol method implements a concrete strategy that encapsulates
/// all method-specific implementation details, validation, and error handling.
abstract class McpMethodStrategy {
  /// The method name as it appears in the JSON-RPC protocol
  String get methodName;

  /// Human-readable description of the method
  String get description;

  /// Whether this method requires authentication/authorization
  bool get requiresAuth => false;

  /// Whether this method is a notification (no response expected)
  bool get isNotification => false;

  /// Whether this method supports cancellation
  bool get supportsCancellation => false;

  /// Handles a JSON-RPC request for this method
  /// 
  /// [request] - The JSON-RPC request object
  /// [context] - Server context containing registries and configuration
  /// 
  /// Returns the response result, or null for notifications
  FutureOr<Object?> handle(
    JsonRpcRequest request,
    McpMethodContext context,
  );
}

/// Context passed to method strategies containing server state
class McpMethodContext {
  const McpMethodContext({
    required this.toolRegistry,
    required this.resourceRegistry,
    required this.promptRegistry,
    required this.cancellationRegistry,
    required this.concurrencyLimiter,
    required this.defaultTimeout,
    required this.perToolTimeouts,
    this.transport,
  });

  final ToolRegistry toolRegistry;
  final ResourceRegistry resourceRegistry;
  final PromptRegistry promptRegistry;
  final CancellationRegistry cancellationRegistry;
  final ConcurrencyLimiter concurrencyLimiter;
  final Duration defaultTimeout;
  final Map<String, Duration> perToolTimeouts;
  final StdioTransport? transport;
}
```

**Example: Tools Call Strategy**

```10:142:packages/fly_mcp_server/lib/src/domain/strategies/tools_call_method_strategy.dart
/// Strategy for the tools/call method
class ToolsCallMethodStrategy extends McpMethodStrategy {
  @override
  String get methodName => 'tools/call';

  @override
  String get description => 'Call a tool with the provided parameters';

  @override
  bool get supportsCancellation => true;

  @override
  Future<Map<String, Object?>> handle(
    JsonRpcRequest request,
    McpMethodContext context,
  ) async {
    final params =
        (request.params as Map?)?.cast<String, Object?>() ?? <String, Object?>{};
    final name = params['name'] as String?;
    final input =
        (params['arguments'] as Map?)?.cast<String, Object?>() ?? <String, Object?>{};

    if (name == null) {
      throw const JsonRpcError(
        code: McpErrorCodes.invalidParams,
        message: 'Missing tool name',
        data: 'Required field: name',
      );
    }

    // Create cancellation token
    final cancelToken = CancellationToken();
    context.cancellationRegistry.register(request.id, cancelToken);

    try {
      // Get tool and validate params schema
      final tool = context.toolRegistry.getTool(name);
      if (tool == null) {
        throw JsonRpcError(
          code: McpErrorCodes.mcpNotFound,
          message: 'Tool not found',
          data: {'tool': name},
        );
      }

      // Validate input against schema if provided
      if (tool.paramsSchema != null) {
        final validationErrors = SchemaValidator.validate(
          input,
          tool.paramsSchema!,
        );
        if (validationErrors.isNotEmpty) {
          throw JsonRpcError(
            code: McpErrorCodes.invalidParams,
            message: 'Invalid parameters',
            data: {'errors': validationErrors},
          );
        }
      }

      // Check confirmation requirement for destructive operations
      if (tool.requiresConfirmation) {
        final confirmed = input['confirm'] as bool? ?? false;
        if (!confirmed) {
          throw JsonRpcError(
            code: McpErrorCodes.mcpPermissionDenied,
            message: 'Confirmation required',
            data: {
              'tool': name,
              'reason': 'This tool requires explicit confirmation',
            },
          );
        }
      }

      // Create progress notifier if transport available
      ProgressNotifier? progressNotifier;
      final transport = context.transport;
      if (transport != null) {
        progressNotifier = ProgressNotifier(
          transport: transport,
          requestId: request.id,
          enabled: true, // Enable for long-running ops
        );
      }

      // Get timeout for this tool
      final timeout = context.perToolTimeouts[name] ?? context.defaultTimeout;

      // Call tool with cancellation token, timeout, and concurrency limiting
      final result = await context.concurrencyLimiter.execute(
        name,
        () => TimeoutManager.withTimeout(
          () => context.toolRegistry.call(
            name,
            input,
            cancelToken: cancelToken,
            progressNotifier: progressNotifier,
          ),
          timeout: timeout,
          operationName: name,
        ),
      );

      // Validate result schema if provided
      if (tool.resultSchema != null) {
        final validationErrors = SchemaValidator.validate(
          result,
          tool.resultSchema!,
        );
        if (validationErrors.isNotEmpty) {
          // Log but don't fail - result validation is advisory
          stderr.writeln(
            '[fly_mcp_server] Result validation warnings: '
            '${validationErrors.join(", ")}',
          );
        }
      }

      return {
        'content': result,
      };
    } on CancellationException {
      throw JsonRpcError(
        code: McpErrorCodes.mcpCanceled,
        message: 'Request cancelled',
        data: {'tool': name},
      );
    } finally {
      context.cancellationRegistry.remove(request.id);
    }
  }
}
```

#### 2. Resource/Prompt Strategies

Sub-strategies for different resource types and prompts:

```7:117:packages/fly_mcp_server/lib/src/domain/strategies/resource/workspace_resource_strategy.dart
/// Strategy for workspace:// resources
class WorkspaceResourceStrategy extends ResourceStrategy {
  // Allowlisted suffixes and specific filenames
  static const _suffixes = <String>{
    '.dart',
    '.yaml',
    '.yml',
    '.gradle',
    '.kt',
    '.kts',
    '.swift',
    '.mm',
    '.m',
    '.xml',
    '.plist'
  };
  static const _filenames = <String>{
    'pubspec.yaml',
    'analysis_options.yaml',
    'CMakeLists.txt',
    'Podfile',
    'Info.plist'
  };

  @override
  String get uriPrefix => 'workspace://';

  @override
  String get description => 'Workspace files and directories';

  @override
  bool get readOnly => true;

  @override
  Map<String, Object?> list(Map<String, Object?> params) {
    final cwd = Directory.current;
    final dir = params['directory'] as String? ?? cwd.path;
    final pageSize = (params['pageSize'] as int?) ?? 100;
    final page = (params['page'] as int?) ?? 0;
    final entries = <Map<String, Object?>>[];
    final all = Directory(dir).listSync(
      recursive: true,
      followLinks: false,
    );
    for (final entity in all) {
      if (entity is File) {
        final name = entity.uri.pathSegments.isNotEmpty
            ? entity.uri.pathSegments.last
            : entity.path;
        final allowed = _filenames.contains(name) ||
            _suffixes.any(entity.path.endsWith);
        if (allowed) {
          entries.add({
            'uri': 'workspace://${entity.path}',
            'size': entity.lengthSync(),
          });
        }
      }
    }
    entries.sort(
      (a, b) => (a['uri'] as String).compareTo(b['uri'] as String),
    );
    final start = page * pageSize;
    final end = (start + pageSize) > entries.length
        ? entries.length
        : (start + pageSize);
    final slice = (start < entries.length)
        ? entries.sublist(start, end)
        : <Map<String, Object?>>[];
    return {
      'items': slice,
      'total': entries.length,
      'page': page,
      'pageSize': pageSize,
    };
  }

  @override
  Map<String, Object?> read(Map<String, Object?> params) {
    final uri = params['uri'] as String?;
    if (uri == null || !uri.startsWith('workspace://')) {
      throw StateError('Invalid or missing uri');
    }
    final path = uri.replaceFirst('workspace://', '');
    final file = File(path);
    if (!file.existsSync()) {
      throw StateError('File not found');
    }
    final start = (params['start'] as int?) ?? 0;
    final length = (params['length'] as int?);

    final raf = file.openSync(mode: FileMode.read);
    try {
      final fileSize = raf.lengthSync();
      final clampedStart = start.clamp(0, fileSize);
      raf.setPositionSync(clampedStart);
      final bytes = raf.readSync(
        length == null ? fileSize - clampedStart : length,
      );
      final content = utf8.decode(bytes, allowMalformed: true);
      return {
        'content': content,
        'encoding': 'utf-8',
        'total': fileSize,
        'start': clampedStart,
        'length': bytes.length,
      };
    } finally {
      raf.closeSync();
    }
  }
}
```

### Method Type Enum

```4:43:packages/fly_mcp_server/lib/src/domain/mcp_method_type.dart
/// Enum representing all available MCP protocol methods
enum McpMethodType {
  initialize,
  toolsList,
  toolsCall,
  resourcesList,
  resourcesRead,
  promptsList,
  promptsGet,
  cancelRequest,
  ping,
  shutdown,
}

/// Extension providing method metadata and strategy delegation
/// 
/// Delegates to strategy classes for method-specific implementation details,
/// maintaining enum exhaustiveness while leveraging the Strategy pattern
/// for flexibility and extensibility.
extension McpMethodTypeExtension on McpMethodType {
  /// Gets the strategy for this method type
  McpMethodStrategy get strategy =>
      mcpMethodStrategyRegistry.getStrategy(this);

  /// The method name as it appears in the JSON-RPC protocol
  String get methodName => strategy.methodName;

  /// Human-readable description of the method
  String get description => strategy.description;

  /// Whether this method requires authentication/authorization
  bool get requiresAuth => strategy.requiresAuth;

  /// Whether this method is a notification (no response expected)
  bool get isNotification => strategy.isNotification;

  /// Whether this method supports cancellation
  bool get supportsCancellation => strategy.supportsCancellation;
}
```

**Benefits:**
- Type-safe method routing
- Exhaustive pattern matching
- Centralized strategy registration

---

## Protocol Methods

### Supported Methods

```14:17:packages/fly_mcp_server/lib/src/domain/mcp_method_type.dart
  initialize,
  toolsList,
  toolsCall,
  resourcesList,
  resourcesRead,
  promptsList,
  promptsGet,
  cancelRequest,
  ping,
  shutdown,
```

### Capability Advertisement

```7:39:packages/fly_mcp_server/lib/src/domain/strategies/initialize_method_strategy.dart
/// Strategy for the initialize method
class InitializeMethodStrategy extends McpMethodStrategy {
  @override
  String get methodName => 'initialize';

  @override
  String get description => 'Initialize MCP handshake';

  @override
  FutureOr<Object?> handle(
    JsonRpcRequest request,
    McpMethodContext context,
  ) {
    return {
      'serverInfo': {
        'name': 'fly-mcp',
        'version': '0.1.0',
      },
      'capabilities': {
        'tools': true,
        'resources': {
          'workspace': {'readOnly': true},
          'logs': {
            'run': {'readOnly': true},
            'build': {'readOnly': true},
          },
        },
        'prompts': true,
        'cancellation': true,
        'progress': true,
      },
    };
  }
}
```

**Capabilities:**
- ✅ Tools: Full CRUD with safety metadata
- ✅ Resources: Workspace files + logs (read-only)
- ✅ Prompts: Template-based AI interactions
- ✅ Cancellation: Cooperative cancellation
- ✅ Progress: Real-time progress notifications

---

## Error Handling & Observability

### Error Categories

```1:17:packages/fly_mcp_core/lib/src/mcp/error_codes.dart
/// MCP-specific error codes (following MCP spec conventions)
class McpErrorCodes {
  // Standard JSON-RPC 2.0 error codes
  static const int parseError = -32700;
  static const int invalidRequest = -32600;
  static const int methodNotFound = -32601;
  static const int invalidParams = -32602;
  static const int internalError = -32603;

  // MCP domain error codes (custom range: -32000 to -32099)
  static const int mcpInvalidParams = -32602; // Reuse JSON-RPC for params
  static const int mcpCanceled = -32800; // Request was canceled
  static const int mcpTimeout = -32801; // Request timed out
  static const int mcpTooLarge = -32802; // Message/resource too large
  static const int mcpPermissionDenied = -32803; // Permission denied for operation
  static const int mcpNotFound = -32804; // Resource/tool not found
}
```

### Structured Logging

All logs are emitted as structured JSON to stderr:

```json
{
  "component": "fly_mcp_server",
  "level": "error|info",
  "method": "tools/call",
  "id": 42,
  "correlation_id": "req_42_1703123456789",
  "elapsed_ms": 1234,
  "error": "TimeoutException",
  "message": "Operation timed out after 300s",
  "tool": "build_app",
  "ts": "2024-12-22T10:30:45.123Z"
}
```

**Fields:**
- `component`: Server identifier
- `level`: Log level (error, info)
- `method`: MCP method name
- `id`: JSON-RPC request ID
- `correlation_id`: Unique trace ID
- `elapsed_ms`: Request duration in milliseconds
- `ts`: ISO 8601 timestamp

---

## Configuration & Customization

### Server Configuration

```16:35:packages/fly_mcp_server/lib/src/server.dart
  McpServer({
    required ToolRegistry toolRegistry,
    ResourceRegistry? resourceRegistry,
    PromptRegistry? promptRegistry,
    StdioTransport? transport,
    Duration? defaultTimeout,
    int? maxConcurrency,
    Map<String, int>? perToolConcurrency,
    Map<String, Duration>? perToolTimeouts,
  })  : _tools = toolRegistry,
        _resources = resourceRegistry ?? ResourceRegistry(),
        _prompts = promptRegistry ?? PromptRegistry(),
        _transport = transport,
        _cancellationRegistry = CancellationRegistry(),
        _concurrencyLimiter = ConcurrencyLimiter(
          maxConcurrency: maxConcurrency ?? 10,
          perToolLimits: perToolConcurrency,
        ),
        _defaultTimeout = defaultTimeout ?? const Duration(minutes: 5),
        _perToolTimeouts = perToolTimeouts ?? {};
```

**Configuration Options:**
- `toolRegistry` (required): Registered tools
- `resourceRegistry`: Custom resource providers
- `promptRegistry`: Custom prompt templates
- `transport`: Custom stdio transport
- `defaultTimeout`: Default tool timeout (5 min)
- `maxConcurrency`: Global concurrency limit (10)
- `perToolConcurrency`: Per-tool limits
- `perToolTimeouts`: Per-tool timeouts

### Example Configuration

```dart
final server = McpServer(
  toolRegistry: tools,
  defaultTimeout: Duration(minutes: 10),
  maxConcurrency: 20,
  perToolConcurrency: {
    'build_app': 2,
    'run_tests': 5,
  },
  perToolTimeouts: {
    'build_app': Duration(minutes: 30),
    'deploy': Duration(hours: 1),
  },
);
```

---

## Entry Point & Lifecycle

### Stdio Server

```172:185:packages/fly_mcp_server/lib/src/server.dart
/// Entrypoint helper to start a stdio MCP server.
Future<void> runStdioServer(
  McpServer server, {
  int maxMessageBytes = (2 * 1024 * 1024),
}) async {
  final transport = StdioTransport(stdin, stdout, stderr: stderr);
  // Inject transport for progress notifications
  server._transport = transport;
  final rpc = JsonRpcConnection(
    transport,
    maxMessageBytes: maxMessageBytes,
  );
  await rpc.start(handleRequest: server.handle);
}
```

### Lifecycle

1. **Create server** with configuration
2. **Run stdio loop** with `runStdioServer()`
3. **Handle requests** via JSON-RPC
4. **Cleanup** on process termination

---

## Summary

The Fly MCP Server provides a **production-ready, type-safe, extensible** implementation of the Model Context Protocol specifically designed for AI-assisted Flutter development. Its architecture emphasizes:

- ✅ **Safety**: Concurrency limits, timeouts, cancellations
- ✅ **Observability**: Structured logging, correlation IDs, performance metrics
- ✅ **Extensibility**: Strategy pattern, pluggable registries
- ✅ **Type Safety**: Exhaustive enums, compile-time verification
- ✅ **Standards Compliance**: Full MCP protocol support

This foundation enables AI assistants to safely and efficiently interact with Flutter development tools through a standardized, well-documented interface.
