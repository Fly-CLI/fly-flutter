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

### 2.3 Add a Planner Plugin

Create `hooks/plugins/provider_mode.dart`:

```dart
import 'package:mason/mason.dart';

import 'planner.dart';

class ProviderModePlanner implements PlannerPlugin {
  @override
  bool canHandle(Map<String, dynamic> vars) {
    return vars['generation_mode'] == 'provider';
  }

  @override
  Map<String, dynamic> derive(Map<String, dynamic> vars, Logger logger) {
    final providerType = (vars['provider_type'] as String?)?.toLowerCase() ?? 'notifier';
    final withStateClass = vars['with_state_class'] == true;

    return <String, dynamic>{
      'active_mode': 'provider',
      'is_notifier_provider': providerType == 'notifier',
      'is_future_provider': providerType == 'future',
      'is_stream_provider': providerType == 'stream',
      'is_state_provider': providerType == 'state',
      'generate_state_class': withStateClass,
    };
  }
}
```

Then register it in `hooks/pre_gen.dart` by adding it to the `CompositePlanner` list.

Optionally, add validation (e.g., certain provider types may require additional flags).

### 2.4 Create Templates and Partials

Start with a minimal, focused set of templates. For example:

- `__brick__/lib/providers/{{#is_provider}}{{component_name}}_provider.dart{{/is_provider}}`  
  (or a future `__brick__/modes/provider/...` subtree).
- Shared partials under `__brick__/common/providers/`:
    - `provider_notifier.dart`
    - `provider_future.dart`
    - `provider_state_class.dart`

Use derived flags from the plugin:

```mustache
{{#is_notifier_provider}}
{{> common/providers/provider_notifier.dart }}
{{/is_notifier_provider}}

{{#generate_state_class}}
{{> common/providers/provider_state_class.dart }}
{{/generate_state_class}}
```

Avoid duplicating whole provider templates for each type; prefer partials.

### 2.5 Add Scenarios and Goldens

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

### 2.6 Update Documentation

- `README.md`: Add the new mode to the generation modes table and usage examples.
- `ONBOARDING.md`: Mention the new mode and any special considerations.
- `ARCHITECTURE_WORKFLOW.md`: Add a short walkthrough for your new mode.

---

## 3. Step‑by‑Step: Adding a Cross‑Cutting Capability

Example: `with_analytics` affects project, feature, and service outputs.

### 3.1 Add Flag (If User‑Facing)

In `brick.yaml`:

```yaml
with_analytics:
  type: boolean
  description: Enable analytics instrumentation in generated code
  default: false
```

### 3.2 Extend Relevant Plugins

Decide which plugins should handle analytics:

- `ProjectModePlanner` – e.g., add `include_analytics_package`.
- `FeatureModePlanner` – e.g., `track_screen_view`.
- `ServiceModePlanner` – e.g., `track_service_call`.

Add simple flags that templates can use like:

- `analytics_enabled`
- `feature_tracks_analytics`
- `service_tracks_analytics`

### 3.3 Add/Update Partials and Templates

Add partials for analytics wiring:

- `common/analytics/event_helpers.dart`
- `common/analytics/project_config.dart`

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
2. Extend appropriate plugin (e.g., `FeatureModePlanner`) to normalize into
   `feature_supports_retry`.
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
- [ ] Planner plugin logic is concise, with validations where needed.
- [ ] Templates use derived flags and partials; no complex logic inline.
- [ ] New scenarios exist and cover new branches.
- [ ] Goldens reflect expected changes only.
- [ ] CI (scenarios + metrics) passes.
- [ ] Documentation updated (README, ONBOARDING, ARCHITECTURE_WORKFLOW, or this guide if needed).

---

By following this guide, you can add powerful extensions to the Fly Foundation template while
preserving its unified, testable, and maintainable architecture.


