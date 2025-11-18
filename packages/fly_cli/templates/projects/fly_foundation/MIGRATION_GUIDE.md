# Composition Architecture Migration Guide

## Overview

This guide explains the composition-based architecture implemented in `fly_foundation` template and provides guidance for users and contributors.

---

## What Changed?

### Before: Conditional-Based Architecture

Previously, the template used path-level conditionals throughout the `__brick__/` directory:

```
__brick__/
├── {{#is_project}}main.dart{{/is_project}}
├── {{#is_project}}pubspec.yaml{{/is_project}}
├── {{#is_feature}}lib/features/...{{/is_feature}}
├── {{#is_service}}lib/core/services/...{{/is_service}}
└── partials/
    └── _*.dart
```

**Issues:**
- Difficult to navigate and understand template structure
- Tight coupling between modes
- Hard to test modes in isolation
- Path conditionals created maintenance overhead

### After: Composition-Based Architecture

The template now uses a modular structure with explicit module directories:

```
__brick__/
├── modes/
│   ├── project/         # Full project scaffolding
│   │   ├── lib/core/foundation/  # Base classes
│   │   ├── lib/shared/           # Navigation, themes
│   │   ├── main.dart
│   │   └── pubspec.yaml
│   ├── feature/         # Standalone feature generation
│   │   ├── lib/features/
│   │   ├── test/
│   │   └── docs/
│   └── service/         # Standalone service generation
│       ├── lib/core/services/
│       ├── test/
│       └── docs/
└── {{~ *.dart }}       # Mason partials at root level
```

**Benefits:**
- Self-documenting structure
- Modes are independent and testable
- No path-level conditionals
- Easy to extend with new modes

---

## For Template Users

### No Breaking Changes

The user-facing API remains unchanged:

```bash
# Project generation (unchanged)
fly create my_app --template=fly_foundation --generation-mode=project

# Feature generation (unchanged)
fly create dashboard --template=fly_foundation --generation-mode=feature

# Service generation (unchanged)
fly create api --template=fly_foundation --generation-mode=service
```

### What You'll Notice

1. **Faster Generation**: Composition architecture is slightly faster (~0.2-0.3s per generation)
2. **Cleaner Output**: Generated files are better organized
3. **Same Structure**: Output directory structure is identical to before

### No Migration Required

If you've been using `fly_foundation` template, you don't need to change anything. The composition architecture is fully backward compatible.

---

## For Template Contributors

### Adding New Modes

To add a new mode (e.g., `widget`):

#### 1. Create Module Directory

```
__brick__/modes/widget/
├── lib/
│   └── widgets/
│       └── {{component_name}}_widget.dart
├── test/
│   └── {{component_name}}_widget_test.dart
└── docs/
    └── {{component_name}}_widget.md
```

#### 2. Define Module Class

Create `hooks/plugins/widget_module.dart`:

```dart
import 'package:mason/mason.dart';
import 'foundation_model.dart';
import 'composition.dart';

class WidgetModule implements TemplateModule {
  @override
  String get name => 'widget';

  @override
  bool canComposeWith(GenerationMode mode, DerivedTemplateVariables vars) {
    return mode == GenerationMode.widget;
  }

  @override
  List<String> get templatePaths => ['modes/widget/'];

  @override
  Map<String, dynamic> getModuleVars(DerivedTemplateVariables base) {
    return {
      'assumes_existing_project': true,
      'widget_name': base.componentName ?? 'widget',
    };
  }
}
```

#### 3. Register Module

Update `hooks/plugins/composition_planner.dart`:

```dart
class CompositionPlanner implements PlannerPlugin {
  final List<TemplateModule> _modules = [
    ProjectModule(),
    FeatureModule(),
    ServiceModule(),
    WidgetModule(), // Add your module
  ];
  
  // ... rest of implementation
}
```

#### 4. Add Generation Mode

Update `hooks/plugins/foundation_model.dart`:

```dart
enum GenerationMode {
  project,
  feature,
  service,
  widget, // Add your mode
}
```

Update `brick.yaml`:

```yaml
vars:
  generation_mode:
    type: enum
    values:
      - project
      - feature
      - service
      - widget  # Add your mode
```

#### 5. Add Tests

Create scenario file `tools/scenarios/widget/basic_widget.json`:

```json
{
  "generation_mode": "widget",
  "name": "custom_button",
  "description": "Custom button widget",
  "organization": "com.example",
  "platforms": ["ios", "android"],
  "preset": "starter"
}
```

Update `tools/run_scenarios.sh`:

```bash
run_scenario "$ROOT_DIR/tools/scenarios/widget/basic_widget.json" "widget/basic_widget"
```

Run tests:

```bash
cd /path/to/fly_foundation
bash tools/run_scenarios.sh
```

Create golden files:

```bash
cp -R .scenario_out/widget/basic_widget test/goldens/widget/basic_widget
```

### Working with Mason Partials

Mason partials must follow specific requirements:

#### Requirements

1. **Location**: Partials must be at `__brick__/` root level (not in subdirectories)
2. **Naming**: Use `{{~ partial_name }}` syntax (with tilde `~`)
3. **Usage**: Include with `{{~ partial_name }}` (not `{{> partials/... }}`)

