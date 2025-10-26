/// Information about a template
class TemplateInfo {
  const TemplateInfo({
    required this.name,
    required this.description,
    required this.version,
    this.features = const [],
    this.dependencies = const [],
    this.estimatedFiles = 0,
    this.tags = const [],
  });

  /// Template name
  final String name;

  /// Template description
  final String description;

  /// Template version
  final String version;

  /// List of features included in this template
  final List<String> features;

  /// List of dependencies used by this template
  final List<String> dependencies;

  /// Estimated number of files this template will generate
  final int estimatedFiles;

  /// Tags for categorizing templates
  final List<String> tags;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'version': version,
      'features': features,
      'dependencies': dependencies,
      'estimated_files': estimatedFiles,
      'tags': tags,
    };
  }

  /// Create from JSON
  factory TemplateInfo.fromJson(Map<String, dynamic> json) {
    return TemplateInfo(
      name: json['name'] as String,
      description: json['description'] as String,
      version: json['version'] as String,
      features: (json['features'] as List<dynamic>?)?.cast<String>() ?? [],
      dependencies: (json['dependencies'] as List<dynamic>?)?.cast<String>() ?? [],
      estimatedFiles: json['estimated_files'] as int? ?? 0,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
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
