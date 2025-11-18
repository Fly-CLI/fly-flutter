# Fly Foundation – Extension Development Guide

This guide explains how to add a new “extension” to the Fly Foundation template system – for
example:

- A new generation mode (`provider`, `repository`, `widget`, `bloc`/`cubit` variants).
- A cross‑cutting capability (e.g., analytics, offline mode, custom logging).
- A substantial feature flag that affects multiple templates.

It focuses on **how** to integrate with the existing architecture (planner plugins, partials,
scenarios, goldens) so your extension is maintainable and testable.

---

## 1. Extension Types

You can extend the template in three main ways:

1. **New Mode** – A first‑class generation path (similar to `project`, `feature`, `service`).
2. **New Capability** – A cross‑cutting concern that alters code in existing modes (e.g.,
   diagnostics).
3. **New Feature Flag** – A toggle that changes a specific aspect (e.g.,
   `with_analytics_dashboard`).

All three follow the same basic pattern:

- Adjust `brick.yaml` (if user‑facing).
- Extend planner plugins (derive flags, enforce constraints).
- Add/update templates/partials.
- Add scenarios and goldens.
- Update docs.

---

## 2. Step‑by‑Step: Adding a New Mode (Example: `provider` Mode)

### 2.1 Design the Extension

Clarify:

- What should `provider` mode generate (files, folders, imports)?
- Which variables are required (e.g., `component_name`, `provider_type`, `with_state_class`)?
- Which existing modes does it depend on (none, or feature/service/project)?

Document this in a short design note before you start coding.

### 2.2 Update `brick.yaml`

1. Extend `generation_mode` enum if you want `provider` as a top‑level mode:

```yaml
generation_mode:
  type: enum
  description: Controls which workflow is executed
  default: project
  values:
    - project
    - feature
    - service
    - provider
```

2. Add any provider‑specific variables (if not already present), e.g.:

```yaml
provider_type:
  type: enum
  description: Provider archetype when generation_mode=provider
  default: notifier
  values:
    - notifier
    - future
    - stream
    - state

with_state_class:
  type: boolean
  description: Generate an explicit state class
  default: false
```

Keep descriptions clear and future‑proof.

### 2.3 Create Mode-Specific Variable Class

Create `hooks/plugins/variables/provider_variables.dart`:

```dart
import 'mode_specific_variables.dart';
import '../foundation_model.dart';
import '../mason_variable_keys.dart';

final class ProviderVariables extends ModeSpecificVariables {
  const ProviderVariables({
    this.isProvider = true,
    this.providerType,
    this.isNotifierProvider = false,
    this.isFutureProvider = false,
    this.isStreamProvider = false,
    this.isStateProvider = false,
    this.generateStateClass = false,
    this.componentName,
  });

  final bool isProvider;
  final String? providerType;
  final bool isNotifierProvider;
  final bool isFutureProvider;
  final bool isStreamProvider;
  final bool isStateProvider;
  final bool generateStateClass;
  final String? componentName;

  @override
  GenerationMode get mode => GenerationMode.provider;

  @override
  Map<String, dynamic> toMasonVars() {
    // Implementation
  }
}
```

### 2.4 Add a Mode-Specific Planner

Create `hooks/plugins/planners/provider_planner.dart`:

```dart
import 'package:mason/mason.dart';
import '../foundation_model.dart';
import '../variables/mode_specific_variables.dart';
import '../variables/provider_variables.dart';
import 'mode_specific_planner.dart';

class ProviderPlanner implements ModeSpecificPlanner {
  @override
  GenerationMode get supportedMode => GenerationMode.provider;

  @override
  ProviderVariables derive(
    BaseTemplateVariables base,
    Logger logger,
  ) {
    final providerType = base.providerType ?? 'notifier';
    final withStateClass = base.withStateClass;

    return ProviderVariables(
      isProvider: true,
      providerType: providerType,
      isNotifierProvider: providerType == 'notifier',
      isFutureProvider: providerType == 'future',
      isStreamProvider: providerType == 'stream',
      isStateProvider: providerType == 'state',
      generateStateClass: withStateClass,
      componentName: base.name,
    );
  }
}
```

Then register it in `hooks/plugins/planners/planner_factory.dart` by adding it to the `_modePlanners` map.

Optionally, add validation (e.g., certain provider types may require additional flags).

### 2.5 Create Templates and Partials

Start with a minimal, focused set of templates. For example:

- `__brick__/lib/providers/{{#is_provider}}{{component_name}}_provider.dart{{/is_provider}}`  
  (or a future `__brick__/modes/provider/...` subtree).
- Shared partials under `__brick__/modes/provider/common/providers/`:
    - `provider_notifier.dart`
    - `provider_future.dart`
    - `provider_state_class.dart`

Use derived flags from the plugin:

```mustache
{{#is_notifier_provider}}
{{> modes/provider/common/providers/provider_notifier.dart }}
{{/is_notifier_provider}}

{{#generate_state_class}}
{{> modes/provider/common/providers/provider_state_class.dart }}
{{/generate_state_class}}
```

