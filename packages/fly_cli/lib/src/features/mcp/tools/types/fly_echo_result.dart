import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Typed result for fly.echo tool
class FlyEchoResult extends ToolResult {

   FlyEchoResult({required this.message});

  /// Create from JSON Map
  factory FlyEchoResult.fromJson(Map<String, Object?> json) {
    return FlyEchoResult(
      message: json['message'] as String? ?? '',
    );
  }
  /// Echoed message
  final String message;

  @override
  Map<String, Object?> toJson() => {
        'message': message,
      };
}

