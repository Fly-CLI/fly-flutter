import 'package:mason/mason.dart';

import 'foundation_model.dart';

/// Abstract interface for template modules that can be composed together.
///
/// Modules represent self-contained units of template generation that can be
/// combined to build projects incrementally.
abstract class TemplateModule {
  /// Unique identifier for the module
  String get name;

  /// Determines if this module can be composed with the given mode and variables
  bool canComposeWith(GenerationMode mode, DerivedTemplateVariables vars);

  /// List of template directory paths relative to __brick__/
  ///
  /// These paths will be scanned for template files to include in generation.
  List<String> get templatePaths;

  /// Module-specific variable derivations
  ///
  /// Returns additional variables that should be added to the template context
  /// when this module is active.
  Map<String, dynamic> getModuleVars(DerivedTemplateVariables base);
}

/// Project module - includes base foundation classes and full project scaffolding.
///
/// This module is responsible for:
/// - Base foundation classes (base_screen.dart, base_view_model.dart)
/// - Project root files (main.dart, pubspec.yaml, etc.)
/// - Shared infrastructure (navigation, themes, localization)
class ProjectModule implements TemplateModule {
  @override
  String get name => 'project';

  @override
  bool canComposeWith(GenerationMode mode, DerivedTemplateVariables vars) {
    return mode == GenerationMode.project;
  }

  @override
  List<String> get templatePaths => [
        'modes/project/', // Includes lib/core/foundation/ (base classes)
      ];

  @override
  Map<String, dynamic> getModuleVars(DerivedTemplateVariables base) {
    return {
      'includes_base_foundation': true,
      'project_structure': 'full',
      'assumes_existing_project': false,
    };
  }
}

/// Feature module - standalone component for generating features.
///
/// This module assumes an existing project structure with base classes already present.
class FeatureModule implements TemplateModule {
  final String? feature;

  FeatureModule({this.feature});

  @override
  String get name => 'feature';

  @override
  bool canComposeWith(GenerationMode mode, DerivedTemplateVariables vars) {
    return mode == GenerationMode.feature ||
        (mode == GenerationMode.project && vars.feature != null);
  }

  @override
  List<String> get templatePaths => [
        'modes/feature/',
      ];

  @override
  Map<String, dynamic> getModuleVars(DerivedTemplateVariables base) {
    return {
      'assumes_existing_project': true,
      'feature_name': feature ?? base.feature ?? 'home',
    };
  }
}

/// Service module - standalone component for generating services.
///
/// This module assumes an existing project structure with base classes already present.
class ServiceModule implements TemplateModule {
  final String? serviceName;

  ServiceModule({this.serviceName});

  @override
  String get name => 'service';

  @override
  bool canComposeWith(GenerationMode mode, DerivedTemplateVariables vars) {
    return mode == GenerationMode.service;
  }

  @override
  List<String> get templatePaths => [
        'modes/service/',
      ];

  @override
  Map<String, dynamic> getModuleVars(DerivedTemplateVariables base) {
    return {
      'assumes_existing_project': true,
      'service_name': serviceName ?? base.componentName ?? 'service',
    };
  }
}

/// Provider module - standalone component for generating providers.
///
/// This module assumes an existing project structure.
class ProviderModule implements TemplateModule {
  @override
  String get name => 'provider';

  @override
  bool canComposeWith(GenerationMode mode, DerivedTemplateVariables vars) {
    // Provider module can be used in any mode, but typically standalone
    return true;
  }

  @override
  List<String> get templatePaths => [
        'modes/provider/',
      ];

  @override
  Map<String, dynamic> getModuleVars(DerivedTemplateVariables base) {
    return {
      'assumes_existing_project': true,
    };
  }
}

