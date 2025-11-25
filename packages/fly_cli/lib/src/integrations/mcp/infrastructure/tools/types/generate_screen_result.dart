import 'package:fly_mcp/fly_mcp.dart';

/// Typed result for fly.generate.screen tool
class GenerateScreenResult extends ToolResult {
  GenerateScreenResult({
    required this.success,
    required this.message,
    this.filesGenerated,
    this.screenPath,
  });

  /// Create from JSON Map
  factory GenerateScreenResult.fromJson(Map<String, Object?> json) {
    return GenerateScreenResult(
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
