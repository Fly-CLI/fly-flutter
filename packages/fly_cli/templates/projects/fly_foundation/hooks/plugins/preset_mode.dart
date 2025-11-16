import 'package:mason/mason.dart';

import 'planner.dart';
import 'presets.dart';

/// Planner that derives all internal flags from the preset enum.
class PresetPlanner implements PlannerPlugin {
  @override
  bool canHandle(Vars vars) {
    // Presets are global, so this planner always handles
    return true;
  }

  @override
  Vars derive(Vars vars, Logger logger) {
    final preset = FoundationPreset.fromVars(vars);

    // Derive cross-cutting flags from preset
    return <String, dynamic>{
      'with_tests': preset.withTests,
      'with_docs': preset.withDocs,
      'with_mcp': preset.withMcp,
      'code_generation': preset.codeGeneration,
      'ai_integration': preset.aiIntegration,
      // Service-related flags
      'with_retry_logic': preset.serviceRetry,
      'with_caching': preset.serviceCaching,
      'with_interceptors': preset.serviceInterceptors,
      'with_mocks': preset.serviceMocks,
      // Feature-related flags
      'with_viewmodel': preset.featureViewModel,
      'with_validation': preset.featureValidation,
      'with_navigation': preset.featureNavigation,
      'state_mgmt': preset.stateMgmt,
    };
  }
}

/// Planner that bridges the new public schema to legacy internal names.
/// Derives project_name, feature, component_name, and other mode-specific vars.
class CoreVarsPlanner implements PlannerPlugin {
  @override
  bool canHandle(Vars vars) {
    // Core vars are global, so this planner always handles
    return true;
  }

  @override
  Vars derive(Vars vars, Logger logger) {
    final mode = GenerationMode.fromVars(vars);
    final name = (vars['name'] as String?) ?? 'unnamed';
    final organization = (vars['organization'] as String?) ?? 'com.example';
    final description = (vars['description'] as String?) ?? 'A new Fly foundation project';
    final platforms = (vars['platforms'] as List?)?.map((e) => '$e'.toLowerCase()).toList() ?? ['ios', 'android'];

    final derived = <String, dynamic>{
      // Common defaults
      'template_variant': 'foundation',
      'min_flutter_sdk': '3.10.0',
      'min_dart_sdk': '3.0.0',
      'fly_packages': [
        'fly_core',
        'fly_mvvm',
        'fly_state',
        'fly_navigation',
        'fly_flow_guard',
        'fly_logger',
        'fly_events',
        'fly_networking',
      ],
    };

    switch (mode) {
      case GenerationMode.project:
        // In project mode, name is the project name
        derived['project_name'] = name;
        derived['features'] = ['home'];
        derived['feature'] = 'home';
        derived['component_name'] = 'home';
        break;

      case GenerationMode.feature:
        // In feature mode, name is the feature/component name
        // Convert to snake_case for consistency
        final snakeName = _toSnakeCase(name);
        derived['project_name'] = 'acme_app'; // Default for tests/context
        derived['feature'] = snakeName;
        derived['component_name'] = snakeName;
        // Default screen_type to 'list' if not provided
        derived['screen_type'] = vars['screen_type'] ?? 'list';
        break;

      case GenerationMode.service:
        // In service mode, name is the service/component name
        final snakeName = _toSnakeCase(name);
        derived['project_name'] = 'acme_app'; // Default for tests/context
        derived['feature'] = snakeName;
        derived['component_name'] = snakeName;
        // Default service_type to 'api' if not provided
        derived['service_type'] = vars['service_type'] ?? 'api';
        derived['api_base_url'] = vars['api_base_url'] ?? 'https://api.example.com';
        break;
    }

    return derived;
  }

  /// Simple snake_case conversion helper.
  /// Converts PascalCase or camelCase to snake_case.
  String _toSnakeCase(String input) {
    if (input.isEmpty) return input;
    
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == char.toUpperCase() && i > 0) {
        buffer.write('_');
      }
      buffer.write(char.toLowerCase());
    }
    return buffer.toString();
  }
}

