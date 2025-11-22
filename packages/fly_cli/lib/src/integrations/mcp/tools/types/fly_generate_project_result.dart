import 'package:fly_mcp/fly_mcp.dart';

/// Typed result for fly.generate.project tool
class FlyGenerateProjectResult extends ToolResult {
  FlyGenerateProjectResult({
    required this.success,
    required this.message,
    this.filesGenerated,
    this.projectPath,
  });

  /// Create from JSON Map
  factory FlyGenerateProjectResult.fromJson(Map<String, Object?> json) {
    return FlyGenerateProjectResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      filesGenerated: json['filesGenerated'] as int?,
      projectPath: json['projectPath'] as String?,
    );
  }

  /// Whether the operation was successful
  final bool success;

  /// Status message
  final String message;

  /// Number of files generated
  final int? filesGenerated;

  /// Path to the generated project
  final String? projectPath;

  @override
  Map<String, Object?> toJson() => {
        'success': success,
        'message': message,
        if (filesGenerated != null) 'filesGenerated': filesGenerated,
        if (projectPath != null) 'projectPath': projectPath,
      };
}

