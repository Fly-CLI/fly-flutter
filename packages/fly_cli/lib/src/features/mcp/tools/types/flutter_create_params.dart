import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Typed parameters for flutter.create tool
class FlutterCreateParams extends ToolParameter {

   FlutterCreateParams({
    required this.projectName,
    this.template,
    this.organization,
    this.platforms,
    this.outputDirectory,
    this.confirm,
  });

  /// Create from JSON Map
  factory FlutterCreateParams.fromJson(Map<String, Object?> json) {
    return FlutterCreateParams(
      projectName: json['projectName'] as String? ?? '',
      template: json['template'] as String?,
      organization: json['organization'] as String?,
      platforms: (json['platforms'] as List?)?.cast<String>(),
      outputDirectory: json['outputDirectory'] as String?,
      confirm: json['confirm'] as bool?,
    );
  }
  /// Project name (required)
  final String projectName;

  /// Template to use
  final String? template;

  /// Organization identifier
  final String? organization;

  /// Target platforms
  final List<String>? platforms;

  /// Output directory
  final String? outputDirectory;

  /// Whether to confirm before creating
  final bool? confirm;

  @override
  Map<String, Object?> toJson() => {
        'projectName': projectName,
        if (template != null) 'template': template,
        if (organization != null) 'organization': organization,
        if (platforms != null) 'platforms': platforms,
        if (outputDirectory != null) 'outputDirectory': outputDirectory,
        if (confirm != null) 'confirm': confirm,
      };
}

