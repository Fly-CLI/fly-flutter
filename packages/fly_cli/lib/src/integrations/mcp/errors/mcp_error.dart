import 'package:fly_cli/src/integrations/mcp/errors/mcp_error_hints.dart';

/// MCP-specific error exception with structured error data
///
/// Extends [StateError] to provide structured error information
/// that includes hints and remediation suggestions for AI assistants.
class McpError extends StateError {
  /// The structured error data with hints and remediation
  final Map<String, Object?> errorData;

  /// The MCP error code (if applicable)
  final int? mcpErrorCode;

  /// Create an MCP error with structured error data
  McpError(
    super.message,
    this.errorData, {
    this.mcpErrorCode,
  });

  /// Create an error for invalid parameters
  factory McpError.invalidParams({
    required String tool,
    required List<String> errors,
    Map<String, Object?>? context,
  }) {
    final errorData = McpErrorHints.invalidParams(
      tool: tool,
      errors: errors,
      context: context,
    );
    return McpError(
      'Invalid parameters for tool: $tool',
      errorData,
      mcpErrorCode: -32602, // MCP_INVALID_PARAMS
    );
  }

  /// Create an error for tool not found
  factory McpError.toolNotFound({
    required String tool,
    Map<String, Object?>? context,
  }) {
    final errorData = McpErrorHints.toolNotFound(
      tool: tool,
      context: context,
    );
    return McpError(
      'Tool not found: $tool',
      errorData,
      mcpErrorCode: -32804, // MCP_NOT_FOUND
    );
  }

  /// Create an error for permission denied
  factory McpError.permissionDenied({
    required String tool,
    String? reason,
    int? current,
    int? limit,
    Map<String, Object?>? context,
  }) {
    final errorData = McpErrorHints.permissionDenied(
      tool: tool,
      reason: reason,
      current: current,
      limit: limit,
      context: context,
    );
    return McpError(
      'Permission denied for tool: $tool',
      errorData,
      mcpErrorCode: -32803, // MCP_PERMISSION_DENIED
    );
  }

  /// Create an error for timeout
  factory McpError.timeout({
    required String tool,
    required Duration timeout,
    String? operation,
    Map<String, Object?>? context,
  }) {
    final errorData = McpErrorHints.timeout(
      tool: tool,
      timeout: timeout,
      operation: operation,
      context: context,
    );
    return McpError(
      'Operation timed out after ${timeout.inSeconds}s',
      errorData,
      mcpErrorCode: -32801, // MCP_TIMEOUT
    );
  }

  /// Create an error for resource not found
  factory McpError.resourceNotFound({
    required String resourceUri,
    String? resourceType,
    Map<String, Object?>? context,
  }) {
    final errorData = McpErrorHints.resourceNotFound(
      resourceUri: resourceUri,
      resourceType: resourceType,
      context: context,
    );
    return McpError(
      'Resource not found: $resourceUri',
      errorData,
      mcpErrorCode: -32804, // MCP_NOT_FOUND
    );
  }

  /// Create an error for template operations
  factory McpError.templateError({
    required String templateId,
    required String error,
    Map<String, Object?>? variables,
    Map<String, Object?>? context,
  }) {
    final errorData = McpErrorHints.templateError(
      templateId: templateId,
      error: error,
      variables: variables,
      context: context,
    );
    return McpError(
      'Template error: $error',
      errorData,
    );
  }

  /// Create an error for validation failures
  factory McpError.validationError({
    required String field,
    required dynamic value,
    required String reason,
    String? tool,
    String? suggestion,
    Map<String, Object?>? context,
  }) {
    final errorData = McpErrorHints.validationError(
      field: field,
      value: value,
      reason: reason,
      suggestion: suggestion,
      context: context,
    );
    if (tool != null) {
      errorData['tool'] = tool;
    }
    return McpError(
      'Validation error: $field = $value ($reason)',
      errorData,
      mcpErrorCode: -32602, // MCP_INVALID_PARAMS
    );
  }

  /// Create an error for screen name validation
  factory McpError.screenNameValidation({
    required String screenName,
    Map<String, Object?>? context,
  }) {
    final errorData = McpErrorHints.screenNameValidationError(
      screenName: screenName,
      context: context,
    );
    return McpError(
      'Invalid screen name: $screenName',
      errorData,
      mcpErrorCode: -32602, // MCP_INVALID_PARAMS
    );
  }

  /// Create an error for file system operations
  factory McpError.fileSystemError({
    required String operation,
    required String path,
    String? error,
    Map<String, Object?>? context,
  }) {
    final errorData = McpErrorHints.fileSystemError(
      operation: operation,
      path: path,
      error: error,
      context: context,
    );
    return McpError(
      'File system error: $operation on $path',
      errorData,
    );
  }

  /// Convert error to JSON-RPC error format
  Map<String, Object?> toJsonRpcError() {
    return {
      'code': mcpErrorCode ?? -32603, // Default to INTERNAL_ERROR
      'message': message,
      'data': errorData,
    };
  }
}
