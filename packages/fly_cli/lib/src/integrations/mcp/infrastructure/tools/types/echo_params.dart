import 'package:fly_mcp/fly_mcp.dart';

/// Typed parameters for fly.echo tool
class EchoParams extends ToolParameter {
  EchoParams({required this.message});

  /// Create from JSON Map
  factory EchoParams.fromJson(Map<String, Object?> json) {
    return EchoParams(
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
