import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Typed result for flutter.run tool
class FlutterRunResult extends ToolResult {

   FlutterRunResult({
    required this.success,
    this.exitCode,
    this.processId,
    this.logResourceUri,
    required this.message,
  });

  /// Create from JSON Map
  factory FlutterRunResult.fromJson(Map<String, Object?> json) {
    return FlutterRunResult(
      success: json['success'] as bool? ?? false,
      exitCode: json['exitCode'] as int?,
      processId: json['processId'] as String?,
      logResourceUri: json['logResourceUri'] as String?,
      message: json['message'] as String? ?? '',
    );
  }
  /// Whether the run was successful
  final bool success;

  /// Exit code
  final int? exitCode;

  /// Process ID
  final String? processId;

  /// Log resource URI
  final String? logResourceUri;

  /// Status message
  final String message;

  @override
  Map<String, Object?> toJson() => {
        'success': success,
        'message': message,
        if (exitCode != null) 'exitCode': exitCode,
        if (processId != null) 'processId': processId,
        if (logResourceUri != null) 'logResourceUri': logResourceUri,
      };
}

