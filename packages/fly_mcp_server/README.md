# Fly MCP Server

A robust, type-safe, and extensible Model Context Protocol (MCP) server implementation for Dart/Flutter, built on the official `dart_mcp` package with advanced features.

## Overview

Fly MCP Server provides a production-ready implementation of the MCP protocol with:

- **dart_mcp Integration**: Built on the official `dart_mcp` package with mixin-based capabilities
- **Type Safety**: Comprehensive type-safe models for all MCP protocol types
- **Error Handling**: Unified error hierarchy with automatic JSON-RPC error conversion
- **Configuration**: Flexible configuration system with validation
- **Builder Pattern**: Fluent API for server setup
- **Resource Management**: Support for workspace files, logs, and custom resources
- **Progress Tracking**: Built-in progress notification support via dart_mcp
- **Cancellation**: Request cancellation support
- **Concurrency Control**: Per-tool and global concurrency limits
- **Timeout Management**: Configurable timeouts with per-tool overrides
- **Size Validation**: Request/response size limits for security
- **Security**: Path sandboxing for resource access

## Architecture

The server extends `MCPServer` from `dart_mcp` and uses mixins for capabilities:

```
MCPServer (from dart_mcp)
    ↓
McpServer (extends MCPServer)
    ↓
with ToolsSupport, ResourcesSupport, PromptsSupport (mixins)
```

This architecture provides:
- **Official Protocol Support**: Uses the official dart_mcp package ensuring protocol compliance
- **Mixin-based Capabilities**: Clean separation of concerns via mixins
- **Extensibility**: Easy to add new tools, resources, and prompts via registries
- **Type Safety**: Full type safety for all MCP protocol types
- **Testability**: Registries and handlers can be tested independently

## Quick Start

### Basic Setup

```dart
import 'package:fly_mcp_server/fly_mcp_server.dart';

void main() async {
  // Create registries
  final tools = ToolRegistry();
  
  // Create resource strategies (users must implement their own ResourceStrategy)
  // This package provides only abstractions - concrete implementations should
  // be in your application layer. See your application code for example implementations.
  final resources = ResourceRegistry(
    strategies: [
      // Add your custom ResourceStrategy implementations here
      // Example: MyCustomResourceStrategy()
    ],
  );
  final prompts = PromptRegistry();

  // Register tools
  tools.register(ToolDefinition(
    name: 'example.echo',
    description: 'Echo back the input',
    paramsSchema: {
      'type': 'object',
      'properties': {
        'message': {'type': 'string'},
      },
      'required': ['message'],
    },
    handler: (params, {cancelToken, progressNotifier}) async {
      final message = params['message'] as String? ?? '';
      return {'echo': message};
    },
  ));

  // Create server
  final server = McpServer.stdio(
    toolRegistry: tools,
    resourceRegistry: resources,
    promptRegistry: prompts,
  );

  // Serve requests
  await server.serve();
}
```

### Using the Builder Pattern

```dart
import 'package:fly_mcp_server/fly_mcp_server.dart';

void main() async {
  final server = McpServerBuilder()
      .withToolRegistry(tools)
      .withResourceRegistry(resources)
      .withDefaultTimeout(Duration(minutes: 10))
      .withMaxConcurrency(5)
      .withConfig(ServerConfig.defaultConfig())
      .build();

  await server.serve();
}
```

### Using Configuration

```dart
import 'package:fly_mcp_server/fly_mcp_server.dart';

void main() async {
  final config = ServerConfig(
    defaultTimeout: Duration(minutes: 5),
    concurrency: ConcurrencyConfig(
      maxConcurrency: 10,
      perToolLimits: {'heavy.tool': 2},
    ),
    timeouts: TimeoutConfig(
      defaultTimeout: Duration(minutes: 5),
      perToolTimeouts: {'heavy.tool': Duration(minutes: 30)},
    ),
    logging: LoggingConfig(
      enabled: true,
      level: LogLevel.info,
    ),
  );

  config.validate(); // Validate configuration

  final server = McpServerBuilder()
      .withConfig(config)
      .withToolRegistry(tools)
      .build();

  await server.serve();
}
```

## Features

### Tools

Tools are registered via `ToolRegistry` and automatically exposed via the `ToolsSupport` mixin:

```dart
tools.register(ToolDefinition(
  name: 'my.tool',
  description: 'Tool description',
  paramsSchema: {
    'type': 'object',
    'properties': {
      'param1': {'type': 'string'},
    },
    'required': ['param1'],
  },
  readOnly: false,
  writesToDisk: true,
  requiresConfirmation: true,
  idempotent: false,
  handler: (params, {cancelToken, progressNotifier}) async {
    // Tool implementation
    return {'result': 'success'};
  },
));
```

### Resources

Resources are registered via resource templates and handled through the `ResourcesSupport` mixin. The server automatically registers:

- `workspace://*` - Workspace files and directories
- `logs://run/*` - Execution logs from process runs
- `logs://build/*` - Build logs from compilation processes

### Prompts

Prompts are registered via `PromptRegistry` and exposed through the `PromptsSupport` mixin.

### Error Handling

The server provides a unified error hierarchy:

```dart
try {
  // Server operations
} on ToolNotFoundError catch (e) {
  // Handle tool not found
} on TimeoutError catch (e) {
  // Handle timeout
} on ValidationError catch (e) {
  // Handle validation errors
}
```

All errors are automatically handled by dart_mcp's error system.

### Progress Notifications

Tools can send progress updates using the progress notifier:

```dart
handler: (params, {cancelToken, progressNotifier}) async {
  await progressNotifier?.notify(
    message: 'Processing step 1...',
    percent: 25,
  );

  await progressNotifier?.notify(
    message: 'Processing step 2...',
    percent: 50,
  );

  await progressNotifier?.notify(
    message: 'Complete',
    percent: 100,
  );

  return {'done': true};
},
```

