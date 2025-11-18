# Fly Foundation Template – Developer Onboarding Guide

This document explains how the Fly Foundation Mason brick is organized, how generation logic works, how to test and validate changes, and how to safely extend the template with new flags, modes, and partials.

It is intended for maintainers and contributors working inside `packages/fly_cli/templates/projects/fly_foundation`.

---

## 1. High‑Level Architecture

The template follows a “thin templates, smart hooks” approach:

- `brick.yaml` defines the user‑facing variables (with types, defaults, prompts).
- `hooks/pre_gen.dart` derives additional flags and enforces constraints. It delegates to a small, pluggable planner system under `hooks/plugins/`.
- Templates under `__brick__/` remain mostly declarative, using simple derived flags and small reusable partials within their respective modules.
- A scenario harness in `tools/` generates output for representative configurations and compares against committed goldens in `test/goldens/`. A CI workflow runs these checks on pull requests.
- A small metrics script counts inline conditional density to keep complexity in check.

This structure preserves a single unified brick while scaling across modes (`project`, `feature`, `service`, and future ones), platforms, and state‑management variants.

---

## 2. Directory Layout

Key paths you will work with:

- `brick.yaml`: Variable schema, defaults, prompts.
- `__brick__/`: Mustache templates for files written to disk.
  - `modes/service/common/`: Service partials used by service templates (e.g., service snippets).
  - Existing mode folders/files will progressively move under a `modes/` tree as the template evolves (not required to contribute now).
- `hooks/`: Hook scripts executed by Mason.
  - `pre_gen.dart`: Thin orchestration layer that delegates to `HookOrchestrator`.
  - `post_gen.dart`: Thin orchestration layer that delegates file reorganization to `HookOrchestrator`.
  - `plugins/`: Core hook logic and planner system:
    - `hook_orchestrator.dart`: Core orchestration API (`plan`, `selectModules`, `reorganizeFiles`).
    - `module_registry.dart`: Data-driven module registry that manages template modules and their composition rules.
    - `planner.dart`: Composite planner that orchestrates planner execution.
    - `hook_exception.dart`: Unified exception type for all hook errors.
    - `planners/`: Planner implementations:
      - `mode_specific_planner.dart`: Interface for mode-specific planners.
      - `cross_cutting_planner.dart`: Interface for cross-cutting planners.
      - `planner_factory.dart`: Factory for creating and managing planners.
      - `project_planner.dart`, `feature_planner.dart`, `service_planner.dart`: Mode-specific planners.
      - `naming_planner.dart`, `preset_planner.dart`, `platform_planner.dart`: Cross-cutting planners.
    - `variables/`: Variable classes:
      - `shared_derived_variables.dart`: Common variables across all modes (includes platform flags).
      - `mode_specific_variables.dart`: Abstract class for mode-specific variables.
      - `project_variables.dart`, `feature_variables.dart`, `service_variables.dart`: Mode-specific implementations.
      - `composed_derived_variables.dart`: Composed result of shared + mode-specific variables.
    - `composition.dart`: Template module definitions (ProjectModule, FeatureModule, ServiceModule).
- `tools/`: Local developer utilities.
  - `run_scenarios.sh`: Scenario/golden runner (non‑interactive).
  - `scenarios/`: JSON answers for sample runs (services, features, project).
  - `metrics/count_conditionals.dart`: Counts conditional tags and reports density.
- `test/goldens/`: Golden outputs by scenario (committed).
- `.github/workflows/template-ci.yml`: CI to run scenarios and metrics in PRs.

---

## 3. Variables and Derived Flags

### 3.1 User Variables (from `brick.yaml`)

The public schema is minimal and consists of:

- **Core**: `generation_mode` (enum: `project`, `feature`, `service`), `name` (string), `description` (string), `organization` (string), `platforms` (list), `preset` (enum: `starter`, `batteries_included`, `minimal`).

All other variables (e.g., `project_name`, `feature`, `component_name`, `with_tests`, `with_docs`, `with_mcp`, `code_generation`, `ai_integration`, `screen_type`, `service_type`, `with_retry_logic`, `with_caching`, `with_interceptors`, `with_mocks`, `state_mgmt`, etc.) are **derived internally** by planner plugins and are not user-facing.

Always prefer adding new variables to `brick.yaml` if they are user‑configurable. If not user‑facing, derive in hooks.

### 3.2 Derived Flags (from hooks)

The planner system computes easy‑to‑consume flags so templates don't need to embed complex logic. The system consists of:

