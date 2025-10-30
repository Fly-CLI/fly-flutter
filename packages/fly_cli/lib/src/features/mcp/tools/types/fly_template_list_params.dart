import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Typed parameters for fly.template.list tool
/// 
/// This tool has no parameters.
class FlyTemplateListParams extends ToolParameter {
   FlyTemplateListParams();

  /// Create from JSON Map
  factory FlyTemplateListParams.fromJson(Map<String, Object?> json) {
    return FlyTemplateListParams();
  }

  @override
  Map<String, Object?> toJson() => {};
}

