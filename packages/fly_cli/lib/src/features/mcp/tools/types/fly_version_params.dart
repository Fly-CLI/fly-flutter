import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Typed parameters for fly.version tool
class FlyVersionParams extends ToolParameter {
  FlyVersionParams({
    this.checkUpdates,
  });

  /// Create from JSON Map
  factory FlyVersionParams.fromJson(Map<String, Object?> json) {
    return FlyVersionParams(
      checkUpdates: json['checkUpdates'] as bool?,
    );
  }

  /// Whether to check for available updates
  final bool? checkUpdates;

  @override
  Map<String, Object?> toJson() => {
        if (checkUpdates != null) 'checkUpdates': checkUpdates,
      };
}

