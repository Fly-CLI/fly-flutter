# Composition-Based Mode Management Architecture Plan

## Executive Summary

This document outlines a comprehensive plan to refactor the `fly_foundation` Mason brick template to
adopt a **composition-based architecture** instead of path-level conditionals. The goal is to
separate generation modes (project, feature, service, provider) into well-defined, composable
modules that can be combined incrementally, improving maintainability, testability, and
extensibility.

**Key Principle:** The base foundation classes (`base_screen.dart`, `base_view_model.dart`) are part
of the project mode and reside directly in `modes/project/lib/core/foundation/`, not in a separate
base module. Feature and service modes are standalone components that assume an existing project
structure.

---

## Current State Analysis

### Current Architecture

**Template Structure:**

- Single `__brick__/` directory with path-level conditionals (`{{#is_project}}`, `{{#is_feature}}`,
  `{{#is_service}}`)
- Mode switching via `generation_mode` enum with derived boolean flags (`isProject`, `isFeature`,
  `isService`)
- Planner plugins derive flags, but templates still rely heavily on conditionals
- Mixed concerns: project scaffolding, feature generation, and service generation share the same
  template structure

**Identified Issues:**

1. **Path conditionals create maintenance overhead** - Template structure is difficult to navigate
   and understand
2. **Tight coupling between modes** - Changes to one mode can inadvertently affect others
3. **No incremental composition** - Cannot easily add features/services to an existing project
   incrementally
4. **Template structure doesn't reflect modularity** - The directory layout doesn't clearly show the
   separation of concerns

---

## Proposed Architecture

### 1. Modular Template Structure

Reorganize the template directory to clearly separate concerns:

```
__brick__/
├── modes/
│   ├── project/                   # Full project scaffolding (includes base foundation)
│   │   ├── analysis_options.yaml
│   │   ├── build.yaml
│   │   ├── l10n.yaml
│   │   ├── pubspec.yaml
│   │   ├── main.dart
│   │   ├── README.md
│   │   ├── .ai/
│   │   │   └── project_context.md
│   │   ├── .mcp/
│   │   │   └── fly_mcp.yaml
│   │   └── lib/
│   │       ├── core/              # Base foundation classes (part of project)
│   │       │   └── foundation/
│   │       │       └── screen/
│   │       │           ├── base_screen.dart
│   │       │           └── base_view_model.dart
│   │       ├── shared/
│   │       │   ├── navigation/
│   │       │   │   ├── app_navigator.dart
│   │       │   │   ├── app_router.dart
│   │       │   │   └── feature_screen_type.dart
│   │       │   └── themes/
│   │       │       └── app_theme.dart
│   │       └── l10n/
│   │           └── app_en.arb
│   │
│   ├── feature/                   # Standalone feature generation
│   │   ├── lib/
│   │   │   └── features/
│   │   │       └── {{feature}}/
│   │   │           └── presentation/
│   │   │               ├── screen/
│   │   │               │   ├── {{component_name}}_screen.dart
│   │   │               │   └── {{component_name}}_view_model.dart
│   │   │               └── widgets/
│   │   ├── docs/
│   │   │   └── features/
│   │   │       └── {{component_name}}.md
│   │   └── test/
│   │       └── features/
│   │           └── {{feature}}/
│   │               └── {{component_name}}_screen_test.dart
│   │
│   ├── service/                   # Standalone service generation
│   │   ├── lib/
│   │   │   └── core/
│   │   │       └── services/
│   │   │           └── {{feature}}/
│   │   │               └── {{component_name}}_service.dart
│   │   ├── docs/
│   │   │   └── services/
│   │   │       └── {{component_name}}_service.md
│   │   └── test/
│   │       └── core/
│   │           └── services/
│   │               └── {{feature}}/
│   │                   ├── {{component_name}}_service_test.dart
│   │                   └── mocks/
│   │
│   └── provider/                  # Standalone provider generation
│       └── lib/
│           └── shared/
│               └── providers/
│
└── modes/
    └── service/
        └── common/
            └── services/          # Service partials (used by service templates)
                ├── caching_field.dart
                ├── caching_get.dart
                ├── caching_set.dart
                ├── interceptors_run.dart
                ├── interceptors_types.dart
                └── retry_execute.dart
```

