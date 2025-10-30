import 'package:fly_mcp_server/src/cancellation.dart';
import 'package:fly_mcp_server/src/concurrency_limiter.dart';
import 'package:fly_mcp_server/src/errors/server_errors.dart';
import 'package:fly_mcp_server/src/timeout_manager.dart';

/// JSON-RPC error codes (standard and MCP-specific)
class JsonRpcErrorCode {
  // Standard JSON-RPC 2.0 error codes
  static const int parseError = -32700;
  static const int invalidRequest = -32600;
  static const int methodNotFound = -32601;
  static const int invalidParams = -32602;
  static const int internalError = -32603;

  // MCP-specific error codes
  static const int mcpCanceled = -32800;
  static const int mcpTimeout = -32801;
  static const int mcpPermissionDenied = -32803;
  static const int mcpNotFound = -32804;
}

/// Simple JSON-RPC error representation
class JsonRpcError implements Exception {
  const JsonRpcError({
    required this.code,
    required this.message,
    this.data,
  });

  final int code;
  final String message;
  final Object? data;

  @override
  String toString() => 'JsonRpcError($code): $message';
}

/// Converts server exceptions to JSON-RPC errors
/// 
/// Note: This is mainly for compatibility. dart_mcp handles errors
/// internally by catching exceptions and returning error results.
class ErrorConverter {
  /// Converts an exception to a JsonRpcError
  /// 
  /// Maps server exceptions to appropriate JSON-RPC error codes
  /// and includes relevant diagnostic information.
  static JsonRpcError toJsonRpcError(Object error, {Object? requestId}) {
    if (error is JsonRpcError) {
      return error;
    }

    if (error is ToolNotFoundError) {
      return JsonRpcError(
        code: JsonRpcErrorCode.mcpNotFound,
        message: error.message,
        data: {
          'tool': error.toolName,
          if (requestId != null) 'requestId': requestId,
        },
      );
    }

    if (error is ResourceNotFoundError) {
      return JsonRpcError(
        code: JsonRpcErrorCode.mcpNotFound,
        message: error.message,
        data: {
          'uri': error.uri,
          if (requestId != null) 'requestId': requestId,
        },
      );
    }

    if (error is PromptNotFoundError) {
      return JsonRpcError(
        code: JsonRpcErrorCode.mcpNotFound,
        message: error.message,
        data: {
          'promptId': error.promptId,
          if (requestId != null) 'requestId': requestId,
        },
      );
    }

    if (error is MethodNotFoundError) {
      return JsonRpcError(
        code: JsonRpcErrorCode.methodNotFound,
        message: error.message,
        data: {
          'method': error.methodName,
          if (requestId != null) 'requestId': requestId,
        },
      );
    }

    if (error is ValidationError) {
      return JsonRpcError(
        code: JsonRpcErrorCode.invalidParams,
        message: error.message,
        data: {
          if (error.fieldErrors != null) 'fieldErrors': error.fieldErrors,
          if (requestId != null) 'requestId': requestId,
        },
      );
    }

    if (error is InvalidParamsError) {
      return JsonRpcError(
        code: JsonRpcErrorCode.invalidParams,
        message: error.message,
        data: {
          if (error.missingFields != null) 'missingFields': error.missingFields,
          if (error.invalidFields != null) 'invalidFields': error.invalidFields,
          if (requestId != null) 'requestId': requestId,
        },
      );
    }

    if (error is CancellationError) {
      return JsonRpcError(
        code: JsonRpcErrorCode.mcpCanceled,
        message: error.message,
        data: {
          'requestId': error.requestId,
        },
      );
    }

    if (error is TimeoutError) {
      return JsonRpcError(
        code: JsonRpcErrorCode.mcpTimeout,
        message: error.message,
        data: {
          'timeout': error.timeout.inSeconds,
          if (error.operationName != null) 'operation': error.operationName,
          if (requestId != null) 'requestId': requestId,
        },
      );
    }

    if (error is ConcurrencyLimitError) {
      return JsonRpcError(
        code: JsonRpcErrorCode.mcpPermissionDenied,
        message: error.message,
        data: {
          'tool': error.toolName,
          'current': error.current,
          'limit': error.limit,
          if (requestId != null) 'requestId': requestId,
        },
      );
    }

    if (error is PermissionDeniedError) {
      return JsonRpcError(
        code: JsonRpcErrorCode.mcpPermissionDenied,
        message: error.message,
        data: {
          if (error.reason != null) 'reason': error.reason,
          if (requestId != null) 'requestId': requestId,
        },
      );
    }

    if (error is CancellationException) {
      return JsonRpcError(
        code: JsonRpcErrorCode.mcpCanceled,
        message: error.toString(),
        data: {
          if (requestId != null) 'requestId': requestId,
        },
      );
    }

    if (error is TimeoutException) {
      return JsonRpcError(
        code: JsonRpcErrorCode.mcpTimeout,
        message: error.toString(),
        data: {
          if (requestId != null) 'requestId': requestId,
        },
      );
    }

    if (error is ConcurrencyLimitException) {
      return JsonRpcError(
        code: JsonRpcErrorCode.mcpPermissionDenied,
        message: error.message,
        data: {
          'tool': error.toolName,
          'current': error.current,
          'limit': error.limit,
          if (requestId != null) 'requestId': requestId,
        },
      );
    }

    // Default: internal server error
    return JsonRpcError(
      code: JsonRpcErrorCode.internalError,
      message: 'Internal server error: ${error.toString()}',
      data: {
        'error': error.toString(),
        if (requestId != null) 'requestId': requestId,
      },
    );
  }

  /// Checks if an error is a known server exception
  static bool isKnownError(Object error) {
    return error is McpServerException ||
        error is JsonRpcError ||
        error is CancellationException ||
        error is TimeoutException ||
        error is ConcurrencyLimitException;
  }
}

