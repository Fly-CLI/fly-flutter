import 'package:json_annotation/json_annotation.dart';

import 'package:fly_cli/src/core/templates/versioning/models/template_compatibility.dart';
import 'package:fly_cli/src/core/templates/versioning/utils/version_parser.dart';

import 'template_variable.dart';

part 'template_info.g.dart';

/// Information about a template
/// 
/// Contains template metadata including name, version, description, and optional
/// compatibility requirements. When compatibility data is present, full versioning
/// checks (CLI versions, SDK versions, deprecation, EOL) are performed.
/// 
/// Templates without compatibility data are considered compatible (no constraints).
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class TemplateInfo {
  /// Create a TemplateInfo instance
  const TemplateInfo({
    required this.name,
    required this.version,
    required this.description,
    required this.path,
    required this.minFlutterSdk,
    required this.minDartSdk,
    required this.variables,
    required this.features,
    required this.packages,
    this.compatibility,
  });
  
  /// Create TemplateInfo from YAML map
  /// 
  /// Parses template.yaml content and extracts all template metadata including
  /// optional compatibility requirements. Compatibility parsing is handled internally
  /// and includes compatibility data when present in the YAML.
  factory TemplateInfo.fromYaml(Map<dynamic, dynamic> yaml, String templatePath) {
    // Helper to treat empty strings as null
    String? nonEmptyString(dynamic value) {
      final str = value as String?;
      return (str != null && str.trim().isNotEmpty) ? str : null;
    }
    
    // Parse compatibility data if present
    final compatibility = VersionParser.parseCompatibility(yaml);
    
    return TemplateInfo(
      name: yaml['name'] as String? ?? '',
      version: nonEmptyString(yaml['version']) ?? '1.0.0',
      description: nonEmptyString(yaml['description']) ?? '',
      path: templatePath,
      minFlutterSdk: nonEmptyString(yaml['min_flutter_sdk']) ?? '3.10.0',
      minDartSdk: nonEmptyString(yaml['min_dart_sdk']) ?? '3.0.0',
      variables: _parseVariables(
        (yaml['variables'] as Map<dynamic, dynamic>? ?? {})
            .cast<String, dynamic>(),
      ),
      features: (yaml['features'] as List<dynamic>? ?? []).cast<String>(),
      packages: (yaml['packages'] as List<dynamic>? ?? []).cast<String>(),
      compatibility: compatibility,
    );
  }

  /// Create TemplateInfo from JSON
  factory TemplateInfo.fromJson(Map<String, dynamic> json) =>
      _$TemplateInfoFromJson(json);
  
  /// Template name
  final String name;
  
  /// Template version
  final String version;
  
  /// Template description
  final String description;
  
  /// Path to the template directory
  final String path;
  
  /// Minimum Flutter SDK version required
  @JsonKey(name: 'minFlutterSdk')
  final String minFlutterSdk;
  
  /// Minimum Dart SDK version required
  @JsonKey(name: 'minDartSdk')
  final String minDartSdk;
  
  /// Template variables
  final List<TemplateVariable> variables;
  
  /// List of features included in this template
  final List<String> features;
  
  /// List of packages used by this template
  final List<String> packages;
  
  /// Compatibility requirements (null if not specified)
  /// 
  /// When present, enables full compatibility checking including CLI version
  /// constraints, SDK requirements, deprecation status, and EOL dates.
  /// When null, template is considered compatible (no constraints to enforce).
  final TemplateCompatibility? compatibility;
  
  static List<TemplateVariable> _parseVariables(
    Map<String, dynamic> variables,
  ) =>
      variables.entries.map((entry) {
      final key = entry.key;
      final value = entry.value as Map<dynamic, dynamic>;

      return TemplateVariable(
        name: key,
        type: value['type'] as String? ?? 'string',
        required: value['required'] as bool? ?? false,
        defaultValue: value['default']?.toString(),
        choices: (value['choices'] as List<dynamic>?)?.cast<String>(),
        description: value['description'] as String?,
      );
    }).toList();

  /// Convert TemplateInfo to JSON for caching
  Map<String, dynamic> toJson() => _$TemplateInfoToJson(this);

  @override
  String toString() =>
      'TemplateInfo(name: $name, description: $description, version: $version)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TemplateInfo &&
        other.name == name &&
        other.description == description &&
        other.version == version &&
        other.compatibility == compatibility;
  }

  @override
  int get hashCode => Object.hash(
        name.hashCode,
        description.hashCode,
        version.hashCode,
        compatibility,
      );
}