Avoid duplicating whole provider templates for each type; prefer partials.

### 2.6 Add Scenarios and Goldens

1. Add scenario JSON files under `tools/scenarios/provider/`, e.g.:

```json
{
  "generation_mode": "provider",
  "component_name": "session",
  "provider_type": "notifier",
  "with_state_class": true
}
```

2. Update `tools/run_scenarios.sh` to run the new scenario:

```bash
run_scenario "$ROOT_DIR/tools/scenarios/provider/notifier_with_state.json" "provider/notifier_with_state"
```

3. Run the scenarios and accept initial goldens:

```bash
tools/run_scenarios.sh
cp -R .scenario_out/provider/notifier_with_state test/goldens/provider/notifier_with_state
```

Commit goldens and ensure CI passes.

### 2.7 Update Documentation

- `README.md`: Add the new mode to the generation modes table and usage examples.
- `ONBOARDING.md`: Mention the new mode and any special considerations.
- `ARCHITECTURE_WORKFLOW.md`: Add a short walkthrough for your new mode.

---

## 3. Step‑by‑Step: Adding a Cross‑Cutting Capability

Example: `with_analytics` affects project, feature, and service outputs.

### 3.1 Add Flag (If User‑Facing)

**Option A**: Add to `brick.yaml` if it should be user-configurable:

```yaml
with_analytics:
  type: boolean
  description: Enable analytics instrumentation in generated code
  default: false
```

**Option B**: Add to preset enum configuration if it should be driven by presets:

In `hooks/plugins/presets.dart`, extend `FoundationPreset` enum with an `analytics` field and set it per preset (e.g., `starter.analytics=false`, `batteriesIncluded.analytics=true`, `minimal.analytics=false`).

### 3.2 Extend Relevant Planners

Decide which planners should handle analytics:

- `PresetPlanner` (cross-cutting) – If driven by preset, map preset's `analytics` field to `with_analytics` flag in `SharedDerivedVariables`.
- `ProjectPlanner` (mode-specific) – e.g., add `include_analytics_package` to `ProjectVariables`.
- `FeaturePlanner` (mode-specific) – e.g., add `track_screen_view` to `FeatureVariables`.
- `ServicePlanner` (mode-specific) – e.g., add `track_service_call` to `ServiceVariables`.

Add simple flags that templates can use like:

- `analytics_enabled` (or `with_analytics` if using preset) - in `SharedDerivedVariables`
- `feature_tracks_analytics` - in `FeatureVariables`
- `service_tracks_analytics` - in `ServiceVariables`

### 3.3 Add/Update Partials and Templates

Add partials for analytics wiring:

- `modes/analytics/common/event_helpers.dart`
- `modes/analytics/common/project_config.dart`

Then conditionally include them where needed:

```mustache
{{#analytics_enabled}}
import 'analytics/event_helpers.dart';
{{/analytics_enabled}}
```

### 3.4 Test with Scenarios

- Add at least one scenario per affected mode with `with_analytics=true`.
- Confirm outputs via goldens and ensure CI passes.

---

## 4. Step‑by‑Step: Adding a New Feature Flag

Feature flags are lighter‑weight than full capabilities or modes but follow the same pattern.

Example: `with_retry_for_feature_calls`.

1. Add to `brick.yaml` if user‑facing.
2. Extend appropriate planner:
   - If cross-cutting: Add to `SharedDerivedVariables` and update a cross-cutting planner (e.g., `PresetPlanner`).
   - If mode-specific: Add to the appropriate mode-specific variable class (e.g., `FeatureVariables`) and update the mode-specific planner (e.g., `FeaturePlanner`).
3. Update templates to use the derived flag instead of raw variables.
4. Add scenarios/goldens for both true/false cases.

---

## 5. Best Practices Checklist

When adding any extension:

- Keep logic in hooks/plugins; keep templates declarative.
- Introduce small, composable partials rather than large copy‑pasted templates.
- Add at least one scenario per new branch (true/false or enum variants).
- Accept goldens deliberately and include a short explanation in your PR.
- Keep naming consistent (`is_*`, `supports_*`, `use_*`, `with_*`).
- Update docs as soon as behavior changes.

---

## 6. Review Checklist for Extensions

For reviewers evaluating a new extension:

- [ ] Variables in `brick.yaml` are clearly named and documented.
- [ ] Mode-specific variable class created (if adding new mode) or existing class extended.
- [ ] Planner logic is concise, with validations where needed.
- [ ] Planner registered in `PlannerFactory` (if adding new mode-specific planner).
- [ ] Templates use derived flags and partials; no complex logic inline.
- [ ] New scenarios exist and cover new branches.
- [ ] Goldens reflect expected changes only.
- [ ] CI (scenarios + metrics) passes.
- [ ] Documentation updated (README, ONBOARDING, ARCHITECTURE_WORKFLOW, or this guide if needed).

---

By following this guide, you can add powerful extensions to the Fly Foundation template while
preserving its unified, testable, and maintainable architecture.


