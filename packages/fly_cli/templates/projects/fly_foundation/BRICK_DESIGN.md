## Fly Foundation Brick Design

This document describes the **public configuration surface** and **architecture decisions** for the
`fly_foundation` brick used by the Fly CLI.

The goal of this brick is to provide a **minimal, simple, and powerful** user-facing configuration
while hiding internal wiring and advanced options behind **opinionated defaults** and **presets**.

---

## Overview

- **Brick name**: `fly_foundation`
- **Description**: Unified Fly CLI foundation template for projects, features, and services.
- **Brick version**: `1.0.0` (schema rewritten, but version kept stable for now).

The brick supports three main workflows, controlled by a single required field: `generation_mode`.

- **Project**: scaffold a new Fly-based Flutter application.
- **Feature**: add a new feature/module to an existing Fly project.
- **Service**: add a new service (e.g., API or local/service layer) to an existing Fly project.

All other configuration surfaces are designed to be:

- **Shared across modes** where possible.
- **High signal / low noise** (few fields, big impact).
- **Backed by presets** instead of many individual flags.

---

## Current `brick.yaml` schema

The `brick.yaml` file lives at:

- `packages/fly_cli/templates/projects/fly_foundation/brick.yaml`

Key sections:

- Top-level metadata (`name`, `description`, `version`).
- `vars` section (user-facing configuration).

### Top-level metadata

From `brick.yaml`:

```1:4:packages/fly_cli/templates/projects/fly_foundation/brick.yaml
name: fly_foundation
description: Unified Fly CLI foundation template for projects, features, and services
version: 1.0.0
```

- **`name`**: Logical name of the brick.
- **`description`**: Human-readable summary shown in CLI help / tooling.
- **`version`**: Brick version. Even though the schema was simplified, the version is pinned at
  `1.0.0` and can be bumped when you decide to signal the new interface formally.

---

## `vars` – User-facing configuration

All user-visible configuration lives under the `vars:` key. The design is:

- **Single primary switch**: `generation_mode`.
- **Shared metadata**: `name`, `description`, `organization`.
- **Few high-impact knobs**: `platforms`, `preset`.
- **No internal flags** (e.g. `is_project`, `is_feature`, `is_service` are removed).

### `generation_mode`

```12:20:packages/fly_cli/templates/projects/fly_foundation/brick.yaml
generation_mode:
  type: enum
  description: What do you want to generate?
  default: project
  values:
    - project
    - feature
    - service
  prompt: What would you like to generate? (project / feature / service)
```

- **Type**: `enum`.
- **Allowed values**:
    - `project`: generate a new Flutter application using Fly foundation.
    - `feature`: generate a new feature/module inside an existing project.
    - `service`: generate a service (e.g. API, storage, analytics) inside an existing project.
- **Default**: `project`.

**Architectural decision**:

- This is the **only field** that decides which workflow the CLI executes.
- All internal flags (`is_project`, `is_feature`, `is_service`) have been **removed**.
- Internal logic in the CLI/brick templates should branch on `generation_mode` directly.

---

### Shared metadata: `name`, `description`, `organization`

```27:41:packages/fly_cli/templates/projects/fly_foundation/brick.yaml
name:
  type: string
  description: Name of the thing you are generating (project, feature, or service)
  prompt: What is the name? (project / feature / service)

description:
  type: string
  description: Short description used in README and metadata
  default: A new Fly foundation project

organization:
  type: string
  description: Reverse-DNS organization identifier
  default: com.example
  prompt: What is your organization (e.g. com.example)?
```

- **`name`**
    - Used as **project name**, **feature name**, or **service name** depending on
      `generation_mode`.
    - Single, generic field to keep the UX consistent across modes.

- **`description`**
    - Short human-friendly text used in `README`, `pubspec`, and other metadata.
    - Default: `"A new Fly foundation project"`.
    - Can be reused for features/services as a simple one-line summary.

- **`organization`**
    - Reverse-DNS identifier (e.g. `com.example`).
    - Used wherever the project / bundle id / namespace requires an org string.
    - Prompted explicitly for clarity.

**Architectural decision**:

- Rather than having **mode-specific names** (e.g. `project_name`, `feature_name`, `service_name`),
  the brick exposes a single `name` and relies on context (`generation_mode`) to interpret it.
- This keeps the schema smaller and more consistent while still allowing the templates to specialize
  behavior by mode.

---

### High-impact options: `platforms`, `preset`

```50:64:packages/fly_cli/templates/projects/fly_foundation/brick.yaml
platforms:
  type: list
  description: Target platforms for Flutter tooling
  default: [ ios, android ]
  prompt: Which platforms do you want to support? (comma-separated, e.g. ios, android)

preset:
  type: enum
  description: Opinionated stack preset (controls tests, docs, AI, services, etc.)
  default: starter
  values:
    - starter           # Balanced defaults for most apps
    - batteries_included  # Everything turned on; great for exploration
    - minimal           # As little as possible; you add things as you go
  prompt: Which preset do you want? (starter / batteries_included / minimal)
```

#### `platforms`

- **Type**: `list`.
- **Default**: `[ ios, android ]`.
- **Usage**:
    - Controls which target platforms are initially wired/configured in the project.
    - Typically determines scaffolding for `ios` / `android` and can be extended to `web`, `macos`,
      etc.

#### `preset`

- **Type**: `enum`.
- **Purpose**: A **high-level preset** that turns many low-level options on/off internally.
- **Values**:
    - `starter`
        - Balanced defaults for most teams.
        - Good mix of tests, docs, and productivity tooling without being overwhelming.
    - `batteries_included`
        - Enables **everything** the foundation knows how to wire up (tests, docs, AI, mocks, etc.).
        - Best for exploration, sandboxes, and internal demos.
    - `minimal`
        - As little as possible.
        - Lightweight scaffold with minimal dependencies and extras; ideal if you want full control.

