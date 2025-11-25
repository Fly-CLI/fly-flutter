<!-- 64ee6f80-0963-4c3c-b0fe-d3b6b1aec5f5 fde967f2-d561-4d93-bee8-6cc518e61f97 -->
# Phase 1 Week 1 – Unified Template & Critical Standards (Greenfield, Breaking Changes Allowed)

## Context and Deep Analysis

- **Plan focus**: The Week 1 slice of the development plan targets four things: a unified Mason brick (`fly_foundation`), explicit `build.yaml` configuration (H1), accessibility best practices in generated widgets (H4), and a comprehensive quick start guide (H6). Together, these shift Fly from multiple loosely documented bricks to a single, standards-driven entry point for new projects.
- **Current template state**: `fly_cli` uses separate bricks under `templates/projects/{minimal,riverpod}` and `templates/components/{screen,service}` with their own `brick.yaml`/`template.yaml`, no unified `generation_mode`, and no explicit `build.yaml` in the project bricks. The existing riverpod brick defines router/theme and a single home feature but does not embed accessibility guidance or build configuration.
- **Template management state**: `TemplateManager` and `BrickRegistry` currently discover bricks only in `templates/projects/` and `templates/components/`, infer `BrickType` from the folder path, and perform generic type/required checks on variables. There is no awareness of `generation_mode` and no cross-variable validation (e.g., “project mode requires `project_name`, `organization`, `platforms`).
- **Technical constraint**: This is a **greenfield rewrite** of the template system and **backward compatibility is not required**. Breaking changes to template layout, brick names, and CLI behavior are acceptable as long as the new `fly_foundation` flow is coherent and well-documented.
- **Implication for Week 1**:
- Introducing `fly_foundation` can fully replace the legacy bricks and their layouts in one step, rather than staging deprecation.
- `BrickRegistry` and `TemplateManager` can be updated to assume the new structure and naming without keeping fallback logic for old layouts.
- Accessibility improvements must be baked into the base screen/presentation templates and theme (semantics, keyboard navigation, contrast) so that all generated projects inherit them by default.
- The quick start guide should live both in the new template README and be reflected in existing docs so the developer experience is consistent.

## High-Level Week 1 Goals

1. **Unify project templating** around a `fly_foundation` brick that is the **only** supported project template going forward and is future-ready for all modes.
2. **Embed an explicit `build.yaml`** and associated documentation into the project template so all generated projects have a standard generator setup.
3. **Raise accessibility standards** in the generated code by updating base UI templates and themes to follow WCAG-aligned patterns.
4. **Provide a quick start path** that lets a new user install Fly, generate a project with `fly_foundation`, run it, and understand next steps in under 5 minutes.

## Implementation Plan – Week 1 Tasks

### 1. Unified Template Structure (`fly_foundation`)

- **1.1 Introduce `fly_foundation` template directory as the primary project brick**
- Create a new brick directory that aligns with or replaces existing discovery rules:
- Preferred: `templates/projects/fly_foundation/…` so `BrickRegistry` auto-detects it as `BrickType.project` while still allowing later mode expansion.
- Alternatively, if you want a cleaner top-level layout, move to `templates/fly_foundation/…` and update `BrickRegistry.discoverBricks` to scan top-level templates and classify `fly_foundation` explicitly as `BrickType.project`.
- Inside the chosen directory, create the layout described in the plan:
- `__brick__/` containing project-mode files guarded by `{{#is_project}}` and stubs for screen/service/provider guarded by their respective flags for future phases.
- `brick.yaml` with `generation_mode` and all variable definitions from section 2.2 of the plan.
- `template.yaml` with Fly CLI-specific metadata, versioning information, SDK constraints, and compatibility info.

- **1.2 Port reference architecture into `__brick__/` project structure**
- Use `examples/foundation_project` as the canonical source for project layout and base patterns:
- `lib/main.dart` wiring `GlobalContainer`, Riverpod, navigation, theme, and localization.
- `lib/core/foundation/screen/{base_screen.dart, base_view_model.dart}` extending `FlyScreen`/`FlyViewModel`.
- `lib/shared/navigation/{app_router.dart, app_navigator.dart, feature_screen_type.dart}` for enum-based navigation.
- `lib/shared/themes/app_theme.dart` for Material 3 themes.
- `l10n/` and `l10n.yaml` for localization.
- Adapt these files into Mustache templates that:
- Respect the directory/variable conventions in the plan (e.g. `{{project_name.snakeCase()}}`, `{{feature}}`, `{{name}}`).
- Use `{{#is_project}}` guards around project-only files so the brick can later serve component modes.

