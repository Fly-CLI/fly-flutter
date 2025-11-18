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
- `hooks/pre_gen.dart` – Thin orchestration layer that delegates to `HookOrchestrator`.
- `hooks/post_gen.dart` – Thin orchestration layer that delegates file reorganization to `HookOrchestrator`.
- `hooks/plugins/hook_orchestrator.dart` – Core orchestration API providing `plan`, `selectModules`, and `reorganizeFiles` functions.
- `hooks/plugins/module_registry.dart` – Data-driven module registry that manages template modules and their composition rules.
- `hooks/plugins/planners/*.dart` – Planner system with mode-specific and cross-cutting planners.
- `hooks/plugins/variables/*.dart` – Variable classes (SharedDerivedVariables, ModeSpecificVariables, ComposedDerivedVariables).
- `hooks/plugins/composition.dart` – Defines composable template modules (ProjectModule, FeatureModule, ServiceModule).
- `hooks/plugins/hook_exception.dart` – Unified exception type for all hook errors.
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
3. `pre_gen.dart` delegates to `HookOrchestrator.plan()` which resolves a canonical "view" of the inputs through the planner system:
    - **Cross-cutting planners** (run first, in sequence):
      - **NamingPlanner**: Derives naming variants (project name in snake_case, camelCase, PascalCase).
      - **PresetPlanner**: Maps `preset` enum to internal boolean flags (`with_tests`, `with_docs`,
        `with_mcp`, `code_generation`, `ai_integration`, service toggles, feature toggles) and fly packages.
      - **PlatformPlanner**: Computes platform support flags from the platforms list.
    - **Mode-specific planner** (selected based on `generation_mode`):
      - **ProjectPlanner**: Derives project-specific variables (`is_project` flag only; platform flags are handled by PlatformPlanner).
      - **FeaturePlanner**: Derives feature-specific variables (screen types, state management, validation).
      - **ServicePlanner**: Derives service-specific variables (service types, capabilities, mocks).
    - The system composes `SharedDerivedVariables` (from cross-cutting planners) with `ModeSpecificVariables` (from mode-specific planner) into `ComposedDerivedVariables`.
    - Validates impossible or unsupported combinations (fail fast with `HookException` and actionable messages).
4. `pre_gen.dart` converts `ComposedDerivedVariables` to Mason variables and merges them into `context.vars`. From this point on, templates reference normalized flags; no complex logic remains in templates.
5. `pre_gen.dart` delegates to `HookOrchestrator.selectModules()` which uses `ModuleRegistry` to determine active modules and compute module-specific variables, then adds them to `context.vars`.
6. `post_gen.dart` delegates to `HookOrchestrator.reorganizeFiles()` which reorganizes generated files:
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
- Project/platforms: `platforms` list → `supports_ios/android/web/macos/windows/linux/desktop` (derived by PlatformPlanner, stored in SharedDerivedVariables).
- State management: `state_mgmt` (from PresetPlanner, default `riverpod`) → `use_riverpod`,
  `use_bloc`, `use_cubit`.

---

## 3) Planner System Architecture

The planner system uses a composition-based architecture with clear separation between cross-cutting and mode-specific concerns.

### 3.1 Planner Interfaces

**CrossCuttingPlanner** (see `hooks/plugins/planners/cross_cutting_planner.dart`):
- Handles variables shared across all modes (naming, metadata, platform flags).
- Implements `canHandle(BaseTemplateVariables)` and `derive(BaseTemplateVariables, SharedDerivedVariables, Logger)`.
- Planners are applied sequentially, with each receiving the accumulated `SharedDerivedVariables`.

**ModeSpecificPlanner** (see `hooks/plugins/planners/mode_specific_planner.dart`):
- Handles variables specific to a single generation mode (project, feature, or service).
- Implements `supportedMode` getter and `derive(BaseTemplateVariables, Logger)`.
- Returns one of `ProjectVariables`, `FeatureVariables`, or `ServiceVariables`.

### 3.2 Planner Factory

**PlannerFactory** (see `hooks/plugins/planners/planner_factory.dart`):
- Maintains registries of mode-specific and cross-cutting planners.
- Provides factory methods to retrieve appropriate planners.
- Default factory includes all standard planners.

### 3.3 Registered Planners

**Cross-cutting planners** (run in sequence):
- `NamingPlanner` – Derives naming variants (project name in different cases) and template metadata.
- `PresetPlanner` – Maps `preset` enum to internal boolean flags and fly packages.
- `PlatformPlanner` – Computes platform support flags from the platforms list.

**Mode-specific planners** (one selected per generation):
- `ProjectPlanner` – Derives project-specific variables (platform flags, project structure).
- `FeaturePlanner` – Derives feature-specific variables (screen types, state management, validation).
- `ServicePlanner` – Derives service-specific variables (service types, capabilities, mocks).

### 3.4 Composite Planner

**CompositePlanner** (see `hooks/plugins/planner.dart`):
- Orchestrates planner execution:
  1. Runs all applicable cross-cutting planners to build `SharedDerivedVariables`.
  2. Selects and runs the appropriate mode-specific planner.
  3. Composes results into `ComposedDerivedVariables`.
