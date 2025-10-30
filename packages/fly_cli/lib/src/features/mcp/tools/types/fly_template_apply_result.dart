import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Typed result for fly.template.apply tool
class FlyTemplateApplyResult extends ToolResult {

   FlyTemplateApplyResult({
    required this.success,
    this.targetDirectory,
    this.filesGenerated,
    this.durationMs,
    required this.message,
  });

  /// Create from JSON Map
  factory FlyTemplateApplyResult.fromJson(Map<String, Object?> json) {
    return FlyTemplateApplyResult(
      success: json['success'] as bool? ?? false,
      targetDirectory: json['targetDirectory'] as String?,
      filesGenerated: json['filesGenerated'] as int?,
      durationMs: json['duration_ms'] as int? ?? json['durationMs'] as int?,
      message: json['message'] as String? ?? '',
    );
  }
  /// Whether the template application was successful
  final bool success;

  /// Target directory where template was applied
  final String? targetDirectory;

  /// Number of files generated
  final int? filesGenerated;

  /// Duration in milliseconds
  final int? durationMs;

  /// Status message
  final String message;

  @override
  Map<String, Object?> toJson() => {
        'success': success,
        'message': message,
        if (targetDirectory != null) 'targetDirectory': targetDirectory,
        if (filesGenerated != null) 'filesGenerated': filesGenerated,
        if (durationMs != null) 'duration_ms': durationMs,
      };
}

