## Future Work – Comprehensive Implementation Plan

### 1. BrickHub Publishing Pipeline

#### 1.1 Finalize Brick Packages

- **Review brick contents**
    - Ensure each brick under `bricks/` has:
        - `pubspec.yaml` with correct `name`, `description`, `version`, `homepage`, `repository`,
          `issue_tracker`, and SDK constraints.
        - `brick.yaml` with accurate description and version.
        - `__brick__/` structure that matches what the CLI expects (paths, variables).
        - A concise, user-focused `README.md` with examples.
- **Stabilize naming & versions**
    - Decide on initial published versions (`1.0.0` or similar) and tag them in git.
    - Ensure brick names are consistent with CLI naming (`fly_foundation_project`,
      `fly_foundation_feature`, `fly_foundation_service`).

#### 1.2 Local Validation Before Publishing

- **Manual mason validation**
    - From each brick directory:
        - Run `mason get` to validate `brick.yaml`.
        - Run `mason make <brick_name>` with sample `--vars` to ensure generation works
          independently of `fly_cli`.
- **CLI integration sanity check**
    - With `FLY_TEMPLATES_DIR` pointing to the workspace, exercise:
        - `fly generate project ... --template=fly_foundation`
        - `fly generate feature ...`
        - `fly generate service ...`
    - Confirm that the right bricks (from `bricks/`) are being used via logs (`BrickRegistry` debug
      output).

#### 1.3 Publishing to BrickHub

- **Prepare for publish**
    - Ensure `publish_to` is either omitted or set appropriately for BrickHub usage.
    - Confirm licenses and links are correct in each brick’s metadata.
- **Publish workflow**
    - Use `mason login` (if needed) and `mason publish` from each brick directory.
    - After publishing, verify:
        - Brick appears on BrickHub with correct description and README.
        - Version and SDK constraints are correct.

#### 1.4 Tie `fly_cli` to BrickHub Bricks

- **Resolution strategy**
    - Decide how `TemplateManager` resolves bricks in production:
        - Prefer BrickHub for known IDs (`fly_foundation_project`, etc.).
        - Use `bricks/` path overrides during development (via `FLY_TEMPLATES_DIR` or
          `customBrickPaths`).
- **Fallback logic**
    - Implement/confirm logic so that, when running outside the monorepo:
        - If local `templates/` directory exists, use it first.
        - Otherwise, rely on BrickHub-resolved bricks.

---

### 2. Remove Legacy Monolithic Brick ✅ (Completed)

#### 2.1 Deprecation & Monitoring ✅

- **Staged deprecation** ✅
    - Legacy `fly_foundation` was marked as deprecated and kept functional during migration period.
    - Migration completed and legacy brick removed.

#### 2.2 Hard Removal ✅

- **Code removal plan** ✅
    - Removed:
        - `templates/projects/fly_foundation/` directory (entire legacy brick).
        - All hooks (`hooks/**` including pre_gen, post_gen, orchestrator, planners).
        - Hook-specific tests.
    - Updated:
        - `mason.yaml` and `mason-lock.json` to remove legacy brick references.
        - Documentation to reflect removal.
        - `MIGRATION_COMPLETE.md` to document completion.

#### 2.3 Validation After Removal (In Progress)

- **Regression testing**
    - Re-run:
        - `fly generate project ...`
        - `fly generate feature ...`
        - `fly generate service ...`
    - Ensure no runtime references to removed files remain (e.g., no missing hook files).
    - Verify test coverage parity with legacy system.

---

### 3. Integration Tests & Golden Alignment

#### 3.1 Update Integration Workflow Tests

- **Command-based workflows**
    - Ensure tests like `command_workflow_test.dart`:
        - Still create projects with `--template=fly_foundation` successfully.
        - Generate screens and services via the orchestrator (implicitly).
    - Add assertions that verify:
        - Expected files exist (paths may be slightly different now that `modes/` is gone).
        - No `modes/` directories remain in final output.

#### 3.2 Update Template Integration Tests

- **TemplateManager / BrickRegistry tests**
    - Adjust `mason_integration_test.dart` and `template_manager_test.dart` to:
        - Expect bricks to be found in `bricks/` (in dev).
        - Confirm that `getProjectBricks`, `getScreenBricks`, and `getServiceBricks` see the new
          bricks.
- **Legacy compatibility tests**
    - If there are tests that rely on `fly_foundation` brick directly, either:
        - Update them to assert deprecation behavior, or
        - Remove them once the legacy brick is gone.

#### 3.3 Golden Output Updates

- **Scenario replays**
    - Re-run existing scenarios under `templates/projects/fly_foundation/tools/scenarios` using the
      new orchestrator.
    - Compare results to current goldens:
        - If differences are purely structural (e.g., missing `modes/`), regenerate goldens with the
          new outputs.
        - If differences are semantic, investigate and fix the templates and/or planning logic.
