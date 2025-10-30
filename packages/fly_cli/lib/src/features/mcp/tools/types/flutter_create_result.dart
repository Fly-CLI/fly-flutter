import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Typed result for flutter.create tool
class FlutterCreateResult extends ToolResult {

   FlutterCreateResult({
    required this.success,
    this.projectPath,
    this.filesGenerated,
    required this.message,
  });

  /// Create from JSON Map
  factory FlutterCreateResult.fromJson(Map<String, Object?> json) {
    return FlutterCreateResult(
      success: json['success'] as bool? ?? false,
      projectPath: json['projectPath'] as String?,
      filesGenerated: json['filesGenerated'] as int?,
      message: json['message'] as String? ?? '',
    );
  }
  /// Whether the creation was successful
  final bool success;

  /// Path to the created project
  final String? projectPath;

  /// Number of files generated
  final int? filesGenerated;

  /// Status message
  final String message;

  @override
  Map<String, Object?> toJson() => {
        'success': success,
        'message': message,
        if (projectPath != null) 'projectPath': projectPath,
        if (filesGenerated != null) 'filesGenerated': filesGenerated,
      };
}

