import 'package:fly_mcp/fly_mcp.dart';

/// Typed result for fly.echo tool
class EchoResult extends ToolResult {
  EchoResult({required this.message});

  /// Create from JSON Map
  factory EchoResult.fromJson(Map<String, Object?> json) {
    return EchoResult(
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