- **1.3 Define `brick.yaml` and `template.yaml` with full variable metadata**
- Implement the variable schema described in the plan, including:
- `generation_mode` enum (`project`, `screen`, `service`, `provider`) with default `project`.
- Project-mode variables: `project_name`, `organization`, `platforms`, `description`, `template`, `features`, `min_flutter_sdk`, `min_dart_sdk`, `with_mcp`, `with_tests`, `with_docs`, `fly_packages`, `code_generation`, `ai_integration`.
- Component-mode variables: `name`, `feature`, plus mode-specific ones (`screen_type`, `with_viewmodel`, etc.), even if only partially used in Week 1.
- Ensure `template.yaml` includes:
- `name: fly_foundation`, semantic `version`, `description`, `min_flutter_sdk`, `min_dart_sdk`.
- A compatibility block so `TemplateManager`/`CompatibilityChecker` can enforce SDK and CLI version constraints.

- **1.4 Remove legacy templates and point the CLI exclusively at `fly_foundation`**
- Delete the old bricks once `fly_foundation` is in place:
- Remove `templates/projects/minimal` and `templates/projects/riverpod`.
- Remove `templates/components/screen` and `templates/components/service` (these will be reintroduced as mode-specific branches of `fly_foundation` in later phases).
- Update `BrickRegistry`/`TemplateManager` behavior as needed so:
- `fly_foundation` is discovered as the canonical project template.
- Any references to legacy brick names (e.g. `riverpod`) in tests or docs are updated.
- Update CLI command wiring (in the create/generate features) so:
- `fly create` uses `fly_foundation` with `generation_mode=project`.
- Screen/service/provider commands are planned to use `fly_foundation` modes in later phases; for Week 1, it is acceptable if only project generation is wired while component commands are temporarily disabled or clearly marked as unsupported.
- Accept and fix any failing tests as part of this rewrite rather than preserving old behaviors.

- **1.5 Implement generation-mode-aware variable validation (foundation)**
- Extend the existing `_validateVariables` logic in `TemplateManager` and/or add a dedicated validator in the templates core to enforce mode-specific rules:
- When `generation_mode == project`: require `project_name`, `organization`, `platforms`; validate `template` choice and `fly_packages` against allowed values.
- When `generation_mode != project`: require `name` and `feature` and validate combinations like `screen_type`.
- For Week 1, focus on project-mode validation so `fly_foundation` project generation is robust; structure the validator so adding full screen/service/provider rules in later phases is straightforward.
- Add unit tests under `packages/fly_cli/test/core/scaffolding/` to cover both happy-path and failure cases, matching the Week 1 deliverable “Unit tests for variable validation”.

### 2. H1 – Explicit `build.yaml` Configuration

- **2.1 Design `build.yaml` template for generated projects**
- Create a `build.yaml` inside `__brick__/` for project mode that:
- Declares the `$default` target and configures the expected builders: `riverpod_generator`, `drift_dev`, `auto_mappr`, `json_serializable`, and any others used in the reference project.
- Specifies sensible default options (e.g., output locations, ignored files) and notes where users may tune them.
- Orders builders to align with the performance guidance from the plan (e.g. riverpod → drift → auto_mappr → json_serializable), within the constraints of Dart’s build system.

- **2.2 Integrate incremental build considerations**
- Ensure the `build.yaml` is compatible with `build_runner watch` and does not introduce unnecessary rebuild triggers.
- Document, in comments or a companion doc, how the configuration supports incremental builds and any recommended flags (e.g. `--delete-conflicting-outputs` for clean builds, `watch` for dev).

- **2.3 Wire `build.yaml` into project-mode generation**
- Make sure `build.yaml` is included only for `{{#is_project}}` so component generations do not create a duplicate build configuration when those modes are implemented.
- Verify that generated projects compile and that code generation runs cleanly with the configured builders (this will be fully validated later but should be feasible to smoke-test during Week 1 implementation).