### 2. Composition System

#### 2.1 Module Registry

Create a module registry that defines composable units:

```dart
// hooks/plugins/composition.dart

abstract class TemplateModule {
  /// Unique identifier for the module
  String get name;

  /// Determines if this module can be composed with the given mode and variables
  bool canComposeWith(GenerationMode mode, DerivedTemplateVariables vars);

  /// List of template directory paths relative to __brick__/
  List<String> get templatePaths;

  /// Module-specific variable derivations
  Map<String, dynamic> getModuleVars(DerivedTemplateVariables base);
}

/// Project module - includes base foundation classes
class ProjectModule implements TemplateModule {
  @override
  String get name => 'project';

  @override
  bool canComposeWith(GenerationMode mode, DerivedTemplateVariables vars) {
    return mode == GenerationMode.project;
  }

  @override
  List<String> get templatePaths =>
      [
        'modes/project/', // Includes lib/core/foundation/ (base classes)
      ];

  @override
  Map<String, dynamic> getModuleVars(DerivedTemplateVariables base) {
    return {
      'includes_base_foundation': true,
      'project_structure': 'full',
    };
  }
}

/// Feature module - standalone component
class FeatureModule implements TemplateModule {
  final String? feature;

  FeatureModule({this.feature});

  @override
  String get name => 'feature';

  @override
  bool canComposeWith(GenerationMode mode, DerivedTemplateVariables vars) {
    return mode == GenerationMode.feature ||
        (mode == GenerationMode.project && vars.initialFeatures.isNotEmpty);
  }

  @override
  List<String> get templatePaths =>
      [
        'modes/feature/',
      ];

  @override
  Map<String, dynamic> getModuleVars(DerivedTemplateVariables base) {
    return {
      'assumes_existing_project': true,
      'feature_name': feature ?? base.name,
    };
  }
}

/// Service module - standalone component
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
  List<String> get templatePaths =>
      [
        'modes/service/',
      ];

  @override
  Map<String, dynamic> getModuleVars(DerivedTemplateVariables base) {
    return {
      'assumes_existing_project': true,
      'service_name': serviceName ?? base.name,
    };
  }
}
```

#### 2.2 Composition Planner

Replace mode-specific planners with a unified composition planner:

```dart
// hooks/plugins/composition_planner.dart

class CompositionPlanner implements PlannerPlugin {
  final List<TemplateModule> _modules = [
    ProjectModule(),
    FeatureModule(),
    ServiceModule(),
  ];

  @override
  bool canHandle(BaseTemplateVariables base) {
    return true; // Always handles - determines composition
  }

  @override
  DerivedTemplateVariables derive(BaseTemplateVariables base,
      DerivedTemplateVariables acc,
      Logger logger,) {
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
        if (base.features.isNotEmpty) {
          for (final feature in base.features) {
            final featureModule = FeatureModule(feature: feature);
            if (featureModule.canComposeWith(base.generationMode, acc)) {
              activeModules.add(featureModule);
              moduleVars.addAll(featureModule.getModuleVars(acc));
            }
          }
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

    return DerivedTemplateVariables(
      activeModules: activeModules.map((m) => m.name).toList(),
      moduleTemplatePaths: activeModules
          .expand((m) => m.templatePaths)
          .toSet()
          .toList(),
      moduleVars: moduleVars,
      includesBaseFoundation: base.generationMode == GenerationMode.project,
    );
  }
}
```

### 3. Template Rendering Strategy

#### 3.1 Module-Based File Resolution

Instead of path conditionals, use module-based file inclusion:

```dart
// hooks/post_gen.dart (or extend pre_gen.dart)

void resolveModuleFiles(HookContext context) {
  final modulePaths = context.vars['module_template_paths'] as List<String>;
  final basePath = '__brick__/';

  // Collect all files from active modules
  final filesToInclude = <String>{};

  for (final modulePath in modulePaths) {
    final fullPath = '$basePath$modulePath';
    // Recursively scan and include all files from this module
    final moduleFiles = _scanModuleDirectory(fullPath);
    filesToInclude.addAll(moduleFiles);
  }

  // Service partials are included within the service module

  // Store resolved file list for template rendering
  context.vars['resolved_files'] = filesToInclude.toList();
}
```

#### 3.2 Template Path Resolution

