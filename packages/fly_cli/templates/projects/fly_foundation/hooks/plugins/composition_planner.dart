import 'package:mason/mason.dart';

import 'foundation_model.dart';
import 'planner.dart';
import 'composition.dart';

/// Unified composition planner that replaces mode-specific planners.
///
/// This planner determines which modules should be active based on the
/// generation mode and composes them together.
class CompositionPlanner implements PlannerPlugin {
  final List<TemplateModule> _modules = [
    ProjectModule(),
    FeatureModule(),
    ServiceModule(),
    ProviderModule(),
  ];

  @override
  bool canHandle(BaseTemplateVariables base) {
    return true; // Always handles - determines composition
  }

  @override
  DerivedTemplateVariables derive(
    BaseTemplateVariables base,
    DerivedTemplateVariables acc,
    Logger logger,
  ) {
    final activeModules = <TemplateModule>[];
    final moduleVars = <String, dynamic>{};

    // Compose based on generation_mode
    switch (base.generationMode) {
      case GenerationMode.project:
        // Project mode includes base foundation + project scaffolding
        final projectModule = ProjectModule();
        activeModules.add(projectModule);
        moduleVars.addAll(projectModule.getModuleVars(acc));

        // Optionally include initial features as part of project creation
        // Note: Features are typically added via separate generation commands,
        // but we support initial features during project creation
        if (base.name.isNotEmpty) {
          // For project mode, the first feature is typically 'home'
          // This is handled by NamingPlanner which sets feature: 'home'
        }
        break;

      case GenerationMode.feature:
        // Feature mode is standalone - assumes existing project
        final featureModule = FeatureModule(feature: base.name);
        activeModules.add(featureModule);
        moduleVars.addAll(featureModule.getModuleVars(acc));
        break;

      case GenerationMode.service:
        // Service mode is standalone - assumes existing project
        final serviceModule = ServiceModule(serviceName: base.name);
        activeModules.add(serviceModule);
        moduleVars.addAll(serviceModule.getModuleVars(acc));
        break;
    }

    // Build module information for derived variables
    final moduleNames = activeModules.map((m) => m.name).toList();
    final moduleTemplatePaths = activeModules
        .expand((m) => m.templatePaths)
        .toSet()
        .toList();

    // Merge module vars into the derived variables
    // Note: We maintain backward compatibility by still setting isProject/isFeature/isService
    final includesBaseFoundation = base.generationMode == GenerationMode.project;

    return acc.copyWith(
      // Maintain backward compatibility flags
      isProject: base.generationMode == GenerationMode.project,
      isFeature: base.generationMode == GenerationMode.feature,
      isService: base.generationMode == GenerationMode.service,
      activeMode: base.generationMode,
      // Add module composition information
      // These will be stored in moduleVars map for template access
    );
  }

  /// Get active modules for a given base configuration
  List<TemplateModule> getActiveModules(
    BaseTemplateVariables base,
    DerivedTemplateVariables acc,
  ) {
    final activeModules = <TemplateModule>[];

    switch (base.generationMode) {
      case GenerationMode.project:
        activeModules.add(ProjectModule());
        break;
      case GenerationMode.feature:
        activeModules.add(FeatureModule(feature: base.name));
        break;
      case GenerationMode.service:
        activeModules.add(ServiceModule(serviceName: base.name));
        break;
    }

    return activeModules;
  }

  /// Get all template paths from active modules
  List<String> getTemplatePaths(
    BaseTemplateVariables base,
    DerivedTemplateVariables acc,
  ) {
    final modules = getActiveModules(base, acc);
    return modules
        .expand((m) => m.templatePaths)
        .toSet()
        .toList();
  }

  /// Get all module variables from active modules
  Map<String, dynamic> getModuleVariables(
    BaseTemplateVariables base,
    DerivedTemplateVariables acc,
  ) {
    final modules = getActiveModules(base, acc);
    final moduleVars = <String, dynamic>{};

    for (final module in modules) {
      moduleVars.addAll(module.getModuleVars(acc));
    }

    // Add module metadata
    moduleVars['active_modules'] = modules.map((m) => m.name).toList();
    moduleVars['module_template_paths'] = getTemplatePaths(base, acc);

    return moduleVars;
  }
}