### 3. H4 – Accessibility Best Practices in Templates

- **3.1 Establish accessibility baseline from Flutter/WCAG guidance**
- Review Flutter’s official accessibility docs and WCAG 2.1 AA requirements relevant to mobile and web UIs to identify concrete patterns you can encode in templates (semantics, focus order, contrast, labels).

- **3.2 Update base screen and widgets in `fly_foundation`**
- In `BaseScreen` and initial feature screens:
- Wrap appropriate regions with `Semantics` widgets and provide meaningful `label`, `hint`, and `value` where appropriate.
- Ensure tappable elements have adequate size and focusability, and support keyboard navigation (e.g., `Focus`/`FocusTraversalGroup` where needed) so generated code works well on web/desktop.
- In `app_theme.dart`:
- Configure color schemes to meet WCAG 2.1 AA contrast guidelines for primary text vs background and interactive elements.
- Provide both light and dark themes with accessible defaults.

- **3.3 Add accessibility docs and tests scoped to the template**
- Add an “Accessibility” section to the `fly_foundation` README (or a linked doc) explaining:
- The built-in accessibility patterns.
- How to extend them when adding new screens.
- Introduce minimal tests (even snapshot/widget tests) in the brick’s `test/` directory that verify:
- Key widgets include semantics labels.
- Common accessibility regressions (e.g., missing labels on key buttons) are less likely by default.
- Ensure Week 1 keeps the scope to foundational patterns; deeper audits and coverage can be expanded in later phases.

### 4. H6 – Comprehensive Quick Start Guide

- **4.1 Draft the quick start flow**
- Based on the plan’s outline, define a concise path that covers:
- Installing Fly CLI and any dependencies (Mason, Flutter version constraints).
- Creating a new project using `fly_foundation` (e.g., `fly create --template fly_foundation` or the equivalent command once wired).
- Running the generated project on at least one platform.
- Running `build_runner` once and understanding what is generated.

- **4.2 Implement the quick start in template docs**
- Update or create the `README.md` inside the `fly_foundation/__brick__/` to include:
- A “Quick Start” section that can be followed in under 5 minutes.
- A “Next Steps” section linking to adding a new screen, adding a service, and enabling MCP/AI integration (even if those flows are implemented in later weeks, outline the intent).
- Cross-link from `packages/fly_cli/README.md` and top-level docs (e.g. `docs/guide/quickstart.md`) so that documentation consistently references `fly_foundation` as the primary project template.

- **4.3 Add troubleshooting notes for common first-run issues**
- Include a short troubleshooting subsection focused on Week 1 scope:
- Missing Flutter or incompatible version.
- Mason not installed or brick not found.
- Build errors related to `build_runner` or missing dependencies.

## Validation and Risk Management

- **Template stability**: Because backward compatibility is not required, prioritize correctness and clarity of the new `fly_foundation` flow over reproducing legacy behaviors. Use tests to validate the new path rather than comparing against old bricks.
- **Discovery/Type risks**: If `fly_foundation` is placed outside `templates/projects/`, update `BrickRegistry.discoverBricks` and its tests in the same batch to avoid broken brick discovery and ensure `fly_foundation` is classified as a project brick.
- **CLI behavior**: Align `fly create` (and later component commands) tightly with `fly_foundation` semantics, updating or removing flags/options that only made sense in the legacy multi-brick world.
- **Success checks for Week 1**:
- A new project generated from `fly_foundation` compiles, runs, and has a working router/theme skeleton.
- `build.yaml` is present and functional in the generated project.
- Base templates exhibit obvious accessibility improvements (semantics, theme contrast) over the prior bricks.
- A new user can follow the quick start guide and get a running project without needing additional undocumented steps.

### To-dos

- [ ] Create the unified `fly_foundation` brick directory, port the reference architecture, and wire brick/template metadata for project mode.
- [ ] Implement generation-mode-aware variable validation for project mode and add unit tests in the templates core.
- [ ] Add an explicit `build.yaml` to the project template with configured builders and integrate it into project-mode generation.
- [ ] Update base UI templates and theme to embed accessibility best practices and add minimal accessibility tests/docs.
- [ ] Author and wire a comprehensive quick start guide into the `fly_foundation` README and CLI/docs references.