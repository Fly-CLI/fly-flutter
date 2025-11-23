import 'package:fly_mcp/fly_mcp.dart';

/// Typed result for fly.version tool
class VersionResult extends ToolResult {
  VersionResult({
    required this.success,
    required this.message,
    this.version,
    this.sdkVersion,
    this.latestVersion,
    this.updateAvailable,
  });

  /// Create from JSON Map
  factory VersionResult.fromJson(Map<String, Object?> json) {
    return VersionResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      version: json['version'] as String?,
      sdkVersion: json['sdkVersion'] as String?,
      latestVersion: json['latestVersion'] as String?,
      updateAvailable: json['updateAvailable'] as bool?,
    );
  }

  /// Whether the operation was successful
  final bool success;

  /// Status message
  final String message;

  /// Current version
  final String? version;

  /// SDK version
  final String? sdkVersion;

  /// Latest available version
  final String? latestVersion;

  /// Whether an update is available
  final bool? updateAvailable;

  @override
  Map<String, Object?> toJson() => {
        'success': success,
        'message': message,
        if (version != null) 'version': version,
        if (sdkVersion != null) 'sdkVersion': sdkVersion,
        if (latestVersion != null) 'latestVersion': latestVersion,
        if (updateAvailable != null) 'updateAvailable': updateAvailable,
      };
}
