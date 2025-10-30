import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Template information
class TemplateInfo {
  const TemplateInfo({
    required this.name,
    required this.description,
    required this.version,
    required this.features,
    this.minFlutterSdk,
    this.minDartSdk,
  });

  factory TemplateInfo.fromJson(Map<String, Object?> json) {
    return TemplateInfo(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      version: json['version'] as String? ?? '',
      features: (json['features'] as List?)?.cast<String>() ?? [],
      minFlutterSdk: json['minFlutterSdk'] as String?,
      minDartSdk: json['minDartSdk'] as String?,
    );
  }

  final String name;
  final String description;
  final String version;
  final List<String> features;
  final String? minFlutterSdk;
  final String? minDartSdk;

  Map<String, Object?> toJson() => {
    'name': name,
    'description': description,
    'version': version,
    'features': features,
    if (minFlutterSdk != null) 'minFlutterSdk': minFlutterSdk,
    if (minDartSdk != null) 'minDartSdk': minDartSdk,
  };
}

/// Typed result for fly.template.list tool
class FlyTemplateListResult extends ToolResult {
  FlyTemplateListResult({required this.templates});

  /// Create from JSON Map
  factory FlyTemplateListResult.fromJson(Map<String, Object?> json) {
    final templatesList = json['templates'] as List?;
    return FlyTemplateListResult(
      templates: templatesList != null
          ? templatesList
                .map((t) => TemplateInfo.fromJson(t as Map<String, Object?>))
                .toList()
          : [],
    );
  }

  /// List of available templates
  final List<TemplateInfo> templates;

  @override
  Map<String, Object?> toJson() => {
    'templates': templates.map((t) => t.toJson()).toList(),
  };
}
