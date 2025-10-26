import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

import '../templates/template_manager.dart';

/// Exception thrown when manifest parsing fails
class ManifestException implements Exception {

  ManifestException(this.message);
  final String message;

  @override
  String toString() => 'ManifestException: $message';
}

/// Configuration for a screen in the manifest
class ScreenConfig {

  ScreenConfig({
    required this.name,
    this.type,
    this.features = const [],
  });
  final String name;
  final String? type;
  final List<String> features;

  /// Parse ScreenConfig from YAML map
  static ScreenConfig fromYaml(Map yaml) {
    if (!yaml.containsKey('name')) {
      throw ManifestException('Screen missing required field: name');
    }

    final name = yaml['name'] as String;
    if (!ProjectManifest._isValidName(name)) {
      throw ManifestException('Invalid screen name: $name');
    }

    final type = yaml['type'] as String?;
    final features = (yaml['features'] as List?)?.cast<String>() ?? [];

    return ScreenConfig(
      name: name,
      type: type,
      features: features,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (type != null) 'type': type,
    'features': features,
  };
}

/// Configuration for a service in the manifest
class ServiceConfig {

  ServiceConfig({
    required this.name,
    this.apiBase,
    this.type,
    this.features = const [],
  });
  final String name;
  final String? apiBase;
  final String? type;
  final List<String> features;

  /// Parse ServiceConfig from YAML map
  static ServiceConfig fromYaml(Map yaml) {
    if (!yaml.containsKey('name')) {
      throw ManifestException('Service missing required field: name');
    }

    final name = yaml['name'] as String;
    if (!ProjectManifest._isValidName(name)) {
      throw ManifestException('Invalid service name: $name');
    }

    final apiBase = yaml['api_base'] as String?;
    final type = yaml['type'] as String?;
    final features = (yaml['features'] as List?)?.cast<String>() ?? [];

    return ServiceConfig(
      name: name,
      apiBase: apiBase,
      type: type,
      features: features,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (apiBase != null) 'api_base': apiBase,
    if (type != null) 'type': type,
    'features': features,
  };
}

/// Configuration map for service generation with Mason brick
class ServiceConfigMap {
  /// Create ServiceConfigMap from ServiceConfig
  factory ServiceConfigMap.fromServiceConfig(ServiceConfig serviceConfig) =>
      ServiceConfigMap(
        serviceName: serviceConfig.name,
        feature: 'core',
        // Default feature
        serviceType: serviceConfig.type ?? 'api',
        withTests: serviceConfig.features.contains('tests'),
        withMocks: serviceConfig.features.contains('mocks'),
        withInterceptors: serviceConfig.features.contains('interceptors'),
        baseUrl: serviceConfig.apiBase ?? 'https://api.example.com',
      );

  /// Create ServiceConfigMap from JSON map
  factory ServiceConfigMap.fromJson(Map<String, dynamic> json) =>
      ServiceConfigMap(
        serviceName: json['service_name'] as String,
        feature: json['feature'] as String,
        serviceType: json['service_type'] as String,
        withTests: json['with_tests'] as bool,
        withMocks: json['with_mocks'] as bool,
        withInterceptors: json['with_interceptors'] as bool,
        baseUrl: json['base_url'] as String,
      );

  /// Create from JSON string
  factory ServiceConfigMap.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return ServiceConfigMap.fromJson(json);
  }

  const ServiceConfigMap({
    required this.serviceName,
    required this.feature,
    required this.serviceType,
    required this.withTests,
    required this.withMocks,
    required this.withInterceptors,
    required this.baseUrl,
  });

  final String serviceName;
  final String feature;
  final String serviceType;
  final bool withTests;
  final bool withMocks;
  final bool withInterceptors;
  final String baseUrl;

  /// Convert to JSON map
  Map<String, dynamic> toJson() => {
    'service_name': serviceName,
    'feature': feature,
    'service_type': serviceType,
    'with_tests': withTests,
    'with_mocks': withMocks,
    'with_interceptors': withInterceptors,
    'base_url': baseUrl,
  };

  /// Convert to JSON string
  String toJsonString() => jsonEncode(toJson());

  @override
  String toString() =>
      'ServiceConfigMap(serviceName: $serviceName, feature: $feature, serviceType: $serviceType, withTests: $withTests, withMocks: $withMocks, withInterceptors: $withInterceptors, baseUrl: $baseUrl)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ServiceConfigMap &&
              runtimeType == other.runtimeType &&
              serviceName == other.serviceName &&
              feature == other.feature &&
              serviceType == other.serviceType &&
              withTests == other.withTests &&
              withMocks == other.withMocks &&
              withInterceptors == other.withInterceptors &&
              baseUrl == other.baseUrl;

  @override
  int get hashCode =>
      serviceName.hashCode ^
      feature.hashCode ^
      serviceType.hashCode ^
      withTests.hashCode ^
      withMocks.hashCode ^
      withInterceptors.hashCode ^
      baseUrl.hashCode;
}

/// Configuration section of the manifest
class ManifestConfig {

  const ManifestConfig({
    this.minSdkVersion,
    this.targetSdkVersion,
    this.iosDeploymentTarget,
    this.generateTests = true,
    this.generateDocs = false,
    this.generateContext = true,
    this.includeExamples = false,
  });
  final int? minSdkVersion;
  final int? targetSdkVersion;
  final String? iosDeploymentTarget;
  final bool generateTests;
  final bool generateDocs;
  final bool generateContext;
  final bool includeExamples;

