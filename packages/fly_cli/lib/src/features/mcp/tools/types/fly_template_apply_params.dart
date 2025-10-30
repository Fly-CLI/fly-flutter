import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Typed parameters for fly.template.apply tool
class FlyTemplateApplyParams extends ToolParameter {

   FlyTemplateApplyParams({
    required this.templateId,
    required this.outputDirectory,
    this.variables,
    this.dryRun,
    this.confirm,
  });

  /// Create from JSON Map
  factory FlyTemplateApplyParams.fromJson(Map<String, Object?> json) {
    return FlyTemplateApplyParams(
      templateId: json['templateId'] as String? ?? '',
      outputDirectory: json['outputDirectory'] as String? ?? '',
      variables: json['variables'] as Map<String, dynamic>?,
      dryRun: json['dryRun'] as bool?,
      confirm: json['confirm'] as bool?,
    );
  }
  /// Template ID to apply (required)
  final String templateId;

  /// Output directory (required)
  final String outputDirectory;

  /// Template variables
  final Map<String, dynamic>? variables;

  /// Whether this is a dry run
  final bool? dryRun;

  /// Whether to confirm before applying
  final bool? confirm;

  @override
  Map<String, Object?> toJson() => {
        'templateId': templateId,
        'outputDirectory': outputDirectory,
        if (variables != null) 'variables': variables,
        if (dryRun != null) 'dryRun': dryRun,
        if (confirm != null) 'confirm': confirm,
      };
}

