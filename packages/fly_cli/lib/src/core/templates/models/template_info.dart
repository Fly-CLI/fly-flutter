import 'package:json_annotation/json_annotation.dart';
import 'template_variable.dart';

part 'template_info.g.dart';

/// Information about a template
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class TemplateInfo {
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
  });
  
  factory TemplateInfo.fromYaml(Map<dynamic, dynamic> yaml, String templatePath) {
    // Helper to treat empty strings as null
    String? nonEmptyString(value) {
      final str = value as String?;
      return (str != null && str.trim().isNotEmpty) ? str : null;
    }
    
    return TemplateInfo(
      name: yaml['name'] as String? ?? '',
      version: nonEmptyString(yaml['version']) ?? '1.0.0',
      description: nonEmptyString(yaml['description']) ?? '',
      path: templatePath,
      minFlutterSdk: nonEmptyString(yaml['min_flutter_sdk']) ?? '3.10.0',
      minDartSdk: nonEmptyString(yaml['min_dart_sdk']) ?? '3.0.0',
      variables: _parseVariables((yaml['variables'] as Map<dynamic, dynamic>? ?? {}).cast<String, dynamic>()),
      features: (yaml['features'] as List<dynamic>? ?? []).cast<String>(),
      packages: (yaml['packages'] as List<dynamic>? ?? []).cast<String>(),
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
  
  static List<TemplateVariable> _parseVariables(Map<String, dynamic> variables) => variables.entries.map((entry) {
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
  String toString() => 'TemplateInfo(name: $name, description: $description, version: $version)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TemplateInfo &&
        other.name == name &&
        other.description == description &&
        other.version == version;
  }

  @override
  int get hashCode => name.hashCode ^ description.hashCode ^ version.hashCode;
}