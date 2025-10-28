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
}
