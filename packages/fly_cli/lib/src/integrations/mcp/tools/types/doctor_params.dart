import 'package:fly_mcp/fly_mcp.dart';

/// Typed parameters for fly.doctor tool
class DoctorParams extends ToolParameter {
  DoctorParams({
    this.fix,
  });

  /// Create from JSON Map
  factory DoctorParams.fromJson(Map<String, Object?> json) {
    return DoctorParams(
      fix: json['fix'] as bool?,
    );
  }

  /// Whether to attempt to fix common issues automatically
  final bool? fix;

  @override
  Map<String, Object?> toJson() => {
        if (fix != null) 'fix': fix,
      };
}