**Architectural decision**:

- Many former booleans (e.g. `with_tests`, `with_docs`, `with_mcp`, `code_generation`,
  `ai_integration`, `with_mocks`, etc.) have been **collapsed** into this single `preset` field.
- The CLI or templates are responsible for mapping each **preset** to internal behavior, for
  example:
    - `starter`: enable tests, core docs, core services; enable AI only where it adds clear value.
    - `batteries_included`: enable all optional components and integrations.
    - `minimal`: disable optional components, keep only the minimum required core.
- This reduces user-facing complexity while still allowing sophisticated internal behavior.

**Implementation details**:

- Presets are implemented as a `FoundationPreset` enum in `hooks/plugins/presets.dart` with
  configuration fields for each preset value.
- The `PresetPlanner` plugin (in `hooks/plugins/preset_mode.dart`) maps each preset enum to internal
  boolean flags that templates consume:
  - Cross-cutting: `with_tests`, `with_docs`, `with_mcp`, `code_generation`, `ai_integration`
  - Service-related: `with_retry_logic`, `with_caching`, `with_interceptors`, `with_mocks`
  - Feature-related: `with_viewmodel`, `with_validation`, `with_navigation`, `state_mgmt`
- Concrete preset mappings:
  - `starter`: tests=true, docs=true, mcp=true, codegen=true, ai=true; service extras=false (except mocks=true); feature validation=false
  - `batteries_included`: all flags enabled (tests, docs, mcp, codegen, ai, all service extras, feature validation)
  - `minimal`: tests=false, docs=false, mcp=false, ai=false; codegen=true; service extras=false; feature validation=false, navigation=false

---

## Removed / implicit configuration

The previous `brick.yaml` contained many additional fields, including:

- Internal flags:
    - `is_project`, `is_feature`, `is_service`.
- Version and state-management details:
    - `min_flutter_sdk`, `min_dart_sdk`, `state_mgmt`.
- Package lists:
    - `fly_packages`.
- Mode-specific details and toggles:
    - Feature inputs: `component_name`, `feature`, `screen_type`, `with_viewmodel`,
      `with_validation`, `with_navigation`.
    - Service inputs: `service_type`, `api_base_url`, `with_retry_logic`, `with_caching`,
      `with_interceptors`, `with_mocks`.
- Cross-cutting toggles:
    - `with_tests`, `with_docs`, `with_mcp`, `code_generation`, `ai_integration`.

These are now considered **implementation details** of the `fly_foundation` brick and Fly CLI:

- They are **not exposed** as direct user knobs in `brick.yaml`.
- They are configured by:
    - The internal Fly foundation template.
    - `generation_mode` (choice of workflow).
    - `preset` (opinionated stack selection).
    - `platforms` (target platform selection).

**Rationale**:

- Most users do not want to micro-manage every aspect of the foundation at scaffold time.
- Providing too many toggles makes the CLI harder to understand and reason about.
- Opinionated presets provide a better out-of-the-box experience while still allowing:
    - Internal evolution of defaults.
    - Manual customization in the generated project after scaffolding.

---

## How the brick is intended to be used by the CLI

At a high level, the Fly CLI should:

1. **Prompt for `generation_mode`**:
    - Decide whether this is a new project, feature, or service generation.

2. **Prompt for shared metadata**:
    - `name`: interpreted according to the chosen mode.
    - `description`, `organization`: used for project metadata.

3. **Prompt for high-impact options**:
    - `platforms`: to conditionally generate platform-specific configuration.
    - `preset`: to select the internal stack behavior.

4. **Apply internal mapping**:
    - Based on `generation_mode` and `preset`, derive internal flags and configuration:
        - Which packages to include.
        - Which integrations and defaults to enable (tests, docs, AI, mocks, services).
        - How to structure the generated directories, files, and templates.

5. **Generate files**:
    - Use the derived internal configuration to execute **opinionated templates**.

This approach keeps the user-facing schema stable and small, while allowing the brick implementation
and CLI to evolve independently.

---

## Design principles recap

- **Minimal surface area**:
    - Very few top-level fields: `generation_mode`, `name`, `description`, `organization`,
      `platforms`, `preset`.

- **High-level control, not low-level toggles**:
    - Use `preset` instead of many `with_*` and per-mode flags.
    - Users choose a **stack style**, not individual wiring options.

- **Mode-aware but schema-light**:
    - `generation_mode` is the only mode switch.
    - Shared fields keep the configuration small and consistent.

- **Implementation details are internal**:
    - Advanced behavior (AI, services, docs, mocks, etc.) is controlled by presets and template
      logic.
    - This allows you to improve the foundation without forcing users to re-learn the configuration.

---

## Future extensions

If the brick needs to evolve without increasing complexity:

- **Extend `preset` behavior**:
    - Keep the same enum values but change what each one does under the hood.
    - Optionally add new presets only when they represent clear, distinct stacks.

- **Add mode-specific but still high-level fields**:
    - Example: a generic `kind` field for services (`api`, `local`) if truly necessary.
    - Any addition should be **mode-aware** and **high-level**, not a proliferation of toggles.

- **Versioning**:
    - When introducing breaking changes to the `vars` schema, bump `version` and update this
      document.

This document should be kept up to date whenever the `brick.yaml` schema changes, so that Fly CLI
contributors and template authors have a single reference for the intended design and behavior.


