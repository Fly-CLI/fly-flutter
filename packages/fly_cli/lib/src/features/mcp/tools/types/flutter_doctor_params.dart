import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Typed parameters for flutter.doctor tool
/// 
/// This tool has no parameters.
class FlutterDoctorParams extends ToolParameter {
   FlutterDoctorParams();

  /// Create from JSON Map
  factory FlutterDoctorParams.fromJson(Map<String, Object?> json) {
    return  FlutterDoctorParams();
  }

  @override
  Map<String, Object?> toJson() => {};
}