1. **Cross-cutting planners** (run first, in sequence):
   - **NamingPlanner**: Derives naming variants (project name in snake_case, camelCase, PascalCase) and template metadata.
   - **PresetPlanner**: Maps `preset` enum to internal boolean flags (`with_tests`, `with_docs`, `with_mcp`, `code_generation`, `ai_integration`, service toggles, feature toggles, `state_mgmt`) and fly packages.
   - **PlatformPlanner**: Computes platform support flags from the platforms list.
2. **Mode-specific planner** (selected based on `generation_mode`):
   - **ProjectPlanner**: Derives project-specific variables (`is_project` flag only; platform flags are handled by PlatformPlanner).
   - **FeaturePlanner**: Derives feature-specific variables (screen types, state management, validation, naming).
   - **ServicePlanner**: Derives service-specific variables (service types, capabilities, mocks, naming).
3. **Composition**: Results are composed into `ComposedDerivedVariables` (shared + mode-specific).

Examples of derived flags:

- Mode: `active_mode` (one of `project`, `feature`, `service`), `is_project`, `is_feature`, `is_service`
- Cross-cutting: `with_tests`, `with_docs`, `with_mcp`, `code_generation`, `ai_integration` (from preset)
- Feature: `is_form_screen`, `requires_validation`, `with_navigation`, `use_riverpod`, `use_bloc`, `use_cubit`
- Service: `is_api_service`, `supports_retry`, `supports_caching`, `supports_interceptors`, `generate_mocks`
- Project/platforms: `supports_ios`, `supports_android`, `supports_web`, `supports_macos`, `supports_windows`, `supports_linux`, `supports_desktop`

Use these flags inside templates with `{{#flag}} ... {{/flag}}` instead of recomputing conditions repeatedly.

---

## 4. Hooks and the Planner Plugins

### 4.1 `hooks/pre_gen.dart`

Entry point run by Mason before file generation. It:

1. Reads current variables from `context.vars` and creates `BaseTemplateVariables`.
2. Delegates to `HookOrchestrator.plan()` which:
   - Applies preset configuration if specified.
   - Runs the `CompositePlanner` which:
     - Executes all cross-cutting planners to build `SharedDerivedVariables`.
     - Selects and runs the appropriate mode-specific planner.
     - Composes results into `ComposedDerivedVariables`.
3. Converts `ComposedDerivedVariables` to Mason variables and merges them into `context.vars`.
4. Delegates to `HookOrchestrator.selectModules()` to determine active modules and compute module-specific variables.
5. Adds module metadata and module-specific variables to `context.vars`.

All errors are caught and rethrown as `HookException` with clear, user-facing messages.

This keeps templates thin and provides a central place to validate and evolve generator logic.

### 4.2 Planner Interfaces

**CrossCuttingPlanner** (located in `hooks/plugins/planners/cross_cutting_planner.dart`):

```dart
abstract class CrossCuttingPlanner {
  bool canHandle(BaseTemplateVariables base);
  SharedDerivedVariables derive(
    BaseTemplateVariables base,
    SharedDerivedVariables acc,
    Logger logger,
  );
}
```

**ModeSpecificPlanner** (located in `hooks/plugins/planners/mode_specific_planner.dart`):

```dart
abstract class ModeSpecificPlanner {
  GenerationMode get supportedMode;
  ModeSpecificVariables derive(
    BaseTemplateVariables base,
    Logger logger,
  );
}
```

The `CompositePlanner` orchestrates planner execution, running cross-cutting planners first, then the mode-specific planner, and composing the results.

All planner errors are thrown as `HookException` with clear, actionable messages.

### 4.3 Planner Implementations

**Cross-cutting planners** (in `hooks/plugins/planners/`):
- `naming_planner.dart`: Derives naming variants and template metadata.
- `preset_planner.dart`: Maps preset enum to internal flags and fly packages.
- `platform_planner.dart`: Computes platform support flags.

**Mode-specific planners** (in `hooks/plugins/planners/`):
- `project_planner.dart`: Derives project-specific variables (`is_project` flag only; platform flags are handled by PlatformPlanner).
- `feature_planner.dart`: Derives feature-specific variables (screen types, state management, validation, naming).
- `service_planner.dart`: Derives service-specific variables (service types, capabilities, mocks, naming) and enforces constraints.

**Note on platform flags**: `PlatformPlanner` is the single source of truth for all platform flags (`supports_ios`, `supports_android`, etc.). These flags are stored in `SharedDerivedVariables` and are available to all generation modes. `ProjectPlanner` no longer duplicates platform flags.

