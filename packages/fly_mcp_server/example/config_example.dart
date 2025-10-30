import 'dart:io';

import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Example showing configuration usage
Future<void> main() async {
  // Create configuration
  const config = ServerConfig(
    defaultTimeout: Duration(minutes: 10),
    concurrency: ConcurrencyConfig(
      maxConcurrency: 5,
      perToolLimits: {
        'heavy.tool': 1, // Only one instance at a time
        'light.tool': 10, // Up to 10 instances
      },
    ),
    timeouts: TimeoutConfig(
      defaultTimeout: Duration(minutes: 5),
      perToolTimeouts: {
        'heavy.tool': Duration(minutes: 30),
        'quick.tool': Duration(seconds: 30),
      },
    ),
    security: SecurityConfig(
      allowedFileSuffixes: {'.dart', '.yaml', '.json'},
      allowedFileNames: {'pubspec.yaml', 'README.md'},
    ),
    logging: LoggingConfig(
      enabled: true,
      level: LogLevel.info,
      includeCorrelationIds: true,
    ),
  );

  // Validate configuration
  try {
    config.validate();
  } catch (e) {
    print('Configuration error: $e');
    exit(1);
  }

  // Create registries
  final tools = ToolRegistry();
  // ... register tools ...

  // Create server with configuration
  final server = McpServerBuilder()
      .withConfig(config)
      .withToolRegistry(tools)
      .build();

  await server.serve();
}