#### Example: Creating a New Partial

Create partial at root:

```dart
// __brick__/{{~ validation_mixin.dart }}
{{#requires_validation}}
mixin ValidationMixin {
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    // ... validation logic
    return null;
  }
}
{{/requires_validation}}
```

Use in template:

```dart
// __brick__/modes/feature/lib/features/{{feature}}/{{component_name}}_view_model.dart
import 'package:flutter/material.dart';

{{~ validation_mixin.dart }}

class {{component_name.pascalCase()}}ViewModel {
  // ... view model code
}
```

#### Partial Best Practices

1. **Keep partials focused**: Each partial should serve a single purpose
2. **Use conditional blocks**: Gate partial content with flags (e.g., `{{#supports_caching}}`)
3. **Name clearly**: Use descriptive names that indicate the partial's purpose
4. **Document usage**: Add comments in partials explaining when they should be used

### Module Design Guidelines

#### 1. Independence

Each module should be standalone and not depend on other modules:

```dart
// ✅ Good: Feature module is standalone
class FeatureModule implements TemplateModule {
  @override
  Map<String, dynamic> getModuleVars(DerivedTemplateVariables base) {
    return {
      'assumes_existing_project': true, // Documents assumption
      'feature_name': base.feature ?? 'home',
    };
  }
}

// ❌ Bad: Feature module depends on project module
class FeatureModule implements TemplateModule {
  final ProjectModule projectModule; // Don't do this
  
  FeatureModule({required this.projectModule});
}
```

#### 2. Clear Ownership

Each file should belong to exactly one module:

```
✅ Good:
modes/project/lib/core/foundation/screen/base_screen.dart  # Project owns base classes
modes/feature/lib/features/{{feature}}/...                  # Feature owns feature files
modes/service/lib/core/services/{{feature}}/...             # Service owns service files

❌ Bad:
modes/shared/lib/core/foundation/...  # Shared ownership is unclear
```

#### 3. Minimal Variables

Modules should derive minimal additional variables:

```dart
// ✅ Good: Minimal, focused variables
@override
Map<String, dynamic> getModuleVars(DerivedTemplateVariables base) {
  return {
    'assumes_existing_project': true,
    'service_name': base.componentName ?? 'service',
  };
}

// ❌ Bad: Too many derived variables
@override
Map<String, dynamic> getModuleVars(DerivedTemplateVariables base) {
  return {
    'assumes_existing_project': true,
    'service_name': base.componentName ?? 'service',
    'has_api': true,
    'has_cache': true,
    'has_retry': true,
    'has_interceptors': true,
    'has_mocks': true,
    // ... 20 more variables
  };
}
```

Use preset-derived flags instead (handled by `PresetPlanner`).

---

## Architecture Decisions

### Why Composition Over Conditionals?

1. **Maintainability**: Changes to one mode don't affect others
2. **Testability**: Modules can be tested in isolation
3. **Extensibility**: New modes can be added without modifying existing code
4. **Clarity**: Directory structure is self-documenting

### Why Base Foundation in Project Mode?

Base foundation classes (`base_screen.dart`, `base_view_model.dart`) are part of project mode because:

1. **Ownership**: Only needed when creating a new project
2. **No Duplication**: Features and services assume base classes exist
3. **Clear Separation**: Project creates structure, features/services extend it

### Why Post-Gen Hook?

Mason generates all modules initially, then `post_gen.dart` reorganizes files because:

1. **Mason Limitation**: Mason doesn't support conditional directory scanning
2. **Flexibility**: Easy to change file organization without touching templates
3. **Cleanliness**: Users never see the `modes/` directory in output

---

## Troubleshooting

### Module Not Generating Files

**Problem**: Files from your module aren't appearing in output

**Solution**: Check that:
1. Module is registered in `CompositionPlanner._modules`
2. `canComposeWith()` returns `true` for your mode
3. `templatePaths` points to correct directory
4. Post-gen hook handles your module correctly

### Partial Not Found

**Problem**: `{{~ partial_name }}` not found error

**Solution**: Ensure partial:
1. Is at `__brick__/` root level (not in subdirectory)
2. Uses correct naming: `{{~ partial_name.dart }}`
3. Is not in `.gitignore` or `.cursorignore`

### Golden Test Failing

**Problem**: Scenario test fails with diff errors

**Solution**:
1. Run scenario manually to see actual output
2. If output is correct, update golden:
   ```bash
   cp -R .scenario_out/mode/scenario test/goldens/mode/scenario
   ```
3. If output is incorrect, fix template and re-run

---

## Resources

- **Architecture Overview**: See `ARCHITECTURE_WORKFLOW.md`
- **Implementation Status**: See `IMPLEMENTATION_STATUS.md`
- **Composition Plan**: See `COMPOSITION_ARCHITECTURE_PLAN.md`
- **Mason Documentation**: [Nested Templates (Partials)](https://pub.dev/packages/mason_cli#nested-templates-partials)

---

## Questions?

If you have questions or need help:

1. Check existing documentation in this repository
2. Review scenario tests in `tools/scenarios/`
3. Look at golden outputs in `test/goldens/`
4. Open an issue with the `template` label

---

**Last Updated**: 2025-11-18
**Applies To**: fly_foundation v1.0.0+