- **Document golden regeneration process**
    - Add a short note in the repo on how to run scenarios and update goldens (for future
      contributors).

---

### 4. Performance & Telemetry

#### 4.1 Benchmarks

- **Local benchmarks**
    - Add simple timing harness around:
        - Project generation.
        - Feature generation.
        - Service generation.
    - Measure:
        - Total generation time.
        - Number of generated files.
        - Disk I/O volume (approximate via file count/size).
- **Compare old vs new**
    - If you still have a branch with the old behavior, compare metrics to quantify improvements.

#### 4.2 Telemetry Hooks

- **Telemetry integration**
    - If `MetricsCollector` or similar is available:
        - Add metrics for number of bricks invoked per command.
        - Track errors from `FoundationPlanner` and `FoundationOrchestrator`.
    - Ensure any telemetry is optional and respects user privacy.

---

### 5. Developer Experience & Tooling

#### 5.1 Contributor Documentation

- **Update / create guides**
    - Extend `MIGRATION_TO_MULTI_BRICK.md` with:
        - “How to add a new brick/module” checklist.
        - Examples of integrating a new module into `FoundationPlanner` and the CLI.
    - Add a section in `fly_cli` README describing:
        - The role of `fly_foundation_planning`.
        - How `bricks/` is structured.

#### 5.2 DX Scripts

- **Helper scripts**
    - Add simple scripts to automate common tasks:
        - `scripts/dev/run_foundation_scenarios.sh` for smoke testing bricks.
        - `scripts/dev/publish_bricks.sh` to assist with BrickHub publishes (dry-run and final).
- **Editor / tooling support**
    - Consider adding VS Code or IDE tasks for:
        - Running tests in `fly_foundation_planning`.
        - Running end-to-end CLI workflows.

---

### 6. API Hardening & Backwards Compatibility

#### 6.1 Public API Contract for Planning Library

- **Surface definition**
    - Decide which symbols are “public contract”:
        - `FoundationPlanner`
        - `PlanningResult`
        - `ModuleInvocation`
        - `BaseTemplateVariables` (if needed externally)
    - Keep these stable across versions; treat others as internal.

#### 6.2 Versioning Strategy

- **Semantic versioning**
    - For `fly_foundation_planning`:
        - `1.x` for current architecture.
        - Bump minor/patch for non-breaking additions.
        - Bump major only if the planning API changes.
    - For bricks:
        - Bump versions when making template changes that affect output.
        - Coordinate version ranges in `fly_cli` if you ever depend on specific brick versions.

---

### 7. Long-Term Evolution

#### 7.1 Additional Modules

- **Future bricks**
    - Plan for:
        - Additional modules (e.g. analytics dashboards, advanced auth flows).
        - Shared bricks (e.g. “testing helpers” brick) that can be orchestrated similarly.
- **Planner extensibility**
    - Consider making the planner pluggable:
        - External modules can register their own planners and add new `GenerationMode`s or module
          types.

#### 7.2 Multi-Template Support

- **Beyond foundation**
    - If Fly adds more template families (not just foundation), define:
        - A generalized orchestrator pattern.
        - A shared abstraction so other template families can reuse the planning/orchestration
          architecture.

---

# Fly Foundation – Future Work & BrickHub Publishing Plan

## 1. BrickHub Publishing & `bricks/` Workspace

### 1.1 Finalize Brick Packages

- **Review brick contents**
- Confirm each brick under `bricks/` has:
- `pubspec.yaml` with correct `name`, `description`, `version`, `homepage`, `repository`,
  `issue_tracker`, and SDK constraints.
- `brick.yaml` with accurate description, version, and any variables that are still user-facing.
- `__brick__/` content that matches what the CLI expects (paths, variables, placeholders).
- A concise, user-focused `README.md` including at least one example `mason make` invocation.
- **Stabilize naming & versions**
- Decide on initial published versions (e.g. `1.0.0`) and tag them in git when ready to release.
- Ensure brick names match CLI usage and planning library expectations:
- `fly_foundation_project`
- `fly_foundation_feature`
- `fly_foundation_service`

### 1.2 Local Validation Before Publishing

- **Run Mason validation per brick**
- From each brick directory:
- `cd /Users/apple/Desktop/dev/flutter/me/projects/Fly/bricks/fly_foundation_project`
- `mason get`
- `mason make fly_foundation_project --on-conflict overwrite --vars '{

### To-dos

- [ ] Extract foundation planning and module-selection logic from hooks into a shared Dart library
  with a stable API for the CLI and bricks.
- [ ] Create separate Mason bricks for project, feature, service (and provider if needed), moving
  templates out of __brick__/modes/** into those bricks.
- [ ] Update fly_cli to orchestrate module bricks using the shared planning library instead of
  relying on a single monolithic fly_foundation brick.
- [ ] Simplify or remove heavy pre_gen/post_gen hooks in new bricks so they only handle local
  concerns (formatting, small adjustments).