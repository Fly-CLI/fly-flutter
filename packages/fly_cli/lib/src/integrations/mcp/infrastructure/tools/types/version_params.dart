import 'package:fly_mcp/fly_mcp.dart';

/// Typed parameters for fly.version tool
class VersionParams extends ToolParameter {
  VersionParams({
    this.checkUpdates,
  });

  /// Create from JSON Map
  factory VersionParams.fromJson(Map<String, Object?> json) {
    return VersionParams(
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
