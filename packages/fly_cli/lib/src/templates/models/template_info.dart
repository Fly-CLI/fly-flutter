import 'template_variable.dart';

/// Information about a template
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
  
  /// Template name
  final String name;
  
  /// Template version
  final String version;
  
  /// Template description
  final String description;
  
  /// Path to the template directory
  final String path;
  
  /// Minimum Flutter SDK version required
  final String minFlutterSdk;
  
  /// Minimum Dart SDK version required
  final String minDartSdk;
  
  /// Template variables
  final List<TemplateVariable> variables;
  
  /// List of features included in this template
  final List<String> features;
  
  /// List of packages used by this template
  final List<String> packages;
  
  factory TemplateInfo.fromYaml(Map<dynamic, dynamic> yaml, String templatePath) => TemplateInfo(
      name: yaml['name'] as String? ?? '',
      version: yaml['version'] as String? ?? '1.0.0',
      description: yaml['description'] as String? ?? '',
      path: templatePath,
      minFlutterSdk: yaml['min_flutter_sdk'] as String? ?? '3.10.0',
      minDartSdk: yaml['min_dart_sdk'] as String? ?? '3.0.0',
      variables: _parseVariables((yaml['variables'] as Map<dynamic, dynamic>? ?? {}).cast<String, dynamic>()),
      features: (yaml['features'] as List<dynamic>? ?? []).cast<String>(),
      packages: (yaml['packages'] as List<dynamic>? ?? []).cast<String>(),
    );
  
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
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'version': version,
      'description': description,
      'path': path,
      'minFlutterSdk': minFlutterSdk,
      'minDartSdk': minDartSdk,
      'variables': variables.map((v) => v.toJson()).toList(),
      'features': features,
      'packages': packages,
    };
  }

  /// Create TemplateInfo from JSON
  factory TemplateInfo.fromJson(Map<String, dynamic> json) {
    return TemplateInfo(
      name: json['name'] as String,
      version: json['version'] as String,
      description: json['description'] as String,
      path: json['path'] as String,
      minFlutterSdk: json['minFlutterSdk'] as String,
      minDartSdk: json['minDartSdk'] as String,
      variables: (json['variables'] as List<dynamic>)
          .map((v) => TemplateVariable.fromJson(v as Map<String, dynamic>))
          .toList(),
      features: (json['features'] as List<dynamic>).cast<String>(),
      packages: (json['packages'] as List<dynamic>).cast<String>(),
    );
  }

  @override
  String toString() {
    return 'TemplateInfo(name: $name, description: $description, version: $version)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TemplateInfo &&
        other.name == name &&
        other.description == description &&
        other.version == version;
  }

  @override
  int get hashCode {
    return name.hashCode ^ description.hashCode ^ version.hashCode;
  }
}