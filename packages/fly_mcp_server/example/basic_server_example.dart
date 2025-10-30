import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Basic example of creating and running an MCP server
Future<void> main() async {
  // Create registries
  final tools = ToolRegistry();
  final resources = ResourceRegistry();
  final prompts = PromptRegistry();

  // Register a simple echo tool
  tools.register(ToolDefinition(
    name: 'example.echo',
    description: 'Echo back the provided message',
    paramsSchema: {
      'type': 'object',
      'properties': {
        'message': {'type': 'string'},
      },
      'required': ['message'],
    },
    resultSchema: {
      'type': 'object',
      'properties': {
        'echo': {'type': 'string'},
      },
    },
    readOnly: true,
    idempotent: true,
    handler: (params, {cancelToken, progressNotifier}) async {
      // Check for cancellation
      cancelToken?.throwIfCancelled();

      final message = params['message'] as String? ?? '';
      return {'echo': message};
    },
  ));

  // Register a tool with progress updates
  tools.register(ToolDefinition(
    name: 'example.process',
    description: 'Process data with progress updates',
    paramsSchema: {
      'type': 'object',
      'properties': {
        'items': {
          'type': 'array',
          'items': {'type': 'string'},
        },
      },
      'required': ['items'],
    },
    handler: (params, {cancelToken, progressNotifier}) async {
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
    },
  ));

  // Create server using builder pattern
  final server = McpServerBuilder()
      .withToolRegistry(tools)
      .withResourceRegistry(resources)
      .withPromptRegistry(prompts)
      .withDefaultTimeout(Duration(minutes: 5))
      .withMaxConcurrency(10)
      .build();

  // Run the server
  print('Starting MCP server on stdio...');
  await server.connectStdioServer();
  print('Server stopped.');
}

