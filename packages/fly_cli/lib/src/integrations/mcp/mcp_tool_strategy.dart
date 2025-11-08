import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/telemetry/domain/metrics_collector.dart';
import 'package:fly_cli/src/integrations/mcp/errors/mcp_error.dart';
import 'package:fly_cli/src/integrations/mcp/utils/tool_logger.dart';
import 'package:fly_core/fly_core_dart.dart';
import 'package:fly_mcp/fly_mcp.dart';

/// Typed handler function for tool execution
///
/// [params] - Typed tool parameters
/// [cancelToken] - Cancellation token to check for cancellation requests
/// [progressNotifier] - Progress notifier for sending progress updates
///
/// Returns the typed tool execution result.
typedef TypedToolHandler<TP extends ToolParameter, TR extends ToolResult>
    = Future<TR> Function(
  TP params, {
  CancellationToken? cancelToken,
  ProgressNotifier? progressNotifier,
});

/// Abstract base class for MCP tool strategies
///
/// Each tool implements a concrete strategy that encapsulates all tool-specific
/// metadata, schemas, and handler creation logic.
///
/// [TP] - The typed parameter class implementing ToolParameter
/// [TR] - The typed result class implementing ToolResult
abstract class McpToolStrategy<TP extends ToolParameter,
    TR extends ToolResult> {
  /// The tool name as it appears in MCP (e.g., 'fly.echo')
  String get name;

  /// Human-readable description of the tool
  String get description;

  /// JSON schema for tool parameters
  ObjectSchema get paramsSchema;

  /// JSON schema for tool results
  ObjectSchema get resultSchema;

  /// Whether this tool is read-only (does not modify system state)
  bool get readOnly;

  /// Whether this tool writes to disk
  bool get writesToDisk;

  /// Whether this tool requires user confirmation before execution
  bool get requiresConfirmation;

  /// Whether this tool is idempotent (can be safely called multiple times)
  bool get idempotent;

  /// Custom timeout for this tool, or null to use the default timeout
  Duration? get timeout => null;

  /// Maximum concurrency for this tool, or null to use the default concurrency
  int? get maxConcurrency => null;

  /// Create a typed parameter instance from JSON Map
  ///
  /// [json] - The JSON Map representation
  ///
  /// Returns an instance of the typed parameter class.
  TP paramsFromJson(Map<String, Object?> json);

  /// Creates a typed handler function for this tool
  ///
  /// The handler will be called when the tool is invoked via MCP.
  /// This is the preferred method for creating handlers with full type safety.
  TypedToolHandler<TP, TR> createTypedHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  );

  /// Creates a handler function for this tool (for protocol compatibility)
  ///
  /// The handler will be called when the tool is invoked via MCP.
  /// This method wraps the typed handler and converts between Map and typed
  /// models.
  ToolHandler createHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    final typedHandler = createTypedHandler(context, resourceRegistry);
    return (
      Map<String, Object?> mapParams, {
      CancellationToken? cancelToken,
      ProgressNotifier? progressNotifier,
    }) async {
      // Layer 1: Protocol Validation - Validate raw JSON before type conversion
      // This ensures invalid protocol data is rejected early, before parsing
      final validationErrors = ProtocolValidator.validateParameters(
        rawJson: mapParams,
        schema: paramsSchema,
      );

      if (validationErrors.isNotEmpty) {
        // Convert validation errors to structured format for MCP error reporting
        final errorMessages =
            validationErrors.map((e) => e.message as String).toList();
        final fieldErrors = <String, Object?>{};

        for (final error in validationErrors) {
          fieldErrors[error.path] = {
            'type': error.type.name,
            'expected': error.expected,
            'actual': error.actual?.toString(),
            'message': error.message,
            'hint': error.hint,
          };
        }

        throw McpError.invalidParams(
          tool: name,
          errors: errorMessages,
          context: {
            'field_errors': fieldErrors,
            'validation_errors':
                validationErrors.map((e) => e.toMap()).toList(),
          },
        );
      }

      // Layer 2: Type Conversion - Now safe to convert to typed parameters
      // Protocol validation ensures the JSON structure is valid
      final params = paramsFromJson(mapParams);

      // Create tool logger with correlation ID for structured logging
      final toolLogger = context.createToolLogger(
        toolName: name,
        initialFields: {
          'params': params.toJson(),
        },
      );

      // Log tool start
      toolLogger.logStart(params: params.toJson());

      // Track performance metrics
      final metrics = ToolPerformanceMetrics(
        logger: toolLogger,
        toolName: name,
        metricsCollector: context.metricsCollector,
      );
      metrics.startTimer('total_execution');

      try {
        // Execute typed handler
        final result = await typedHandler(
          params,
          cancelToken: cancelToken,
          progressNotifier: progressNotifier,
        );

        metrics.stopTimer('total_execution');

        // Layer 4: Result Validation - Validate result against schema (advisory)
        // Result validation failures are logged but don't fail the operation
        final resultJson = result.toJson();
        final resultValidationErrors = ProtocolValidator.validateResult(
          result: resultJson,
          schema: resultSchema,
        );

        if (resultValidationErrors.isNotEmpty) {
          // Log validation warnings (result validation is advisory)
          toolLogger.warn(
            'Result validation failed for tool $name',
            fields: {
              'validation_errors':
                  resultValidationErrors.map((e) => e.toMap()).toList(),
            },
          );
        }

        // Log tool completion
        final durationMs =
            metrics.getMetrics()['total_execution_duration_ms'] as int?;
        toolLogger.logComplete(
          success: true,
          result: {
            if (resultJson.containsKey('success'))
              'success': resultJson['success'],
            if (durationMs != null) 'duration_ms': durationMs,
          },
          durationMs: durationMs,
        );

        // Convert typed result to Map for protocol
        return resultJson;
      } catch (error, stackTrace) {
        metrics.stopTimer('total_execution');

        // Log tool error
        if (error is McpError) {
          final errorData = error.errorData;
          toolLogger.logError(
            message: error.message,
            error: error,
            stackTrace: stackTrace,
            context: {
              if (errorData.containsKey('tool')) 'tool': errorData['tool'],
              if (error.mcpErrorCode != null) 'error_code': error.mcpErrorCode,
              if (errorData.containsKey('hint')) 'hint': errorData['hint'],
              if (errorData.containsKey('remediation'))
                'remediation': errorData['remediation'],
              if (errorData.containsKey('field_errors'))
                'field_errors': errorData['field_errors'],
              if (errorData.containsKey('errors'))
                'errors': errorData['errors'],
            },
          );
        } else {
          toolLogger.logError(
            message: error.toString(),
            error: error,
            stackTrace: stackTrace,
          );
        }

        // Re-throw error
        rethrow;
      }
    };
  }

  /// Creates a [Tool] instance from `dart_mcp/src/api/tools.dart` for this tool
  ///
  /// This factory method uses all metadata from the strategy to create
  /// a complete [Tool] object that can be registered with ToolRegistry.
  /// Returns the Tool, handler, and requiresConfirmation separately,
  /// since Tool doesn't include the handler or confirmation requirement.
  ({
    Tool tool,
    ToolHandler handler,
    bool requiresConfirmation,
  }) createToolAndHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    final handler = createHandler(context, resourceRegistry);
    final tool = createTool(
      name: name,
      description: description,
      inputSchema: paramsSchema,
      outputSchema: resultSchema,
      readOnly: readOnly,
      writesToDisk: writesToDisk,
      requiresConfirmation: requiresConfirmation,
      idempotent: idempotent,
    );
    return (
      tool: tool,
      handler: handler,
      requiresConfirmation: requiresConfirmation,
    );
  }
}