- Ensures that:
  1. Cross-cutting concerns are handled first (naming, presets, platforms).
  2. Mode-specific logic runs after shared derivation.
  3. Variables are properly composed and type-safe.

Adding a new planner is straightforward: implement the appropriate interface and register it in `PlannerFactory`.

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

1. **Module Selection**: `pre_gen.dart` determines which modules are active based on `generation_mode` and `ComposedDerivedVariables`
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

All hook errors use the unified `HookException` type for consistent, user-facing error messages:

- **Planner validation**: If a combination is unsupported (example: `service_type=analytics` + `with_caching=true`), the planner throws a `HookException` with a clear message.
- **Missing planners**: If no planner is found for a generation mode, `CompositePlanner` throws a `HookException` listing supported modes.
- **Module errors**: If module variable computation fails, `HookOrchestrator.selectModules()` throws a `HookException`.
- **Error propagation**: Both `pre_gen.dart` and `post_gen.dart` catch `HookException` and log it before rethrowing, ensuring errors are visible to users.

Failures occur **before** any files are generated, avoiding partial outputs. Add new constraints in the appropriate planner to centralize policy.

---

## 8) Testing and Goldens

The template uses a **two-tier testing approach**:

### 8.1 Unit Tests

Unit tests in `hooks/test/` provide focused testing of hook logic:

- **Planner tests** (`planner_test.dart`): Test variable derivation for all modes, error handling, and validation.
- **Module registry tests** (`module_registry_test.dart`): Test module resolution and disposition strategies.
- **Hook orchestrator tests** (`hook_orchestrator_test.dart`): Test file reorganization, module selection, and edge cases.

Run unit tests with `dart test` from the `hooks/` directory.

### 8.2 Scenario-Based Testing (End-to-End)

Scenario-based testing provides end-to-end validation:

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

- **Add variables**: `brick.yaml` (user‑facing) or compute them in a planner (derived).
- **Add planners**: Create a new planner implementing `CrossCuttingPlanner` or `ModeSpecificPlanner` and register it in `PlannerFactory`.
- **Add modules**: Create a new module class implementing `TemplateModule` in `composition.dart` and register it in `ModuleRegistry` with the appropriate `ModuleDisposition`.
- **Add service partials**: Place under `__brick__/modes/service/common/services/…` and include with `{{> modes/service/common/services/... }}`.
- **Add unit tests**: Add tests to `hooks/test/` for new planners or modules.
- **Add scenarios**: Put JSONs under `tools/scenarios/<mode>/` and add to `tools/run_scenarios.sh`.
- **Add goldens**: Copy `.scenario_out/<name>` into `test/goldens/<name>` after verifying correctness.

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

1. Cross-cutting planners run:
   - `NamingPlanner` derives `project_name=acme_app`, `project_name_snake=acme_app`, `project_name_camel=acmeApp`, `project_name_pascal=AcmeApp`, and template metadata.
   - `PresetPlanner` maps `preset=batteries_included` → all internal flags enabled (`with_tests=true`, `with_docs=true`, `with_mcp=true`, `code_generation=true`, `ai_integration=true`, etc.) and fly packages.
   - `PlatformPlanner` computes `supports_ios/android/web` flags from the platforms list.
2. `ProjectPlanner` (mode-specific) sets `is_project=true` and platform support flags.
3. Results are composed into `ComposedDerivedVariables` (shared + mode-specific).
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

1. Cross-cutting planners run:
   - `NamingPlanner` derives naming variants and template metadata.
   - `PresetPlanner` maps `preset=starter` → `with_viewmodel=true`, `with_navigation=true`,
     `with_validation=false`, `state_mgmt=riverpod`, and fly packages.
   - `PlatformPlanner` computes platform support flags.
2. `FeaturePlanner` (mode-specific) sets `is_feature=true`, `screen_type=list`, `is_list_screen=true`,
   `use_riverpod=true`, `feature=dashboard`, `component_name=dashboard`.
3. Results are composed into `ComposedDerivedVariables`.
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

1. Cross-cutting planners run:
   - `NamingPlanner` derives naming variants and template metadata.
   - `PresetPlanner` maps `preset=batteries_included` → `with_retry_logic=true`,
     `with_caching=true`, `with_interceptors=true`, `with_mocks=true`, and fly packages.
   - `PlatformPlanner` computes platform support flags.
2. `ServicePlanner` (mode-specific) sets `is_service=true`, `service_type=api`, `is_api_service=true`,
   `supports_retry/caching/interceptors=true`, `generate_mocks=true`, `feature=summary`, `component_name=summary`.
3. Results are composed into `ComposedDerivedVariables`.
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
- **Cross-cutting planner**: A planner that derives variables shared across all modes (e.g., naming, presets, platforms).
- **Mode-specific planner**: A planner that derives variables for a specific generation mode (project, feature, or service).
- **SharedDerivedVariables**: Class containing variables common to all modes (naming, metadata, platform flags).
- **ModeSpecificVariables**: Abstract class with implementations for each mode (ProjectVariables, FeatureVariables, ServiceVariables).
- **ComposedDerivedVariables**: Class that composes shared and mode-specific variables into a unified result.

---

With this architecture and workflow, the Fly Foundation template stays unified, testable, and
scalable—ready for additional modes, platforms, and architectural patterns without sacrificing
maintainability.


