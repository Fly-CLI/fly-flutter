import 'package:fly_mcp/fly_mcp.dart';

/// Typed parameters for fly.generate.project tool
class FlyGenerateProjectParams extends ToolParameter {
  FlyGenerateProjectParams({
    required this.projectName,
    this.template,
    this.organization,
    this.description,
    this.platforms,
    this.features,
    this.outputDir,
  });

  /// Create from JSON Map
  factory FlyGenerateProjectParams.fromJson(Map<String, Object?> json) {
    return FlyGenerateProjectParams(
      projectName: json['projectName'] as String? ?? '',
      template: json['template'] as String?,
      organization: json['organization'] as String?,
      description: json['description'] as String?,
      platforms: (json['platforms'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      features: (json['features'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      outputDir: json['outputDir'] as String?,
    );
  }

  /// Project name (required)
  final String projectName;

  /// Template to use (defaults to 'fly_foundation')
  final String? template;

  /// Organization identifier (defaults to 'com.example')
  final String? organization;

  /// Project description
  final String? description;

  /// Target platforms (defaults to ['ios', 'android'])
  final List<String>? platforms;

  /// Initial features to scaffold
  final List<String>? features;

  /// Output directory where project will be created
  final String? outputDir;

  @override
  Map<String, Object?> toJson() => {
        'projectName': projectName,
        if (template != null) 'template': template,
        if (organization != null) 'organization': organization,
        if (description != null) 'description': description,
        if (platforms != null) 'platforms': platforms,
        if (features != null) 'features': features,
        if (outputDir != null) 'outputDir': outputDir,
      };
}

