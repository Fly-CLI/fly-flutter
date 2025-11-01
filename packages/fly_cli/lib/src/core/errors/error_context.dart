import 'dart:io';

/// Simple error context helper for consistent error reporting
///
/// Provides static methods to create common error context patterns
/// without complex fluent APIs or builders.
class ErrorContext {
  /// Create context for command operations
  static Map<String, dynamic> forCommand(
    String commandName, {
    List<String>? arguments,
    Map<String, dynamic>? extra,
  }) {
    return {
      'command': commandName,
      'arguments': arguments,
      'timestamp': DateTime.now().toIso8601String(),
      'platform': Platform.operatingSystem,
      'platform_version': Platform.operatingSystemVersion,
      ...?extra,
    };
  }

  /// Create context for validation errors
  static Map<String, dynamic> forValidation(
    String fieldName,
    dynamic value,
    String reason,
  ) {
    return {
      'field': fieldName,
      'value': value,
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Create context for file operations
  static Map<String, dynamic> forFileOperation(
    String operation,
    String path, {
    String? error,
  }) {
    return {
      'operation': operation,
      'path': path,
      'error': error,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Create context for template operations
  static Map<String, dynamic> forTemplateOperation(
    String operation,
    String templateName, {
    String? outputPath,
    Map<String, dynamic>? variables,
  }) {
    return {
      'operation': operation,
      'template_name': templateName,
      'output_path': outputPath,
      'variables': variables,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Create context for project operations
  static Map<String, dynamic> forProjectOperation(
    String operation,
    String projectName, {
    String? projectPath,
    String? projectType,
  }) {
    return {
      'operation': operation,
      'project_name': projectName,
      'project_path': projectPath,
      'project_type': projectType,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Create context for network operations
  static Map<String, dynamic> forNetworkOperation(
    String operation,
    String url, {
    int? statusCode,
    Duration? timeout,
  }) {
    return {
      'operation': operation,
      'url': url,
      'status_code': statusCode,
      'timeout_ms': timeout?.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Create context for permission errors
  static Map<String, dynamic> forPermissionError(
    String operation,
    String path, {
    String? requiredPermission,
  }) {
    return {
      'operation': operation,
      'path': path,
      'required_permission': requiredPermission,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Create context for system errors
  static Map<String, dynamic> forSystemError(
    String operation, {
    String? resource,
    String? error,
  }) {
    return {
      'operation': operation,
      'resource': resource,
      'error': error,
      'timestamp': DateTime.now().toIso8601String(),
      'platform': Platform.operatingSystem,
    };
  }

  /// Create basic context with custom fields
  static Map<String, dynamic> basic({
    required String operation,
    Map<String, dynamic>? extra,
  }) {
    return {
      'operation': operation,
      'timestamp': DateTime.now().toIso8601String(),
      ...?extra,
    };
  }

  /// Create context for MCP tool errors
  static Map<String, dynamic> forMcpToolError(
    String tool,
    String error, {
    Map<String, dynamic>? params,
    List<String>? validationErrors,
    String? hint,
    List<String>? remediation,
  }) {
    return {
      'tool': tool,
      'error': error,
      'params': params,
      'validation_errors': validationErrors,
      'hint':
          hint ?? 'Check tool schema with tools/list for correct parameters',
      'remediation': remediation ??
          [
            'Call tools/list to see available tools',
            'Read tool schema to understand parameters',
            'Verify all required parameters are provided',
            'Check parameter types match schema',
          ],
      'timestamp': DateTime.now().toIso8601String(),
      'platform': Platform.operatingSystem,
    };
  }

  /// Create context for MCP resource errors
  static Map<String, dynamic> forMcpResourceError(
    String resourceUri,
    String error, {
    String? resourceType,
    String? hint,
    List<String>? remediation,
  }) {
    return {
      'resource_uri': resourceUri,
      'resource_type': resourceType,
      'error': error,
      'hint': hint ?? 'Verify resource URI is correct',
      'remediation': remediation ??
          [
            'Use resources/list to discover available resources',
            'Verify resource URI prefix (workspace://, logs://, etc.)',
            'Check resource exists and is accessible',
          ],
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Create context for MCP validation errors
  static Map<String, dynamic> forMcpValidationError(
    String field,
    dynamic value,
    String reason, {
    String? tool,
    String? hint,
    List<String>? remediation,
  }) {
    final hints = <String>[];
    if (field.toLowerCase().contains('name')) {
      hints.add('Names must be lowercase (e.g., "Home" → "home")');
    }
    if (field.toLowerCase().contains('screen')) {
      hints.add('Screen names must be lowercase and use snake_case');
    }

    final defaultHint = hints.isNotEmpty ? hints.first : reason;

    return {
      'tool': tool,
      'field': field,
      'value': value.toString(),
      'reason': reason,
      'hint': hint ?? defaultHint,
      'remediation': remediation ?? hints,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