Modify Mason's file resolution to:

1. Scan `modes/{active_mode}/` for mode-specific files
2. Merge paths, with mode-specific files taking precedence
3. Service partials are included within the service module structure
4. Remove path-level conditionals entirely

### 4. Composition Workflows

#### 4.1 Project Generation (Includes Base Foundation)

```
generation_mode=project
  → ProjectModule
    → modes/project/lib/core/foundation/  (base classes)
    → modes/project/lib/shared/           (navigation, themes)
    → modes/project/                      (root files: main.dart, pubspec.yaml, etc.)
```

**Generated Structure:**

```
{{project_name}}/
├── lib/
│   ├── core/
│   │   └── foundation/
│   │       └── screen/
│   │           ├── base_screen.dart
│   │           └── base_view_model.dart
│   ├── shared/
│   │   ├── navigation/
│   │   └── themes/
│   └── l10n/
├── main.dart
├── pubspec.yaml
└── ...
```

#### 4.2 Feature Generation (Standalone)

```
generation_mode=feature
  → FeatureModule
    → modes/feature/lib/features/{{feature}}/
    → Assumes: existing project with base classes
```

**Generated Structure:**

```
lib/
└── features/
    └── {{feature}}/
        └── presentation/
            ├── screen/
            │   ├── {{component_name}}_screen.dart
            │   └── {{component_name}}_view_model.dart
            └── widgets/
```

#### 4.3 Service Generation (Standalone)

```
generation_mode=service
  → ServiceModule
    → modes/service/lib/core/services/{{feature}}/
    → modes/service/common/services/      (service partials)
    → Assumes: existing project with base classes
```

**Generated Structure:**

```
lib/
└── core/
    └── services/
        └── {{feature}}/
            └── {{component_name}}_service.dart
```

### 5. Module Dependencies

Define module dependencies to ensure correct composition:

```dart
class ModuleDependency {
  final String module;
  final List<String> requires;
  final List<String> conflicts;
  final List<String> includes;

  const ModuleDependency({
    required this.module,
    this.requires = const [],
    this.conflicts = const [],
    this.includes = const [],
  });
}

final moduleDependencies = {
  'project': ModuleDependency(
    module: 'project',
    requires: [],
    conflicts: [],
    includes: ['base_foundation'], // Base foundation is part of project
  ),
  'feature': ModuleDependency(
    module: 'feature',
    requires: [], // Assumes existing project, but doesn't require it at generation time
    conflicts: [],
    // Note: Feature assumes base classes exist in target project
  ),
  'service': ModuleDependency(
    module: 'service',
    requires: [], // Assumes existing project, but doesn't require it at generation time
    conflicts: [],
    // Note: Service assumes base classes exist in target project
  ),
};
```

### 6. Implementation Phases

#### Phase 1: Foundation (Week 1-2)

- [ ] Create modular directory structure (`modes/project/`, `modes/feature/`, `modes/service/`)
- [ ] Move base foundation classes to `modes/project/lib/core/foundation/`
- [ ] Implement `TemplateModule` interface and base modules
- [ ] Create `CompositionPlanner` to replace mode-specific planners
- [ ] Update `DerivedTemplateVariables` model to include module information

#### Phase 2: Project Mode Migration (Week 2-3)

- [ ] Migrate all project templates to `modes/project/`
- [ ] Ensure base foundation is properly included in project mode
- [ ] Update file path resolution for project mode
- [ ] Remove `{{#is_project}}` conditionals from templates
- [ ] Update scenario tests for project generation

#### Phase 3: Feature & Service Mode Migration (Week 3-4)

- [ ] Migrate feature templates to `modes/feature/`
- [ ] Migrate service templates to `modes/service/`
- [ ] Remove base foundation dependencies from feature/service templates
- [ ] Update template rendering to use module-based inclusion
- [ ] Remove `{{#is_feature}}` and `{{#is_service}}` conditionals
- [ ] Update scenario tests for feature and service generation

#### Phase 4: Composition Engine (Week 4-5)

- [ ] Implement module registry and composition system
- [ ] Create module dependency resolution
- [ ] Implement module-based file scanning and inclusion
- [ ] Update `pre_gen.dart` to use `CompositionPlanner`
- [ ] Ensure common partials work across all modes
- [ ] Remove all remaining path-level conditionals

