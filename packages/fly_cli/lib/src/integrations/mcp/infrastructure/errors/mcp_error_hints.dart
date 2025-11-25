/// MCP error hint generation utilities
///
/// Provides structured error hints with actionable remediation suggestions
/// following the patterns described in AI_INTEGRATION_GUIDE.md
class McpErrorHints {
  /// Create error data with hints for invalid parameters
  static Map<String, Object?> invalidParams({
    required String tool,
    required List<String> errors,
    Map<String, Object?>? context,
  }) {
    return {
      'tool': tool,
      'errors': errors,
      'hint': _getInvalidParamsHint(tool, errors),
      'remediation': _getInvalidParamsRemediation(tool, errors),
      'documentation':
          'Check tool schema with tools/list for correct parameters',
      if (context != null) ...context,
    };
  }

  /// Create error data with hints for tool not found
  static Map<String, Object?> toolNotFound({
    required String tool,
    Map<String, Object?>? context,
  }) {
    return {
      'tool': tool,
      'hint':
          'Verify tool name spelling and check available tools with tools/list',
      'remediation': [
        'Call tools/list to see all available tools',
        'Verify tool name is correct (case-sensitive)',
        'Check if tool requires specific workspace context',
        'Verify MCP server is properly initialized',
      ],
      'documentation': 'Use tools/list to discover available tools',
      if (context != null) ...context,
    };
  }

  /// Create error data with hints for permission denied
  static Map<String, Object?> permissionDenied({
    required String tool,
    String? reason,
    int? current,
    int? limit,
    Map<String, Object?>? context,
  }) {
    return {
      'tool': tool,
      'reason': reason ?? 'Permission denied or concurrency limit exceeded',
      if (current != null) 'current': current,
      if (limit != null) 'limit': limit,
      'hint': _getPermissionDeniedHint(tool, reason, current, limit),
      'remediation': _getPermissionDeniedRemediation(
        tool,
        reason,
        current,
        limit,
      ),
      'documentation': 'Check tool requirements and limits',
      if (context != null) ...context,
    };
  }

  /// Create error data with hints for timeout
  static Map<String, Object?> timeout({
    required String tool,
    required Duration timeout,
    String? operation,
    Map<String, Object?>? context,
  }) {
    return {
      'tool': tool,
      'timeout_seconds': timeout.inSeconds,
      'operation': operation,
      'hint': 'Operation exceeded timeout limit',
      'remediation': [
        'Check if operation is still running (read logs if available)',
        'Consider breaking operation into smaller steps',
        'Verify system resources are sufficient',
        'Retry operation if it\'s idempotent',
      ],
      'documentation': 'Long-running operations may require extended timeouts',
      if (context != null) ...context,
    };
  }

  /// Create error data with hints for resource not found
  static Map<String, Object?> resourceNotFound({
    required String resourceUri,
    String? resourceType,
    Map<String, Object?>? context,
  }) {
    return {
      'resource_uri': resourceUri,
      'resource_type': resourceType,
      'hint': 'Resource URI not found or invalid',
      'remediation': [
        'Verify resource URI is correct',
        'Check resource type prefix (workspace://, logs://, etc.)',
        'Use resources/list to discover available resources',
        'Verify resource exists and is accessible',
      ],
      'documentation': 'Use resources/list to explore available resources',
      if (context != null) ...context,
    };
  }

  /// Create error data with hints for template errors
  static Map<String, Object?> templateError({
    required String templateId,
    required String error,
    Map<String, Object?>? variables,
    Map<String, Object?>? context,
  }) {
    return {
      'template_id': templateId,
      'error': error,
      'variables': variables,
      'hint': 'Template operation failed',
      'remediation': [
        'Check template ID is correct (use fly.template.list to see available templates)',
        'Verify template variables match template requirements',
        'Check template compatibility with current Flutter/Dart SDK versions',
        'Review template error details for specific issues',
      ],
      'documentation':
          'Use fly.template.list to see available templates and their requirements',
      if (context != null) ...context,
    };
  }