---

## 5. Templates and Partials

### 5.1 Location and Conventions

- Service partials are located under `__brick__/modes/service/common/services/` and included in service templates via Mustache partial includes:
  - Example partials for services:
    - `modes/service/common/services/interceptors_types.dart`
    - `modes/service/common/services/interceptors_run.dart`
    - `modes/service/common/services/caching_field.dart`
    - `modes/service/common/services/caching_get.dart`
    - `modes/service/common/services/caching_set.dart`
    - `modes/service/common/services/retry_execute.dart`

### 5.2 Example: Service Template Using Partials

File: `__brick__/lib/core/services/{{feature}}/{{#is_service}}{{component_name}}_service.dart{{/is_service}}`

- Service templates import shared types/logic with `{{> modes/service/common/services/... }}`.
- Uses derived flags like `{{#supports_retry}}` and `{{#supports_interceptors}}` to toggle sections.
- Caching logic is injected via `caching_field`, `caching_get`, and `caching_set` partials.

### 5.3 Example: Feature Screen Using Derived Flags

File: `__brick__/lib/features/{{feature}}/presentation/screen/{{#is_feature}}{{component_name}}_screen.dart{{/is_feature}}`

- Replaced prior `screen_type_*` checks with `{{#is_form_screen}}`.
- Leaves navigation wiring under `{{#with_navigation}}`.
- Future additions for state management can switch wiring with `{{#use_bloc}}` etc., without changing screen layout code.

---

## 6. Scenarios, Goldens, and CI

### 6.1 Scenarios

Non‑interactive scenario inputs live in `tools/scenarios/`:

- Services: `services/api_retry_cache.json`, `services/api_minimal.json`, `services/local_minimal.json`
- Features: `features/list_riverpod.json`, `features/form_with_validation.json`
- Projects: `project/default_foundation.json`, `project/minimal_no_tests.json`

Each file is a JSON map matching `brick.yaml` variables; values are fed to `mason make` during automated checks.

### 6.2 Running Scenarios Locally

```bash
chmod +x tools/run_scenarios.sh
tools/run_scenarios.sh
```

For any scenario without an existing golden, the script will prompt how to accept the current output as a baseline:

```bash
cp -R packages/fly_cli/templates/projects/fly_foundation/.scenario_out/<name> \
      packages/fly_cli/templates/projects/fly_foundation/test/goldens/<name>
```

Commit goldens so CI can compare against them.

### 6.3 CI Workflow

File: `.github/workflows/template-ci.yml`

- Installs Mason CLI
- Runs all scenarios and diffs with goldens
- Prints conditional density metrics

CI prevents regressions by failing when generated output deviates unexpectedly or when the script returns diffs.

---

## 7. Complexity Metrics

Script: `tools/metrics/count_conditionals.dart`

Reports:

- Total files and lines under `__brick__/`
- Count of conditional tags (`{{#...}}`, `{{^...}}`)
- Inline conditional density (conditional tags / lines)

Use this to monitor complexity trends after large changes. Aim to reduce density by moving branching logic into hooks and partials.

---

## 8. Contributor Workflow

1. Clone the monorepo and bootstrap tooling.
2. Make changes in:
   - `brick.yaml` (new user‑facing variables)
   - `hooks/` (derivations, constraints, or new plugins)
   - `__brick__/` (templates and partials)
3. Add or update scenarios under `tools/scenarios/` to cover new flags/paths.
4. Run `tools/run_scenarios.sh` and accept/update goldens intentionally.
5. Run metrics to check conditional density:
   - `dart tools/metrics/count_conditionals.dart`
6. Update docs when changing variables, flows, or structure:
   - `README.md` and/or `CONTRIBUTING_TEMPLATE.md`
7. Commit and open a PR. CI will validate scenarios and report metrics.

---

## 9. How to Add a New Flag or Mode

### 9.1 New User‑Facing Flag

1. Add the variable to `brick.yaml` (choose appropriate type and defaults).
2. If needed, derive computed flags in an existing plugin (e.g., service or feature).
3. Use the new derived flags or variable in templates by adding small partials (preferred) or targeted inline conditionals.
4. Add a scenario that exercises both true/false branches (or multiple enum values).
5. Run scenarios and update goldens.

### 9.2 New Mode (e.g., `provider`, `repository`, `widget`, `bloc/cubit` variants)