  /// Parse ManifestConfig from YAML map
  static ManifestConfig fromYaml(Map? yaml) {
    if (yaml == null) {
      return const ManifestConfig();
    }

    final codeGen = yaml['code_generation'] as Map?;
    final aiIntegration = yaml['ai_integration'] as Map?;

    return ManifestConfig(
      minSdkVersion: yaml['min_sdk_version'] as int?,
      targetSdkVersion: yaml['target_sdk_version'] as int?,
      iosDeploymentTarget: yaml['ios_deployment_target'] as String?,
      generateTests: codeGen?['generate_tests'] as bool? ?? true,
      generateDocs: codeGen?['generate_docs'] as bool? ?? false,
      generateContext: aiIntegration?['generate_context'] as bool? ?? true,
      includeExamples: aiIntegration?['include_examples'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    if (minSdkVersion != null) 'min_sdk_version': minSdkVersion,
    if (targetSdkVersion != null) 'target_sdk_version': targetSdkVersion,
    if (iosDeploymentTarget != null) 'ios_deployment_target': iosDeploymentTarget,
    'code_generation': {
      'generate_tests': generateTests,
      'generate_docs': generateDocs,
    },
    'ai_integration': {
      'generate_context': generateContext,
      'include_examples': includeExamples,
    },
  };
}

/// Main project manifest class
class ProjectManifest {

  ProjectManifest({
    required this.name,
    required this.template,
    required this.organization,
    this.description,
    this.platforms = const ['ios', 'android'],
    this.screens = const [],
    this.services = const [],
    this.packages = const [],
    this.config = const ManifestConfig(),
  });
  final String name;
  final String template;
  final String organization;
  final String? description;
  final List<String> platforms;
  final List<ScreenConfig> screens;
  final List<ServiceConfig> services;
  final List<String> packages;
  final ManifestConfig config;

  /// Parse manifest from YAML file
  static Future<ProjectManifest> fromFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw ManifestException('Manifest file not found: $path');
    }

    try {
      final content = await file.readAsString();
      final yaml = loadYaml(content) as Map;

      return ProjectManifest.fromYaml(yaml);
    } catch (e) {
      throw ManifestException('Failed to parse manifest file: $e');
    }
  }

  /// Parse manifest from YAML map
  static ProjectManifest fromYaml(Map yaml) {
    // Validate required fields
    if (!yaml.containsKey('name')) {
      throw ManifestException('Missing required field: name');
    }
    if (!yaml.containsKey('template')) {
      throw ManifestException('Missing required field: template');
    }

    // Parse and validate name
    final name = yaml['name'] as String;
    if (!_isValidProjectName(name)) {
      throw ManifestException('Invalid project name: $name');
    }

    // Parse template
    final template = yaml['template'] as String;
    if (!['minimal', 'riverpod'].contains(template)) {
      throw ManifestException('Invalid template: $template. Must be "minimal" or "riverpod"');
    }

    // Parse organization
    final organization = yaml['organization'] as String? ?? 'com.example';

    // Parse platforms
    final platforms = (yaml['platforms'] as List?)?.cast<String>() ?? ['ios', 'android'];
    final validPlatforms = ['ios', 'android', 'web', 'macos', 'windows', 'linux'];
    for (final platform in platforms) {
      if (!validPlatforms.contains(platform)) {
        throw ManifestException('Invalid platform: $platform. Must be one of: ${validPlatforms.join(', ')}');
      }
    }

    // Parse screens
    final screens = <ScreenConfig>[];
    final screensList = yaml['screens'] as List?;
    if (screensList != null) {
      for (final screenYaml in screensList) {
        if (screenYaml is Map) {
          screens.add(ScreenConfig.fromYaml(screenYaml));
        }
      }
    }

    // Parse services
    final services = <ServiceConfig>[];
    final servicesList = yaml['services'] as List?;
    if (servicesList != null) {
      for (final serviceYaml in servicesList) {
        if (serviceYaml is Map) {
          services.add(ServiceConfig.fromYaml(serviceYaml));
        }
      }
    }

    // Parse packages
    final packages = (yaml['packages'] as List?)?.cast<String>() ?? [];

    // Parse config
    final config = ManifestConfig.fromYaml(yaml['config'] as Map?);

    return ProjectManifest(
      name: name,
      template: template,
      organization: organization,
      description: yaml['description'] as String?,
      platforms: platforms,
      screens: screens,
      services: services,
      packages: packages,
      config: config,
    );
  }

  /// Convert to TemplateVariables for project generation
  TemplateVariables toTemplateVariables() => TemplateVariables(
    projectName: name,
    organization: organization,
    platforms: platforms,
    description: description ?? 'A new Flutter project',
    features: _extractFeatures(),
  );

  /// Extract features from screens and services
  List<String> _extractFeatures() {
    final features = <String>{};

    for (final screen in screens) {
      features.addAll(screen.features);
    }

    for (final service in services) {
      features.addAll(service.features);
    }

    return features.toList();
  }

  /// Convert to JSON for debugging/testing
  Map<String, dynamic> toJson() => {
    'name': name,
    'template': template,
    'organization': organization,
    if (description != null) 'description': description,
    'platforms': platforms,
    'screens': screens.map((s) => s.toJson()).toList(),
    'services': services.map((s) => s.toJson()).toList(),
    'packages': packages,
    'config': config.toJson(),
  };

  /// Validate project name format
  static bool _isValidProjectName(String name) {
    final regex = RegExp(r'^[a-z][a-z0-9_]*$');
    return regex.hasMatch(name) && name.length <= 50;
  }

  /// Validate name format (for screens/services)
  static bool _isValidName(String name) {
    final regex = RegExp(r'^[a-z][a-z0-9_]*$');
    return regex.hasMatch(name) && name.length <= 50;
  }
}
