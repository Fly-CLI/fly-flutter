import 'package:fly_mcp/fly_mcp.dart';

/// Typed parameters for fly.template.list tool
///
/// This tool has no parameters.
class TemplateListParams extends ToolParameter {
  TemplateListParams();

  /// Create from JSON Map
  factory TemplateListParams.fromJson(Map<String, Object?> json) {
    return TemplateListParams();
  }

  @override
  Map<String, Object?> toJson() => {};
}
