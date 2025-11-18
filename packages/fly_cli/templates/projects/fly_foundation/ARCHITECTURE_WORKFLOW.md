# Fly Foundation – Architecture & End‑to‑End Generation Workflow

This document details the internal architecture of the Fly Foundation Mason brick and traces the
complete generation workflow from user input to files on disk, including how validation, planning,
templating, and verification fit together.

Use this as a technical companion to `ONBOARDING.md` when you need deeper, system‑level
understanding.

---

## 1) System Overview

Core pieces involved in generation:

- `brick.yaml` – Declares user‑facing variables with types, defaults, and prompts.
- `hooks/pre_gen.dart` – Orchestrates planning via lightweight plugins and writes derived flags to
  `context.vars`.
- `hooks/plugins/*.dart` – Per‑mode derivation logic (project/feature/service) and validation rules.
- `hooks/plugins/composition.dart` – Defines composable template modules (ProjectModule, FeatureModule, ServiceModule).
- `hooks/plugins/composition_planner.dart` – Unified planner that composes modules based on generation_mode.
- `hooks/post_gen.dart` – Reorganizes generated files based on active modules.
- `__brick__/modes/` – Module-specific templates organized by mode (project, feature, service).
- `__brick__/{{~ *.dart }}` – Mason partials at root level for reusable template fragments.
- `tools/scenarios/` – Non‑interactive answer files for end‑to‑end runs.
- `test/goldens/` – Expected outputs for scenarios; used for regression checks.
- `.github/workflows/template-ci.yml` – CI pipeline running scenarios, diffs, and metrics.

High‑level data flow:

```
User/CLI inputs
   │
   ▼
brick.yaml  ──►  mason reads variables  ──►  hooks/pre_gen.dart (planner + plugins)  ──►  derived flags merged
                                                                                         into context.vars
                                                                                                       │
                                                                                                       ▼
                                                                                           __brick__/ templates
                                                                                           (partials + flags)
                                                                                                       │
                                                                                                       ▼
                                                                                   generated project/files on disk
```

---

## 2) Variable Resolution and Normalization

1. The CLI (Fly CLI or Mason CLI) collects inputs defined in `brick.yaml` (minimal public schema:
   `generation_mode`, `name`, `description`, `organization`, `platforms`, `preset`).
2. Mason makes these inputs available as `context.vars` to hooks.
3. `pre_gen.dart` resolves a canonical "view" of the inputs through a planner chain:
    - **PresetPlanner**: Maps `preset` enum to internal boolean flags (`with_tests`, `with_docs`,
      `with_mcp`, `code_generation`, `ai_integration`, service toggles, feature toggles).
    - **CoreVarsPlanner**: Bridges public schema to legacy internal names (`project_name`, `feature`,
      `component_name`, `screen_type`, `service_type`, defaults for SDK versions, packages).
    - **CompositionPlanner**: Unified planner that determines which modules to activate based on
      `generation_mode` and composes them together. Replaces mode-specific planners.
    - Validates impossible or unsupported combinations (fail fast with actionable messages).
4. The hook merges all derived flags back into `context.vars`. From this point on, templates reference
   normalized flags; no complex logic remains in templates.
5. `post_gen.dart` reorganizes generated files:
    - Moves files from `modes/project/` to output root (for project mode)
    - Merges files from `modes/feature/` and `modes/service/` into existing structure
    - Removes files from inactive modules
    - Cleans up temporary `modes/` directory

Key normalization examples:

- Preset → internal flags: `preset=starter` → `with_tests=true`, `with_docs=true`, `with_mcp=true`,
  `code_generation=true`, `ai_integration=true`, `with_retry_logic=false`, etc.
- Feature mode: `screen_type` (from CoreVarsPlanner) → `is_list_screen`, `is_detail_screen`,
  `is_form_screen`, `requires_validation`.
- Service mode: `service_type` (from CoreVarsPlanner) + preset-derived toggles → `is_api_service`,
  `supports_retry`, `supports_caching`, `supports_interceptors`, `generate_mocks`.
- Project/platforms: `platforms` list → `supports_ios/android/web/macos/windows/linux/desktop`.
- State management: `state_mgmt` (from PresetPlanner, default `riverpod`) → `use_riverpod`,
  `use_bloc`, `use_cubit`.

---

## 3) Planner Plugins (Hooks)

The planner is pluggable (see `hooks/plugins/planner.dart`). Each plugin:

- Decides applicability via `canHandle(vars)`.
- Produces a `Map<String, dynamic>` of derived flags via `derive(vars, logger)`.

Registered plugins (evaluated in order):

- `PresetPlanner` – Maps `preset` enum to all internal boolean flags (tests, docs, MCP, codegen, AI,
  service extras, feature toggles). Always handles (presets are global).
