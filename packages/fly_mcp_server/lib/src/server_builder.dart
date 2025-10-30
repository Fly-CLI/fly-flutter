import 'package:fly_mcp_server/src/config/server_config.dart';
import 'package:fly_mcp_server/src/config/size_limits_config.dart';
import 'package:fly_mcp_server/src/registries/prompt_registry.dart';
import 'package:fly_mcp_server/src/registries/resource_registry.dart';
import 'package:fly_mcp_server/src/registries/tool_registry.dart';
import 'package:fly_mcp_server/src/server.dart';
import 'package:fly_mcp_server/src/tool_call/pipeline_factory.dart';

/// Builder for creating MCP server instances with fluent API
/// 
/// Provides a fluent interface for configuring and creating [McpServer]
/// instances. This builder pattern makes it easy to configure complex
/// server setups with validation.
/// 
/// Example:
/// ```dart
/// final server = McpServerBuilder()
///     .withToolRegistry(tools)
///     .withDefaultTimeout(Duration(minutes: 10))
///     .withMaxConcurrency(5)
///     .withConfig(config)
///     .build();
/// ```
class McpServerBuilder {
  /// Creates a new server builder
  McpServerBuilder();

  ToolRegistry? _toolRegistry;
  ResourceRegistry? _resourceRegistry;
  PromptRegistry? _promptRegistry;
  Duration? _defaultTimeout;
  int? _maxConcurrency;
  Map<String, int>? _perToolConcurrency;
  Map<String, Duration>? _perToolTimeouts;
  SecurityConfig? _securityConfig;
  LoggingConfig? _loggingConfig;
  SizeLimitsConfig? _sizeLimitsConfig;
  String? _workspaceRoot;
  ToolCallPipelineFactory? _pipelineFactory;

  /// Set the tool registry
  /// 
  /// [registry] - The tool registry to use
  /// 
  /// Returns this builder for method chaining.
  McpServerBuilder withToolRegistry(ToolRegistry registry) {
    _toolRegistry = registry;
    return this;
  }

  /// Set the resource registry
  /// 
  /// [registry] - The resource registry to use
  /// 
  /// Returns this builder for method chaining.
  McpServerBuilder withResourceRegistry(ResourceRegistry registry) {
    _resourceRegistry = registry;
    return this;
  }

  /// Set the prompt registry
  /// 
  /// [registry] - The prompt registry to use
  /// 
  /// Returns this builder for method chaining.
  McpServerBuilder withPromptRegistry(PromptRegistry registry) {
    _promptRegistry = registry;
    return this;
  }

  /// Set the default timeout for tool execution
  /// 
  /// [timeout] - Default timeout duration
  /// 
  /// Returns this builder for method chaining.
  McpServerBuilder withDefaultTimeout(Duration timeout) {
    _defaultTimeout = timeout;
    return this;
  }

  /// Set the maximum number of concurrent tool executions
  /// 
  /// [maxConcurrency] - Maximum concurrent executions
  /// 
  /// Returns this builder for method chaining.
  McpServerBuilder withMaxConcurrency(int maxConcurrency) {
    _maxConcurrency = maxConcurrency;
    return this;
  }

  /// Set per-tool concurrency limits
  /// 
  /// [limits] - Map of tool names to their concurrency limits
  /// 
  /// Returns this builder for method chaining.
  McpServerBuilder withPerToolConcurrency(Map<String, int> limits) {
    _perToolConcurrency = limits;
    return this;
  }

  /// Set per-tool timeout overrides
  /// 
  /// [timeouts] - Map of tool names to their timeout durations
  /// 
  /// Returns this builder for method chaining.
  McpServerBuilder withPerToolTimeouts(Map<String, Duration> timeouts) {
    _perToolTimeouts = timeouts;
    return this;
  }

  /// Set configuration from a [ServerConfig] object
  /// 
  /// This applies all configuration values from the config object,
  /// including timeouts, concurrency limits, security, logging, size limits, and other settings.
  /// 
  /// [config] - Complete server configuration
  /// 
  /// Returns this builder for method chaining.
  McpServerBuilder withConfig(ServerConfig config) {
    config.validate();

    _defaultTimeout = config.defaultTimeout;
    _maxConcurrency = config.concurrency.maxConcurrency;
    _perToolConcurrency = config.concurrency.perToolLimits;
    _perToolTimeouts = config.timeouts.perToolTimeouts;
    _securityConfig = config.security;
    _loggingConfig = config.logging;
    _sizeLimitsConfig = config.sizeLimits;

    return this;
  }

  /// Set the workspace root directory
  /// 
  /// [workspaceRoot] - The workspace root directory path
  /// 
  /// Returns this builder for method chaining.
  McpServerBuilder withWorkspaceRoot(String workspaceRoot) {
    _workspaceRoot = workspaceRoot;
    return this;
  }

  /// Set the logging configuration
  /// 
  /// [config] - Logging configuration
  /// 
  /// Returns this builder for method chaining.
  McpServerBuilder withLoggingConfig(LoggingConfig config) {
    _loggingConfig = config;
    return this;
  }

  /// Set the pipeline factory for customizing the middleware pipeline.
  /// 
  /// [factory] - Factory function that creates the middleware pipeline
  /// 
  /// Returns this builder for method chaining.
  /// 
  /// Example:
  /// ```dart
  /// builder.withPipelineFactory((ctx) {
  ///   return CustomPipelineFactory(ctx)
  ///       .addAfter<SetupMiddleware>(MyCustomMiddleware())
  ///       .build();
  /// });
  /// ```
  McpServerBuilder withPipelineFactory(ToolCallPipelineFactory factory) {
    _pipelineFactory = factory;
    return this;
  }

  /// Builds the configured MCP server instance with stdio transport
  /// 
  /// Validates that all required components are configured and creates
  /// a new [McpServer] instance with the specified configuration.
  /// 
  /// Returns a configured [McpServer] instance connected to stdio.
  /// 
  /// Throws [StateError] if [toolRegistry] is not set.
  McpServer build() {
    if (_toolRegistry == null) {
      throw StateError('ToolRegistry is required');
    }

    return McpServer.stdio(
      toolRegistry: _toolRegistry!,
      resourceRegistry: _resourceRegistry,
      promptRegistry: _promptRegistry,
      defaultTimeout: _defaultTimeout,
      maxConcurrency: _maxConcurrency,
      perToolConcurrency: _perToolConcurrency,
      perToolTimeouts: _perToolTimeouts,
      securityConfig: _securityConfig,
      loggingConfig: _loggingConfig,
      sizeLimitsConfig: _sizeLimitsConfig,
      workspaceRoot: _workspaceRoot,
      pipelineFactory: _pipelineFactory,
    );
  }
}

