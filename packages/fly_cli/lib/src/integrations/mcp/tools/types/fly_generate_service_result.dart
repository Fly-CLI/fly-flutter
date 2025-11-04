import 'package:fly_mcp/fly_mcp.dart';

/// Typed result for fly.generate.service tool
class FlyGenerateServiceResult extends ToolResult {
  FlyGenerateServiceResult({
    required this.success,
    required this.message,
    this.filesGenerated,
    this.servicePath,
  });

  /// Create from JSON Map
  factory FlyGenerateServiceResult.fromJson(Map<String, Object?> json) {
    return FlyGenerateServiceResult(
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

