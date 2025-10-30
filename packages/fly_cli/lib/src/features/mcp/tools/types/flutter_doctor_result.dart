import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Typed result for flutter.doctor tool
class FlutterDoctorResult extends ToolResult {

   FlutterDoctorResult({
    required this.stdout,
    required this.exitCode,
  });

  /// Create from JSON Map
  factory FlutterDoctorResult.fromJson(Map<String, Object?> json) {
    return FlutterDoctorResult(
      stdout: json['stdout'] as String? ?? '',
      exitCode: json['exitCode'] as int? ?? 0,
    );
  }
  /// Standard output from flutter doctor
  final String stdout;

  /// Exit code
  final int exitCode;

  @override
  Map<String, Object?> toJson() => {
        'stdout': stdout,
        'exitCode': exitCode,
      };
}