1. Add support in `brick.yaml` (`generation_mode` values or auxiliary flags).
2. Create a new mode-specific variable class in `hooks/plugins/variables/` (e.g., `provider_variables.dart`) extending `ModeSpecificVariables`.
3. Create a new mode-specific planner in `hooks/plugins/planners/` (e.g., `provider_planner.dart`) implementing `ModeSpecificPlanner` and register it in `PlannerFactory`.
4. Create a new module class in `hooks/plugins/composition.dart` (e.g., `ProviderModule`) implementing `TemplateModule`.
5. Register the new module in `ModuleRegistry` (in `hooks/plugins/module_registry.dart`) with the appropriate `ModuleDisposition`:
   - `moveToRoot`: For modules that should move files to the output root (like project mode).
   - `mergeIntoExisting`: For modules that should merge files into existing structure (like feature/service modes).
6. Start with a minimal set of templates for the new mode. Prefer:
   - Service partials in `__brick__/modes/service/common/services/...`
   - Mode‑scoped templates under `__brick__/modes/<mode>/...` (as the repository evolves)
7. Add scenarios and goldens for the new mode.
8. Iterate: keep mode logic inside the planner, and keep templates declarative.

---

## 10. Style & Naming Guidelines

- Favor derived flags: `is_form_screen`, `supports_retry`, `use_riverpod`.
- Keep partials small; avoid deeply nested blocks inside partials.
- Prefer explicit names over abbreviations (e.g., `supports_interceptors`).
- Do not duplicate logic across templates; extract into module-specific partials (e.g., `modes/service/common/services/` for service partials).
- Keep comments concise in templates; reserve detailed rationale for this document or inline in hooks.

---

## 11. Common Pitfalls and Anti‑Patterns

- Excessive inline conditionals (`{{#...}}` everywhere): Move logic into hooks and expose a simple flag.
- Copy‑pasted mode templates: Extract shared parts into module-specific partials (e.g., `modes/service/common/services/`) and keep mode files small.
- Unvalidated flags: Add constraints in the relevant plugin so invalid combos fail fast with good error messages.
- Large, unreviewed changes to template outputs: Update scenarios/goldens and include a brief explanation in the PR.

---

## 12. FAQ

Q: How do I quickly check what the planner is producing?  
A: Temporarily log inside a plugin or add a debug knob (e.g., `__debug_pre_gen=true`) and print `context.vars`. Remove before submitting.

Q: Where should I put cross‑cutting logic (e.g., platform‑specific tweaks)?  
A: Add or extend a plugin (e.g., project/platform plugin) and expose normalized flags like `supports_web`. Reference those flags in templates.

Q: Do I need to restructure everything into `modes/` right now?  
A: No. The current layout already benefits from the planner + partials. We will gradually partition files into `modes/` as complexity grows.

Q: How do I test locally without prompts?  
A: Use the scenario files: `tools/run_scenarios.sh` runs `mason make` with the provided JSON answers.

Q: How do I test hook logic?  
A: The hooks package includes unit tests in `hooks/test/` that test planners, module resolution, and file reorganization. Run them with `dart test` from the `hooks/` directory. For end-to-end testing, use scenario/golden tests in `tools/run_scenarios.sh`.

---

## 13. Checklists

### Adding a New Feature/Flag

- [ ] Variable added to `brick.yaml` (if user‑facing)
- [ ] Derived flags added to a plugin (or new plugin created)
- [ ] Constraints validated in plugin
- [ ] Partials created/updated in appropriate module directories (e.g., `__brick__/modes/service/common/services/`)
- [ ] Template uses derived flags, minimal inline conditionals
- [ ] Scenario(s) added; goldens updated
- [ ] Metrics reviewed
- [ ] Docs updated

### Reviewing a Template PR

- [ ] Hooks logic has tests or at least scenario coverage
- [ ] New scenarios cover new branches (positive/negative)
- [ ] Goldens reflect intended changes only
- [ ] Inline conditionals reduced or stable
- [ ] Naming is explicit, partials are small and reusable
- [ ] Docs updated (variables, usage, or contributor notes)

---

## 14. Next Steps and Evolution

- As complexity grows, we can:
  - Add additional plugins for state management or platform packs.
  - Adopt a `modes/` structure more fully with thin mode‑specific templates and module-specific partial libraries.
  - Introduce a declarative constraints file (e.g., `template.yaml`) for advanced validation rules consumed by plugins.

This onboarding guide should equip you to confidently navigate, test, and extend the Fly Foundation template while keeping complexity manageable and the developer experience strong.


