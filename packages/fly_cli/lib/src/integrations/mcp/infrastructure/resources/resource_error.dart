/// Resource access error for MCP resources
///
/// Provides structured error information with hints and remediation
/// for resource access failures.
class ResourceError extends StateError {
  ResourceError({
    required String message,
    required this.code,
    required this.category,
    required this.severity,
    this.resourceUri,
    this.path,
    this.hints = const [],
    this.remediation,
    Map<String, Object?>? context,
  }) : _context = context ?? <String, Object?>{},
       super(message);

  /// Error code identifying the specific error type
  final String code;

  /// Error category (e.g., 'validation', 'permission', 'not_found')
  final String category;

  /// Error severity (e.g., 'error', 'warning')
  final String severity;

  /// The resource URI that caused the error
  final String? resourceUri;

  /// The file path that caused the error
  final String? path;

  /// Hints for resolving the error
  final List<String> hints;

  /// Remediation steps
  final String? remediation;

  /// Additional error context
  final Map<String, Object?> _context;

  /// Additional error context
  Map<String, Object?> get context => Map<String, Object?>.from(_context);

  /// Invalid resource URI
  factory ResourceError.invalidUri({
    required String resourceUri,
    String? expectedFormat,
    List<String>? hints,
  }) {
    final hintsList = [
      'Resource URI must start with a valid URI prefix (e.g., workspace://, manifest://)',
      if (expectedFormat != null) 'Expected format: $expectedFormat',
      'Check the resource URI format and try again',
      ...?hints,
    ];

    return ResourceError(
      message: 'Invalid resource URI: $resourceUri',
      code: 'invalid_uri',
      category: 'validation',
      severity: 'error',
      resourceUri: resourceUri,
      hints: hintsList,
      remediation:
          'Verify the resource URI format matches the expected schema. '
          'Use resources/list to see available resources.',
      context: {
        'resource_uri': resourceUri,
        if (expectedFormat != null) 'expected_format': expectedFormat,
      },
    );
  }

  /// Path traversal attempt
  factory ResourceError.pathTraversal({
    required String path,
    required String workspaceRoot,
    String? resourceUri,
  }) {
    return ResourceError(
      message: 'Path traversal attempt detected: $path',
      code: 'path_traversal',
      category: 'security',
      severity: 'error',
      resourceUri: resourceUri,
      path: path,
      hints: [
        'Path contains invalid characters or sequences (e.g., ../, ~/)',
        'All resource paths must be within the workspace root: $workspaceRoot',
        'Use relative paths from the workspace root',
        'Do not use absolute paths outside the workspace',
      ],
      remediation:
          'Ensure the path is within the workspace root directory. '
          'Use relative paths only. Avoid ../ or absolute paths.',
      context: {
        'path': path,
        'workspace_root': workspaceRoot,
        'reason': 'Path traversal attempt',
      },
    );
  }

  /// File not found
  factory ResourceError.notFound({
    required String path,
    String? resourceUri,
    List<String>? suggestions,
  }) {
    final hintsList = [
      'The file or directory does not exist at the specified path',
      if (suggestions != null && suggestions.isNotEmpty) ...suggestions,
      'Use resources/list to see available resources',
      'Check the file path for typos or incorrect paths',
    ];

    return ResourceError(
      message: 'Resource not found: $path',
      code: 'not_found',
      category: 'not_found',
      severity: 'error',
      resourceUri: resourceUri,
      path: path,
      hints: hintsList,
      remediation:
          'Verify the resource path exists. Use resources/list to see available resources. '
          'Check for typos or incorrect paths.',
      context: {
        'path': path,
        if (suggestions != null && suggestions.isNotEmpty)
          'suggestions': suggestions,
      },
    );
  }