- `CoreVarsPlanner` – Bridges public schema (`name`, `generation_mode`) to legacy internal names
  (`project_name`, `feature`, `component_name`, `screen_type`, `service_type`, SDK defaults,
  package lists). Always handles (core vars are global).
- `CompositionPlanner` – Unified planner that determines active modules based on `generation_mode` and
  composes them together. Maintains backward compatibility with `is_project`/`is_feature`/`is_service`
  flags while enabling composition-based architecture.

The planner chain ensures that:
1. Presets drive all internal toggles (no user-facing boolean flags).
2. Public schema (`name`, `generation_mode`) is mapped to internal names templates expect.
3. Mode-specific logic runs after core derivation, consuming derived vars.

Adding a new plugin (e.g., `ProviderModePlanner`) is frictionless and avoids stuffing every rule
into a monolith.

---

## 4) Composition-Based Template Structure

Templates are organized by mode under `__brick__/modes/`, following a **composition architecture**:

### Module Organization

```
__brick__/
├── modes/
│   ├── project/         # Full project scaffolding (includes base foundation)
│   │   ├── lib/
│   │   │   ├── core/foundation/  # Base classes (part of project mode)
│   │   │   ├── shared/           # Navigation, themes
│   │   │   └── l10n/             # Localization
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

### Mason Partials

Partials are reusable template fragments that live at `__brick__/` root level (Mason requirement):

- `{{~ caching_field.dart }}` – Cache field declaration gated by `supports_caching`.
- `{{~ caching_get.dart }}` / `{{~ caching_set.dart }}` – Cache access around operations.
- `{{~ retry_execute.dart }}` – Retry loop gated by `supports_retry`.
- `{{~ interceptors_types.dart }}` – Typedef for interceptors.
- `{{~ interceptors_run.dart }}` – Generic interceptor chain runner.

Partials are included using `{{~ partial_name }}` syntax (not generated as separate files).

### Composition Benefits

- **Maintainability**: Each mode is self-contained and easier to modify independently
- **No Path Conditionals**: Removed all `{{#is_project}}`, `{{#is_feature}}`, `{{#is_service}}` path-level conditionals
- **Extensibility**: New modes can be added without affecting existing ones
- **Clarity**: Template structure reflects the modular architecture

---

## 5) Module-Based File Resolution

The composition architecture uses module-based file resolution instead of path conditionals:

1. **Module Selection**: `CompositionPlanner` determines which modules are active based on `generation_mode`
2. **Template Rendering**: Mason generates files from all active module directories
3. **Post-Generation Reorganization**: `post_gen.dart` hook reorganizes files:
   - **Project mode**: Moves `modes/project/` files to output root
   - **Feature mode**: Merges `modes/feature/` files into existing `lib/features/` structure
   - **Service mode**: Merges `modes/service/` files into existing `lib/core/services/` structure
   - Removes files from inactive modules
   - Cleans up temporary `modes/` directory

This approach completely eliminates path-level conditionals while maintaining clean separation of concerns.

---

## 6) End‑to‑End Workflow (Start → Finish)

1. User invokes generation:
    - Fly CLI (recommended): `fly create … --template=fly_foundation --generation-mode=project`
    - Or Mason CLI: `mason make packages/fly_cli/templates/projects/fly_foundation`
2. Mason loads `brick.yaml` and collects variables.
3. Mason runs `hooks/pre_gen.dart`.
    - Plugins compute derived flags and validate combos.
    - Any invalid configuration raises a `HookException` with a clear message.
    - Derived flags merge into `context.vars`.
4. Mason renders `__brick__/`:
    - File paths are resolved; files gated by conditionals are included/skipped.
    - Content is rendered with Mustache + derived flags and partials.
5. Files are written into the output directory (target project or component folder).
6. (Optional) Post steps by the user:
    - Run `flutter analyze` / `dart analyze`.
    - Run code generators if enabled (`build_runner`).

---

## 7) Error Handling and Validation

Validation lives in plugins (e.g., `ServiceModePlanner`):

- If a combination is unsupported (example: `service_type=analytics` + `with_caching=true`), the
  plugin throws a `HookException`.
- Failures occur **before** any files are generated, avoiding partial outputs.
- Add new constraints in the appropriate plugin to centralize policy.

---

## 8) Testing and Goldens

The template uses **scenario‑based testing**:

- `tools/scenarios/` stores JSON inputs representing real user cases (service/feature/project).
- `tools/run_scenarios.sh` runs all scenarios non‑interactively, generating outputs in
  `.scenario_out/`.
- If a matching golden exists in `test/goldens/<name>`, a recursive diff (`diff -ru`) is performed.
- On mismatch, the script fails and prints instructions for updating goldens intentionally.

This approach ensures:

- Regression safety across modes and flags.
- Practical coverage of conditional paths.
- Easy onboarding for reviewers (diffs are readable).

---

## 9) CI Integration

Workflow: `.github/workflows/template-ci.yml`

- Checks out repo, installs Dart and Mason CLI.
- Runs scenario script and diffs against goldens.
- Runs `tools/metrics/count_conditionals.dart` to report conditional density.
- Fails PRs with diffs or broken scenarios, preventing unreviewed changes to generated outputs.

---

## 10) Performance Considerations

- `pre_gen.dart` does minimal CPU work (string comparisons, boolean derivations); negligible
  overhead compared to file I/O.
- Partial inclusion is linear in template size; no dynamic file generation loops are performed in
  hooks.
- Target generation time remains comfortably under the 5‑second goal for typical projects.

---

## 11) Extension Points

- Add variables: `brick.yaml` (user‑facing) or compute them in a plugin (derived).
- Add plugins: create `hooks/plugins/<something>_mode.dart` and register it in the composite
  planner.
- Add service partials: place under `__brick__/modes/service/common/services/…` and include with `{{> modes/service/common/services/... }}`.
- Add scenarios: put JSONs under `tools/scenarios/<mode>/` and add to `tools/run_scenarios.sh`.
- Add goldens: copy `.scenario_out/<name>` into `test/goldens/<name>` after verifying correctness.

---

## 12) Example Walkthroughs

### A) Project Creation (default foundation)

Inputs (new minimal schema):

```
generation_mode=project
name=acme_app
description=Default Fly foundation project
organization=com.example
platforms=[ios, android, web]
preset=batteries_included
```

Flow:

1. `PresetPlanner` maps `preset=batteries_included` → all internal flags enabled
   (`with_tests=true`, `with_docs=true`, `with_mcp=true`, `code_generation=true`,
   `ai_integration=true`, etc.).
2. `CoreVarsPlanner` derives `project_name=acme_app`, `feature=home`, `component_name=home`,
   SDK defaults, package lists.
3. `ProjectModePlanner` sets `active_mode=project`, `is_project=true`, computes
   `supports_ios/android/web`, etc.
4. Templates for project files render with conditionals (tests/docs/ai) based on preset-derived flags.
5. Output is a runnable Flutter project with configured analysis options, `pubspec.yaml`,
   `main.dart`, navigation, l10n.

### B) Feature Screen (list + riverpod)

Inputs:

```
generation_mode=feature
name=dashboard
description=Feature list (riverpod) scenario
organization=com.example
platforms=[ios, android]
preset=starter
```

Flow:

1. `PresetPlanner` maps `preset=starter` → `with_viewmodel=true`, `with_navigation=true`,
   `with_validation=false`, `state_mgmt=riverpod`.
2. `CoreVarsPlanner` derives `project_name=acme_app`, `feature=dashboard`, `component_name=dashboard`,
   `screen_type=list` (default).
3. `FeatureModePlanner` sets `active_mode=feature`, `is_feature=true`, `is_list_screen=true`,
   `use_riverpod=true`.
4. Screen template includes base layout and wiring; form/validation flags remain off.
5. Output is a `DashboardScreen` with Riverpod wiring and navigation hooks.

### C) Service (api + retry + caching + interceptors)

Inputs:

```
generation_mode=service
name=summary
description=API service with retry and cache scenario
organization=com.example
platforms=[ios, android]
preset=batteries_included
```

Flow:

1. `PresetPlanner` maps `preset=batteries_included` → `with_retry_logic=true`,
   `with_caching=true`, `with_interceptors=true`, `with_mocks=true`.
2. `CoreVarsPlanner` derives `project_name=acme_app`, `feature=summary`, `component_name=summary`,
   `service_type=api` (default), `api_base_url=https://api.example.com` (default).
3. `ServiceModePlanner` sets `active_mode=service`, `is_service=true`, `is_api_service=true`,
   `supports_retry/caching/interceptors=true`, `generate_mocks=true`.
4. Service template includes partials for caching, retry, and interceptor chain.
5. Output is a `SummaryService` with consistent `AppResult<T>` flow and optional layers enabled.

---

## 13) Maintaining Architectural Integrity

To keep the template maintainable as it grows:

- Prefer new planner plugins over complex template logic.
- Centralize constraints in plugins and fail early.
- Keep partials focused and small; avoid nested partial pyramids.
- Grow scenario coverage alongside new flags or modes; update goldens intentionally.
- Track conditional density to avoid gradual complexity creep.

---

## 14) Glossary

- **Derived flag**: A hook‑computed boolean/string that simplifies template logic (e.g.,
  `is_form_screen`).
- **Partial**: A reusable template snippet included in multiple templates.
- **Scenario**: A fixed set of answers used to generate outputs non‑interactively for testing.
- **Golden**: Committed expected output for a given scenario.
- **Planner plugin**: A small class that derives flags/validations for a mode or concern.

---

With this architecture and workflow, the Fly Foundation template stays unified, testable, and
scalable—ready for additional modes, platforms, and architectural patterns without sacrificing
maintainability.


