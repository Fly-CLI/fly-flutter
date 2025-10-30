import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Typed result for fly.doctor tool
class FlyDoctorResult extends ToolResult {
  FlyDoctorResult({
    required this.success,
    required this.message,
    this.totalChecks,
    this.healthyChecks,
    this.issuesFound,
    this.overallStatus,
    this.checks,
  });

  /// Create from JSON Map
  factory FlyDoctorResult.fromJson(Map<String, Object?> json) {
    return FlyDoctorResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      totalChecks: json['totalChecks'] as int?,
      healthyChecks: json['healthyChecks'] as int?,
      issuesFound: json['issuesFound'] as int?,
      overallStatus: json['overallStatus'] as String?,
      checks: (json['checks'] as List?)?.cast<Map<String, Object?>>(),
    );
  }

  /// Whether the operation was successful
  final bool success;

  /// Status message
  final String message;

  /// Total number of checks performed
  final int? totalChecks;

  /// Number of healthy checks
  final int? healthyChecks;

  /// Number of issues found
  final int? issuesFound;

  /// Overall status
  final String? overallStatus;

  /// List of check results
  final List<Map<String, Object?>>? checks;

  @override
  Map<String, Object?> toJson() => {
        'success': success,
        'message': message,
        if (totalChecks != null) 'totalChecks': totalChecks,
        if (healthyChecks != null) 'healthyChecks': healthyChecks,
        if (issuesFound != null) 'issuesFound': issuesFound,
        if (overallStatus != null) 'overallStatus': overallStatus,
        if (checks != null) 'checks': checks,
      };
}

