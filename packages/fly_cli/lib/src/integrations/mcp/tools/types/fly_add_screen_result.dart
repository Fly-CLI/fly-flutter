import 'package:fly_mcp/fly_mcp.dart';

/// Typed result for fly.add.screen tool
class FlyAddScreenResult extends ToolResult {
  FlyAddScreenResult({
    required this.success,
    required this.message,
    this.filesGenerated,
    this.screenPath,
  });

  /// Create from JSON Map
  factory FlyAddScreenResult.fromJson(Map<String, Object?> json) {
    return FlyAddScreenResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      filesGenerated: json['filesGenerated'] as int?,
      screenPath: json['screenPath'] as String?,
    );
  }

  /// Whether the operation was successful
  final bool success;

  /// Status message
  final String message;

  /// Number of files generated
  final int? filesGenerated;

  /// Path to the generated screen
  final String? screenPath;

  @override
  Map<String, Object?> toJson() => {
        'success': success,
        'message': message,
        if (filesGenerated != null) 'filesGenerated': filesGenerated,
        if (screenPath != null) 'screenPath': screenPath,
      };
}
