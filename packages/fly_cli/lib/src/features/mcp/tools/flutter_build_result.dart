import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Typed result for flutter.build tool
class FlutterBuildResult extends ToolResult {

   FlutterBuildResult({
    required this.success,
    this.exitCode,
    this.buildPath,
    this.logResourceUri,
    required this.message,
  });

  /// Create from JSON Map
  factory FlutterBuildResult.fromJson(Map<String, Object?> json) {
    return FlutterBuildResult(
      success: json['success'] as bool? ?? false,
      exitCode: json['exitCode'] as int?,
      buildPath: json['buildPath'] as String?,
      logResourceUri: json['logResourceUri'] as String?,
      message: json['message'] as String? ?? '',
    );
  }
  /// Whether the build was successful
  final bool success;

  /// Exit code
  final int? exitCode;

  /// Build output path
  final String? buildPath;

  /// Log resource URI
  final String? logResourceUri;

  /// Status message
  final String message;

  @override
  Map<String, Object?> toJson() => {
        'success': success,
        'message': message,
        if (exitCode != null) 'exitCode': exitCode,
        if (buildPath != null) 'buildPath': buildPath,
        if (logResourceUri != null) 'logResourceUri': logResourceUri,
      };
}

