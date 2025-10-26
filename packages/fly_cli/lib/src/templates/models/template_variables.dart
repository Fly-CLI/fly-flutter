/// Variables used in template generation
class TemplateVariables {
  const TemplateVariables({
    this.projectName = '',
    this.organization = 'com.example',
    this.platforms = const ['ios', 'android'],
    this.screens = const [],
    this.services = const [],
    this.customVariables = const {},
  });

  /// Project name
  final String projectName;

  /// Organization identifier
  final String organization;

  /// Target platforms
  final List<String> platforms;

  /// Screens to generate
  final List<ScreenVariable> screens;

  /// Services to generate
  final List<ServiceVariable> services;

  /// Custom variables
  final Map<String, dynamic> customVariables;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'project_name': projectName,
      'organization': organization,
      'platforms': platforms,
      'screens': screens.map((e) => e.toJson()).toList(),
      'services': services.map((e) => e.toJson()).toList(),
      'custom_variables': customVariables,
    };
  }

  /// Create from JSON
  factory TemplateVariables.fromJson(Map<String, dynamic> json) {
    return TemplateVariables(
      projectName: json['project_name'] as String? ?? '',
      organization: json['organization'] as String? ?? 'com.example',
      platforms: (json['platforms'] as List<dynamic>?)?.cast<String>() ?? ['ios', 'android'],
      screens: (json['screens'] as List<dynamic>?)
          ?.map((e) => ScreenVariable.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      services: (json['services'] as List<dynamic>?)
          ?.map((e) => ServiceVariable.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      customVariables: Map<String, dynamic>.from(json['custom_variables'] as Map<String, dynamic>? ?? {}),
    );
  }

  /// Create a copy with updated values
  TemplateVariables copyWith({
    String? projectName,
    String? organization,
    List<String>? platforms,
    List<ScreenVariable>? screens,
    List<ServiceVariable>? services,
    Map<String, dynamic>? customVariables,
  }) {
    return TemplateVariables(
      projectName: projectName ?? this.projectName,
      organization: organization ?? this.organization,
      platforms: platforms ?? this.platforms,
      screens: screens ?? this.screens,
      services: services ?? this.services,
      customVariables: customVariables ?? this.customVariables,
    );
  }

  @override
  String toString() {
    return 'TemplateVariables(projectName: $projectName, organization: $organization, platforms: $platforms)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TemplateVariables &&
        other.projectName == projectName &&
        other.organization == organization &&
        other.platforms == platforms;
  }

  @override
  int get hashCode {
    return projectName.hashCode ^ organization.hashCode ^ platforms.hashCode;
  }

  /// Convert to Mason variables format
  Map<String, dynamic> toMasonVars() {
    return {
      'project_name': projectName,
      'organization': organization,
      'platforms': platforms,
      'screens': screens.map((e) => e.toJson()).toList(),
      'services': services.map((e) => e.toJson()).toList(),
      ...customVariables,
    };
  }
}

/// Screen variable for template generation
class ScreenVariable {
  const ScreenVariable({
    required this.name,
    required this.type,
    this.title = '',
    this.description = '',
    this.features = const [],
  });

  /// Screen name
  final String name;

  /// Screen type (auth, list, detail, form, etc.)
  final String type;

  /// Screen title
  final String title;

  /// Screen description
  final String description;

  /// Features to include in this screen
  final List<String> features;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'title': title,
      'description': description,
      'features': features,
    };
  }

  /// Create from JSON
  factory ScreenVariable.fromJson(Map<String, dynamic> json) {
    return ScreenVariable(
      name: json['name'] as String,
      type: json['type'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      features: (json['features'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  @override
  String toString() {
    return 'ScreenVariable(name: $name, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScreenVariable &&
        other.name == name &&
        other.type == type;
  }

  @override
  int get hashCode {
    return name.hashCode ^ type.hashCode;
  }
}

/// Service variable for template generation
class ServiceVariable {
  const ServiceVariable({
    required this.name,
    this.apiBase = '',
    this.description = '',
    this.endpoints = const [],
    this.authentication = '',
  });

  /// Service name
  final String name;

  /// API base URL
  final String apiBase;

  /// Service description
  final String description;

  /// API endpoints
  final List<String> endpoints;

  /// Authentication method
  final String authentication;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'api_base': apiBase,
      'description': description,
      'endpoints': endpoints,
      'authentication': authentication,
    };
  }

  /// Create from JSON
  factory ServiceVariable.fromJson(Map<String, dynamic> json) {
    return ServiceVariable(
      name: json['name'] as String,
      apiBase: json['api_base'] as String? ?? '',
      description: json['description'] as String? ?? '',
      endpoints: (json['endpoints'] as List<dynamic>?)?.cast<String>() ?? [],
      authentication: json['authentication'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'ServiceVariable(name: $name, apiBase: $apiBase)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceVariable &&
        other.name == name &&
        other.apiBase == apiBase;
  }

  @override
  int get hashCode {
    return name.hashCode ^ apiBase.hashCode;
  }
}
