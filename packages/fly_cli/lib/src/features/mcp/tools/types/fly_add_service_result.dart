import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Typed result for fly.add.service tool
class FlyAddServiceResult extends ToolResult {
  FlyAddServiceResult({
    required this.success,
    required this.message,
    this.filesGenerated,
    this.servicePath,
  });

  /// Create from JSON Map
  factory FlyAddServiceResult.fromJson(Map<String, Object?> json) {
    return FlyAddServiceResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      filesGenerated: json['filesGenerated'] as int?,
      servicePath: json['servicePath'] as String?,
    );
  }

  /// Whether the operation was successful
  final bool success;

  /// Status message
  final String message;

  /// Number of files generated
  final int? filesGenerated;

  /// Path to the generated service
  final String? servicePath;

  @override
  Map<String, Object?> toJson() => {
        'success': success,
        'message': message,
        if (filesGenerated != null) 'filesGenerated': filesGenerated,
        if (servicePath != null) 'servicePath': servicePath,
      };
}