Progress notifications are automatically sent via dart_mcp's progress notification system when a progress token is present in the request.

### Cancellation

Tools should respect cancellation tokens:

```dart
handler: (params, {cancelToken, progressNotifier}) async {
  // Periodically check for cancellation
  cancelToken?.throwIfCancelled();

  // Long-running operation
  for (var i = 0; i < 100; i++) {
    // Check cancellation in loop
    cancelToken?.throwIfCancelled();

    // Do work
    await Future.delayed(Duration(milliseconds: 100));
  }

  return {'done': true};
},
```

## API Reference

### McpServer

Main server class that extends `MCPServer` from `dart_mcp`.

**Constructors:**
```dart
McpServer.stdio({
  required ToolRegistry toolRegistry,
  ResourceRegistry? resourceRegistry,
  PromptRegistry? promptRegistry,
  Duration? defaultTimeout,
  int? maxConcurrency,
  Map<String, int>? perToolConcurrency,
  Map<String, Duration>? perToolTimeouts,
  SecurityConfig? securityConfig,
  LoggingConfig? loggingConfig,
  SizeLimitsConfig? sizeLimitsConfig,
  String? workspaceRoot,
})
```

or

```dart
factory McpServer.fromConfig({
  required ToolRegistry toolRegistry,
  ServerConfig? config,
  ResourceRegistry? resourceRegistry,
  PromptRegistry? promptRegistry,
  String? workspaceRoot,
})
```

**Methods:**
- `Future<void> serve()` - Serve requests over stdio transport
- `factory McpServer.fromConfig(...)` - Create server from ServerConfig

### McpServerBuilder

Builder pattern for creating server instances.

**Methods:**
- `withToolRegistry(ToolRegistry registry)` - Set tool registry
- `withResourceRegistry(ResourceRegistry registry)` - Set resource registry
- `withPromptRegistry(PromptRegistry registry)` - Set prompt registry
- `withDefaultTimeout(Duration timeout)` - Set default timeout
- `withMaxConcurrency(int maxConcurrency)` - Set max concurrency
- `withPerToolConcurrency(Map<String, int> limits)` - Set per-tool limits
- `withPerToolTimeouts(Map<String, Duration> timeouts)` - Set per-tool timeouts
- `withConfig(ServerConfig config)` - Set configuration
- `withWorkspaceRoot(String workspaceRoot)` - Set workspace root
- `withLoggingConfig(LoggingConfig config)` - Set logging configuration
- `build()` - Build server instance

### ServerConfig

Configuration class for server settings.

**Properties:**
- `Duration defaultTimeout` - Default operation timeout
- `ConcurrencyConfig concurrency` - Concurrency settings
- `TimeoutConfig timeouts` - Timeout settings
- `SecurityConfig? security` - Security settings
- `LoggingConfig? logging` - Logging settings
- `SizeLimitsConfig? sizeLimits` - Size limit settings

**Methods:**
- `factory ServerConfig.defaultConfig()` - Create default configuration
- `validate()` - Validate configuration
- `copyWith(...)` - Create modified copy

## Extending the Server

### Adding a New Tool

Simply register it in the `ToolRegistry`:

```dart
tools.register(ToolDefinition(
  name: 'my.new.tool',
  description: 'Description',
  handler: (params, {cancelToken, progressNotifier}) async {
    // Implementation
    return {'result': 'success'};
  },
));
```

### Adding a New Resource Type

1. Create a resource strategy class extending `ResourceStrategy`:
```dart
class MyResourceStrategy extends ResourceStrategy {
  @override
  String get uriPrefix => 'my://';

  @override
  String get description => 'My resource type';

  @override
  Map<String, Object?> list(Map<String, Object?> params) {
    // Implementation
  }

  @override
  Map<String, Object?> read(Map<String, Object?> params) {
    // Implementation
  }
}
```

2. Create your own ResourceStrategy implementations and pass them to ResourceRegistry
3. The server will automatically handle it via resource templates

### Adding a New Prompt Type

1. Create a prompt strategy class extending `PromptStrategy`:
```dart
class MyPromptStrategy extends PromptStrategy {
  @override
  String get id => 'my.prompt';

  @override
  String get title => 'My Prompt';

  @override
  String get description => 'Description';

  @override
  List<Map<String, Object?>> getVariables() {
    // Return variable definitions
  }

  @override
  Map<String, Object?> getPrompt(Map<String, Object?> params) {
    // Return prompt content
  }
}
```

2. Register it in your `PromptStrategyRegistry` implementation (in fly_cli)
3. The server will automatically expose it via the `PromptsSupport` mixin

Note: The concrete prompt strategy implementations should be in your application layer (e.g., fly_cli), not in fly_mcp_server. Use `setPromptStrategyRegistryProvider()` to connect your strategies to the MCP server.

## Error Handling

The server automatically converts exceptions to appropriate error responses:

- `ToolNotFoundError` → Error response in `CallToolResult`
- `ResourceNotFoundError` → Error response in `ReadResourceResult`
- `TimeoutError` → Error response with timeout information
- `CancellationError` → Error response indicating cancellation
- `ConcurrencyLimitError` → Error response with concurrency information
- `ValidationError` → Error response with validation details

All errors are handled through dart_mcp's error system and returned as error results rather than protocol-level errors when appropriate.

## Dependencies

- `dart_mcp: ^0.3.3` - Official MCP package for Dart
- All JSON-RPC handling, protocol compliance, and transport are provided by `dart_mcp`

## License

This package is part of the Fly project.
