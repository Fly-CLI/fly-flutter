import 'package:fly_mcp_server/fly_mcp_server.dart';
import 'package:fly_mcp_server/src/tool_call/middleware/concurrency_middleware.dart';
import 'package:fly_mcp_server/src/tool_call/middleware/confirmation_middleware.dart';
import 'package:fly_mcp_server/src/tool_call/middleware/error_handling_middleware.dart';
import 'package:fly_mcp_server/src/tool_call/middleware/execution_middleware.dart';
import 'package:fly_mcp_server/src/tool_call/middleware/logging_middleware.dart';
import 'package:fly_mcp_server/src/tool_call/middleware/result_conversion_middleware.dart';
import 'package:fly_mcp_server/src/tool_call/middleware/setup_middleware.dart';
import 'package:fly_mcp_server/src/tool_call/middleware/timeout_middleware.dart';
import 'package:fly_mcp_server/src/tool_call/middleware/validation_middleware.dart';

/// Basic example of creating and running an MCP server
/// 
/// Note: This example shows how to create a server with minimal resources.
/// For concrete resource strategies (workspace, logs, etc.), see your application
/// code (e.g., fly_cli) or create your own ResourceStrategy implementations.
Future<void> main() async {
  // Create registries
  final tools = ToolRegistry();
  
  // Create resource registry with empty strategies list
  // In a real application, you would create your own ResourceStrategy
  // implementations or use concrete ones from your application layer
  final resources = ResourceRegistry(
    strategies: [
      // Add your custom ResourceStrategy implementations here
      // Example: MyCustomResourceStrategy()
    ],
  );
  final prompts = PromptRegistry();

  // Register a simple echo tool
  Future<Map<String, String>> echoHandler(params, {cancelToken, progressNotifier}) async {
    // Check for cancellation
    cancelToken?.throwIfCancelled();

    final message = params['message'] as String? ?? '';
    return {'echo': message};
  }
  final echoTool = createTool(
    name: 'example.echo',
    description: 'Echo back the provided message',
    inputSchema: ObjectSchema(
      properties: {
        'message': Schema.string(),
      },
      required: ['message'],
    ),
    outputSchema: ObjectSchema(
      properties: {
        'echo': Schema.string(),
      },
    ),
    readOnly: true,
    idempotent: true,
  );
  tools.register(echoTool, echoHandler);

  // Register a tool with progress updates
  Future<Map<String, int>> processHandler(params, {cancelToken, progressNotifier}) async {
    final items = (params['items'] as List?)?.cast<String>() ?? [];

    for (var i = 0; i < items.length; i++) {
      cancelToken?.throwIfCancelled();

      await progressNotifier?.notify(
        message: 'Processing item ${i + 1} of ${items.length}',
        percent: ((i + 1) / items.length * 100).round(),
      );

      // Simulate processing
      await Future.delayed(Duration(milliseconds: 100));
    }

    await progressNotifier?.notify(
      message: 'Processing complete',
      percent: 100,
    );

    return {'processed': items.length};
  }
  final processTool = createTool(
    name: 'example.process',
    description: 'Process data with progress updates',
    inputSchema: ObjectSchema(
      properties: {
        'items': Schema.list(
          items: Schema.string(),
        ),
      },
      required: ['items'],
    ),
  );
  tools.register(processTool, processHandler);

  // Example 1: Create server with default pipeline (standard middleware)
  // This uses the DefaultPipelineFactory automatically
  final server1 = McpServerBuilder()
      .withToolRegistry(tools)
      .withResourceRegistry(resources)
      .withPromptRegistry(prompts)
      .withDefaultTimeout(const Duration(minutes: 5))
      .withMaxConcurrency(10)
      .build();

  // Example 2: Create server with custom pipeline factory
  // You can completely customize the middleware pipeline
  final server2 = McpServerBuilder()
      .withToolRegistry(tools)
      .withResourceRegistry(resources)
      .withPromptRegistry(prompts)
      .withDefaultTimeout(const Duration(minutes: 5))
      .withMaxConcurrency(10)
      .withPipelineFactory((context) {
        // Create a custom pipeline
    final pipeline = ToolCallPipeline()

      // Add standard middleware in desired order
      ..add(ValidationMiddleware(
            toolRegistry: context.toolRegistry,
            sizeValidator: context.sizeValidator,
          ))
          ..add(ConfirmationMiddleware())
          ..add(SetupMiddleware(
            server: context.server,
            defaultTimeout: context.defaultTimeout,
            perToolTimeouts: context.perToolTimeouts,
          ))
          // Add your custom middleware here
          // ..add(MyCustomMiddleware())
          ..add(ConcurrencyMiddleware(
            concurrencyLimiter: context.concurrencyLimiter,
          ))
          ..add(TimeoutMiddleware())
          ..add(ExecutionMiddleware(
            toolRegistry: context.toolRegistry,
            sizeValidator: context.sizeValidator,
          ))
          ..add(ResultConversionMiddleware())
          ..add(LoggingMiddleware(logger: context.logger))
          ..add(ErrorHandlingMiddleware(logger: context.logger));
        
        return pipeline;
      })
      .build();

  // Example 3: Use CustomPipelineFactory helper for convenient customization
  // This starts with the default pipeline and allows easy modifications
  final server3 = McpServerBuilder()
      .withToolRegistry(tools)
      .withResourceRegistry(resources)
      .withPromptRegistry(prompts)
      .withDefaultTimeout(const Duration(minutes: 5))
      .withMaxConcurrency(10)
      .withPipelineFactory((context) {
        return CustomPipelineFactory(context)
            // Add custom middleware after setup
            .addAfter<SetupMiddleware>(
              // MyCustomMiddleware() // Example custom middleware
              ConfirmationMiddleware(), // Example: adding another confirmation
            )
            .build();
      })
      .build();

  // Example 4: Use MinimalPipelineFactory for minimal overhead
  // Useful for testing or when you don't need all features
  final server4 = McpServerBuilder()
      .withToolRegistry(tools)
      .withResourceRegistry(resources)
      .withPromptRegistry(prompts)
      .withDefaultTimeout(const Duration(minutes: 5))
      .withMaxConcurrency(10)
      .withPipelineFactory(MinimalPipelineFactory.create)
      .build();

  // Use server1 (default pipeline) for this example
  final server = server1;

  // Run the server
  print('Starting MCP server on stdio...');
  print('Using default pipeline with all standard middleware.');
  print('See examples 2-4 above for custom pipeline configurations.');
  await server.serve();
  print('Server stopped.');
}

