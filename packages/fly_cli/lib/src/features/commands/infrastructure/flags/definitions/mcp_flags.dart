part of '../cli_flags.dart';

// ============================================================================
// MCP Serve Command Flags
// ============================================================================

/// MCP serve stdio flag
class McpServeStdioFlag extends CliFlag {
  const McpServeStdioFlag()
    : super(
        name: 'stdio',
        description: 'Use stdio transport (required for MCP desktop clients)',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.boolean,
        isNegatable: false,
        defaultValue: true,
      );
}

/// MCP serve max message MB flag
class McpServeMaxMessageMbFlag extends CliFlag {
  const McpServeMaxMessageMbFlag()
    : super(
        name: 'max-message-mb',
        description: 'Max message size in MB',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.singleValue,
        defaultValue: '2',
      );
}

/// MCP serve default timeout seconds flag
class McpServeDefaultTimeoutSecondsFlag extends CliFlag {
  const McpServeDefaultTimeoutSecondsFlag()
    : super(
        name: 'default-timeout-seconds',
        description:
            'Default timeout for tools in seconds (default: 5 minutes)',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.singleValue,
        defaultValue: '300',
      );
}

/// MCP serve max concurrency flag
class McpServeMaxConcurrencyFlag extends CliFlag {
  const McpServeMaxConcurrencyFlag()
    : super(
        name: 'max-concurrency',
        description: 'Maximum concurrent tool executions',
        isGlobal: false,
        category: CliFlagCategory.execution,
        type: FlagType.singleValue,
        defaultValue: '10',
      );
}
