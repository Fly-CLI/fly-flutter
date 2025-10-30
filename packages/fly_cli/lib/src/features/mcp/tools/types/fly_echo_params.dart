import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Typed parameters for fly.echo tool
class FlyEchoParams extends ToolParameter {

   FlyEchoParams({required this.message});

  /// Create from JSON Map
  factory FlyEchoParams.fromJson(Map<String, Object?> json) {
    return FlyEchoParams(
      message: json['message'] as String? ?? '',
    );
  }
  /// Message to echo back
  final String message;

  @override
  Map<String, Object?> toJson() => {
        'message': message,
      };
}

