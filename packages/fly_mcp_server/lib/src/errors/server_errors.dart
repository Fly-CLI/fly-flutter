/// Unified error hierarchy for MCP server

/// Base exception class for all MCP server errors
abstract class McpServerException implements Exception {
  const McpServerException({
    required this.message,
    this.cause,
    this.context,
  });

  final String message;
  final Object? cause;
  final Map<String, Object?>? context;

  @override
  String toString() {
    final buffer = StringBuffer(message);
    if (cause != null) {
      buffer.write(' (caused by: $cause)');
    }
    if (context != null && context!.isNotEmpty) {
      buffer.write(' [context: $context]');
    }
    return buffer.toString();
  }
}

/// Exception thrown when a tool is not found
class ToolNotFoundError extends McpServerException {
  const ToolNotFoundError({
    required this.toolName,
    super.cause,
    super.context,
  }) : super(message: 'Tool not found: $toolName');

  final String toolName;
}

/// Exception thrown when a resource is not found
class ResourceNotFoundError extends McpServerException {
  const ResourceNotFoundError({
    required this.uri,
    super.cause,
    super.context,
  }) : super(message: 'Resource not found: $uri');

  final String uri;
}

/// Exception thrown when a prompt is not found
class PromptNotFoundError extends McpServerException {
  const PromptNotFoundError({
    required this.promptId,
    super.cause,
    super.context,
  }) : super(message: 'Prompt not found: $promptId');

  final String promptId;
}

/// Exception thrown when method is not found
class MethodNotFoundError extends McpServerException {
  const MethodNotFoundError({
    required this.methodName,
    super.cause,
    super.context,
  }) : super(message: 'Method not found: $methodName');

  final String methodName;
}

/// Exception thrown when validation fails
class ValidationError extends McpServerException {
  const ValidationError({
    required super.message,
    this.fieldErrors,
    super.cause,
    super.context,
  });

  final Map<String, List<String>>? fieldErrors;

  @override
  String toString() {
    final buffer = StringBuffer(super.toString());
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      buffer.write(' [field errors: $fieldErrors]');
    }
    return buffer.toString();
  }
}

/// Exception thrown when parameters are invalid
class InvalidParamsError extends McpServerException {
  const InvalidParamsError({
    required super.message,
    this.missingFields,
    this.invalidFields,
    super.cause,
    super.context,
  });

  final List<String>? missingFields;
  final List<String>? invalidFields;

  @override
  String toString() {
    final buffer = StringBuffer(super.toString());
    if (missingFields != null && missingFields!.isNotEmpty) {
      buffer.write(' [missing fields: $missingFields]');
    }
    if (invalidFields != null && invalidFields!.isNotEmpty) {
      buffer.write(' [invalid fields: $invalidFields]');
    }
    return buffer.toString();
  }
}

/// Exception thrown when a request is cancelled
class CancellationError extends McpServerException {
  const CancellationError({
    required this.requestId,
    super.cause,
    super.context,
  }) : super(message: 'Request cancelled: $requestId');

  final Object requestId;
}

/// Exception thrown when a request times out
class TimeoutError extends McpServerException {
  TimeoutError({
    required this.timeout,
    this.operationName,
    super.cause,
    super.context,
  }) : super(
          message: operationName != null
              ? 'Operation ($operationName) timed out after ${timeout.inSeconds}s'
              : 'Operation timed out after ${timeout.inSeconds}s',
        );

  final Duration timeout;
  final String? operationName;
}

/// Exception thrown when concurrency limit is exceeded
class ConcurrencyLimitError extends McpServerException {
  const ConcurrencyLimitError({
    required this.toolName,
    required this.current,
    required this.limit,
    super.cause,
    super.context,
  }) : super(
          message: 'Maximum concurrency reached for tool: $toolName (current: $current, limit: $limit)',
        );

  final String toolName;
  final int current;
  final int limit;
}

/// Exception thrown when permission is denied
class PermissionDeniedError extends McpServerException {
  const PermissionDeniedError({
    required super.message,
    this.reason,
    super.cause,
    super.context,
  });

  final String? reason;
}

/// Exception thrown when an internal server error occurs
class InternalServerError extends McpServerException {
  const InternalServerError({
    required super.message,
    super.cause,
    super.context,
  });
}