  /// Create error data with hints for validation errors
  static Map<String, Object?> validationError({
    required String field,
    required dynamic value,
    required String reason,
    String? suggestion,
    Map<String, Object?>? context,
  }) {
    final hints = <String>[];

    // Add field-specific suggestions
    if (field.toLowerCase().contains('name')) {
      hints.add('Names must be lowercase (e.g., "Home" → "home")');
      hints.add('Names must contain only letters, numbers, and underscores');
    } else if (field.toLowerCase().contains('path') ||
        field.toLowerCase().contains('directory')) {
      hints.add('Verify path exists and is accessible');
      hints.add('Check for path traversal attempts (../ is not allowed)');
      hints.add('Ensure path is within workspace root');
    } else if (field.toLowerCase().contains('template')) {
      hints.add('Use fly.template.list to see available templates');
      hints.add('Check template name spelling and version compatibility');
    }

    if (suggestion != null) {
      hints.insert(0, suggestion);
    }

    return {
      'field': field,
      'value': value.toString(),
      'reason': reason,
      'hint': hints.isNotEmpty ? hints.first : reason,
      'remediation': hints,
      'documentation': 'Check parameter schema for valid values',
      if (context != null) ...context,
    };
  }

  /// Create error data with hints for screen name validation
  static Map<String, Object?> screenNameValidationError({
    required String screenName,
    Map<String, Object?>? context,
  }) {
    final lowercaseName = screenName.toLowerCase();
    final needsConversion = screenName != lowercaseName;

    return {
      'provided_name': screenName,
      'suggested_name': lowercaseName,
      'needs_conversion': needsConversion,
      'hint': 'Screen names must be lowercase',
      'remediation': [
        if (needsConversion)
          'Convert screen name to lowercase: "$screenName" → "$lowercaseName"',
        'Screen names must contain only letters, numbers, and underscores',
        'Use lowercase snake_case for multi-word names (e.g., "product_list")',
      ],
      'documentation': 'Fly convention: Screen names must be lowercase',
      if (context != null) ...context,
    };
  }

  /// Create error data with hints for file system errors
  static Map<String, Object?> fileSystemError({
    required String operation,
    required String path,
    String? error,
    Map<String, Object?>? context,
  }) {
    return {
      'operation': operation,
      'path': path,
      'error': error,
      'hint': 'File system operation failed',
      'remediation': [
        'Check file permissions',
        'Verify path exists and is accessible',
        'Ensure sufficient disk space',
        'Check for file system errors',
        'Verify path is within allowed workspace boundaries',
      ],
      'documentation': 'File operations are restricted to workspace root',
      if (context != null) ...context,
    };
  }

  /// Get hint for invalid parameters based on tool and errors
  static String _getInvalidParamsHint(String tool, List<String> errors) {
    if (errors.any((e) => e.toLowerCase().contains('missing'))) {
      return 'Missing required parameters. Check tool schema for required fields';
    }
    if (errors.any((e) => e.toLowerCase().contains('type'))) {
      return 'Parameter type mismatch. Verify parameter types match schema';
    }
    if (errors.any((e) => e.toLowerCase().contains('enum'))) {
      return 'Invalid enum value. Check schema for allowed values';
    }
    if (tool.contains('template') || tool.contains('apply')) {
      return 'Template parameters invalid. Check template variable requirements';
    }
    return 'Check tool schema with tools/list for correct parameters';
  }

  /// Get remediation steps for invalid parameters
  static List<String> _getInvalidParamsRemediation(
    String tool,
    List<String> errors,
  ) {
    final steps = <String>[
      'Call tools/list to read tool schema',
      'Verify all required parameters are provided',
      'Check parameter types match schema',
      'Verify enum values are valid',
    ];

    if (errors.any((e) => e.toLowerCase().contains('confirm'))) {
      steps.add('Provide confirm: true for destructive operations');
    }

    if (tool.contains('template') || tool.contains('screen')) {
      steps.add('Convert names to lowercase if needed');
      steps.add('Check template variable requirements');
    }

    return steps;
  }

  /// Get hint for permission denied errors
  static String _getPermissionDeniedHint(
    String tool,
    String? reason,
    int? current,
    int? limit,
  ) {
    if (current != null && limit != null) {
      return 'Concurrency limit exceeded: $current/$limit concurrent operations';
    }
    if (reason?.toLowerCase().contains('confirm') ?? false) {
      return 'Confirmation required for this operation';
    }
    return 'Permission denied. Check requirements and try again';
  }

  /// Get remediation steps for permission denied
  static List<String> _getPermissionDeniedRemediation(
    String tool,
    String? reason,
    int? current,
    int? limit,
  ) {
    final steps = <String>[];

    if (current != null && limit != null) {
      steps.add('Wait for other operations to complete');
      steps.add('Reduce concurrent operations');
    }

    if (reason?.toLowerCase().contains('confirm') ?? false) {
      steps.add('Provide confirm: true for writes-to-disk operations');
    } else {
      steps.add('Verify workspace context is correct');
      steps.add('Check if operation requires specific permissions');
    }

    return steps;
  }
}