  /// Permission denied
  factory ResourceError.permissionDenied({
    required String path,
    required String operation,
    String? resourceUri,
    String? reason,
  }) {
    return ResourceError(
      message: 'Permission denied: $operation operation on $path',
      code: 'permission_denied',
      category: 'permission',
      severity: 'error',
      resourceUri: resourceUri,
      path: path,
      hints: [
        'File access permissions do not allow the requested operation',
        'Check file permissions (read, write, execute)',
        if (reason != null) reason,
        'Contact workspace administrator if you need access',
      ],
      remediation:
          'Verify file permissions allow the requested operation. '
          'Check file system permissions and workspace security settings.',
      context: {
        'path': path,
        'operation': operation,
        if (reason != null) 'reason': reason,
      },
    );
  }

  /// Path outside workspace
  factory ResourceError.pathOutsideWorkspace({
    required String path,
    required String workspaceRoot,
    String? resourceUri,
  }) {
    return ResourceError(
      message: 'Path is outside workspace: $path',
      code: 'path_outside_workspace',
      category: 'security',
      severity: 'error',
      resourceUri: resourceUri,
      path: path,
      hints: [
        'All resource paths must be within the workspace root: $workspaceRoot',
        'Use relative paths from the workspace root',
        'Do not use absolute paths outside the workspace',
        'Check path resolution and ensure it stays within workspace',
      ],
      remediation:
          'Ensure the path is within the workspace root directory. '
          'Use relative paths only. The workspace root is: $workspaceRoot',
      context: {
        'path': path,
        'workspace_root': workspaceRoot,
        'resolved_path': path,
      },
    );
  }

  /// Invalid manifest file
  factory ResourceError.invalidManifestFile({
    required String fileName,
    List<String>? allowedFiles,
  }) {
    final hintsList = [
      'Manifest file name must be one of the allowed files',
      if (allowedFiles != null && allowedFiles.isNotEmpty)
        'Allowed files: ${allowedFiles.join(", ")}',
      'Use resources/list with manifest:// prefix to see available manifest files',
      'Check the file name for typos',
    ];

    return ResourceError(
      message: 'Invalid manifest file: $fileName',
      code: 'invalid_manifest_file',
      category: 'validation',
      severity: 'error',
      resourceUri: 'manifest://$fileName',
      hints: hintsList,
      remediation:
          'Use one of the allowed manifest file names. '
          'Use resources/list to see available manifest resources.',
      context: {
        'file_name': fileName,
        if (allowedFiles != null) 'allowed_files': allowedFiles,
      },
    );
  }

  /// Resource read error
  factory ResourceError.readError({
    required String path,
    required Object error,
    String? resourceUri,
  }) {
    return ResourceError(
      message: 'Failed to read resource: $path',
      code: 'read_error',
      category: 'io',
      severity: 'error',
      resourceUri: resourceUri,
      path: path,
      hints: [
        'File may be locked by another process',
        'File may be corrupted or inaccessible',
        'Check file system permissions',
        'Verify the file is not a directory',
      ],
      remediation:
          'Ensure the file is not locked, has proper permissions, and is readable. '
          'Check file system status and try again.',
      context: {
        'path': path,
        'error': error.toString(),
      },
    );
  }

  /// Invalid resource type
  factory ResourceError.invalidResourceType({
    required String resourceUri,
    required String expectedType,
    String? actualType,
  }) {
    return ResourceError(
      message: 'Invalid resource type for URI: $resourceUri',
      code: 'invalid_resource_type',
      category: 'validation',
      severity: 'error',
      resourceUri: resourceUri,
      hints: [
        'Resource URI does not match the expected resource type',
        'Expected type: $expectedType',
        if (actualType != null) 'Actual type: $actualType',
        'Use resources/list to see available resource types',
      ],
      remediation:
          'Verify the resource URI matches the expected resource type. '
          'Use resources/list to see available resources.',
      context: {
        'resource_uri': resourceUri,
        'expected_type': expectedType,
        if (actualType != null) 'actual_type': actualType,
      },
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer(message);
    if (hints.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Hints:');
      for (final hint in hints) {
        buffer.writeln('  - $hint');
      }
    }
    if (remediation != null) {
      buffer.writeln();
      buffer.writeln('Remediation: $remediation');
    }
    return buffer.toString();
  }
}