#### Phase 5: Testing & Validation (Week 5-6)

- [ ] Update scenario tests for new structure
- [ ] Verify project mode includes base foundation correctly
- [ ] Verify feature/service modes work standalone
- [ ] Test incremental composition workflows
- [ ] Update golden files to match new structure
- [ ] Run full regression suite
- [ ] Update CI/CD workflows if needed

#### Phase 6: Documentation & Migration (Week 6)

- [ ] Update `ARCHITECTURE_WORKFLOW.md` with new composition model
- [ ] Update `README.md` with new structure
- [ ] Create migration guide for existing templates
- [ ] Update `BRICK_DESIGN.md` with composition architecture
- [ ] Document module extension points for future additions

### 7. Key Architectural Decisions

#### 7.1 Base Foundation Location

**Decision:** Base foundation classes are part of project mode and live in
`modes/project/lib/core/foundation/`

**Rationale:**

- Base classes (`base_screen.dart`, `base_view_model.dart`) are only needed when creating a new
  project
- Features and services assume an existing project structure with base classes already present
- This eliminates duplication and clarifies ownership

#### 7.2 Module Independence

**Decision:** Feature and service modes are standalone modules that assume existing project
structure

**Rationale:**

- Features and services are typically added to existing projects, not created in isolation
- Standalone modules are easier to test and maintain
- Clear separation of concerns improves code organization

#### 7.3 Composition Over Conditionals

**Decision:** Use explicit module composition instead of path-level conditionals

**Rationale:**

- Composition is more maintainable and testable
- Template structure becomes self-documenting
- Easier to extend with new modes or modules

### 8. Benefits

1. **Maintainability:** Each mode is self-contained and easier to modify independently
2. **Testability:** Modules can be tested in isolation
3. **Extensibility:** New modes can be added without affecting existing ones
4. **Clarity:** Template structure reflects the modular architecture
5. **Composition:** Projects can be built incrementally (base → features → services)
6. **Reduced Complexity:** Eliminates path conditionals in favor of explicit module inclusion
7. **Better Organization:** Clear ownership of base foundation (project mode only)

### 9. Migration Strategy

#### Backward Compatibility

- Maintain existing `generation_mode` enum for user-facing API
- Internally map to composition system
- Ensure generated outputs remain identical during transition

#### Gradual Migration

1. Implement composition system alongside existing conditionals
2. Migrate one mode at a time (start with `feature`, then `service`, then `project`)
3. Validate each migration with scenario tests
4. Remove old conditional logic once all modes are migrated

#### Risk Mitigation

- Keep old template structure as backup during migration
- Run comprehensive scenario tests after each phase
- Update golden files incrementally
- Document breaking changes (if any) clearly

### 10. Success Criteria

- [ ] Zero path-level conditionals in template structure
- [ ] All modes generate identical outputs (verified by golden tests)
- [ ] New modules can be added without modifying existing code
- [ ] Incremental composition works (base → add features → add services)
- [ ] Template structure is self-documenting (directory layout shows composition)
- [ ] Performance remains under 5-second generation target
- [ ] Base foundation classes are correctly located in `modes/project/lib/core/foundation/`
- [ ] Feature and service modes work standalone without base foundation

### 11. Future Extensions

#### Adding New Modes

1. Create new module directory: `modes/{new_mode}/`
2. Implement `TemplateModule` for the new mode
3. Register module in `CompositionPlanner`
4. Add scenario tests and golden files

#### Adding New Modules

1. Create module directory under appropriate mode
2. Implement module class extending `TemplateModule`
3. Update composition logic if needed
4. Add tests and documentation

### 12. References

- Current architecture: `ARCHITECTURE_WORKFLOW.md`
- Brick design: `BRICK_DESIGN.md`
- Template structure: `README.md`
- Reference implementation: `/examples/foundation_project`

---

## Conclusion

This plan establishes a clear path to refactor the `fly_foundation` template from a
conditional-based to a composition-based architecture. By separating modes into well-defined modules
and making base foundation classes part of the project mode, we achieve better maintainability,
testability, and extensibility while enabling incremental project composition.

The phased implementation approach allows for gradual migration with minimal disruption, and the
modular structure supports future extensions without requiring architectural changes.

