# fly_foundation Template

`fly_foundation` is the unified Mason brick that powers Fly CLI’s production-ready Flutter
experience. A single template generates full projects and standalone components (screens, services,
providers) with MVVM architecture, Riverpod 3 state management, AI-ready documentation, and
WCAG-compliant UX baked in.

- **Generation modes:** `project`, `feature`, `service`, `provider`
- **Target compliance:** ≥95 % Flutter/Dart code-generation, ≥90 % documentation, ≥85 %
  accessibility
- **Reference implementation:** `/examples/foundation_project`

---

## Requirements

- Flutter SDK ≥ `3.10.0` (recommended `3.16.x`)
- Dart SDK ≥ `3.0.0`
- `fly_cli` (`dart pub global activate fly_cli`)
- (Optional) Mason CLI for direct brick usage (`dart pub global activate mason_cli`)

---

## Installation & Setup

```bash
dart pub global activate fly_cli
fly --version
```

Add or update the template:

```bash
fly templates add fly_foundation ./packages/fly_cli/templates/projects/fly_foundation
```

Verify Flutter tooling:

```bash
flutter upgrade
flutter doctor
```

---

## Quick Start (≤5 minutes)

1. **Create a project**
   ```bash
   fly create my_app \
     --template=fly_foundation \
     --generation-mode=project \
     --organization=com.example \
     --platforms=ios,android,web
   ```
2. **Install deps & run generators**
   ```bash
   cd my_app
   dart run build_runner build --delete-conflicting-outputs
   ```
3. **Run the app**
   ```bash
   flutter run
   ```
4. **Export AI context / start MCP (optional)**
   ```bash
   fly context export
   fly mcp serve
   ```

---

## Generation Modes Overview

| Mode       | CLI usage example                                                                | Generates                                                                                             |
|------------|----------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------|
| `project`  | `fly create my_app --template=fly_foundation --generation-mode=project`          | Full Flutter app with MVVM base classes, navigation, localization, theming, tests, build/config files |
| `feature`  | `fly generate feature dashboard --feature=home --template=fly_foundation`        | `BaseScreen` subclass, optional ViewModel + provider, accessibility wrappers, optional widget tests   |
| `service`  | `fly generate service auth --feature=auth --template=fly_foundation`             | Service class returning `AppResult<T>`, provider wiring, optional retry/caching, unit tests           |
| `provider` | `fly generate provider session --provider-type=future --template=fly_foundation` | `@riverpod` provider boilerplate with optional explicit state class                                   |

Each mode shares the same variable system, naming rules, and lint configuration so components slot
directly into generated projects.

---

## Project Mode Details

### Directory Layout

```
{{project_name}}/
├── .gitignore
├── README.md
├── analysis_options.yaml
├── l10n.yaml
├── main.dart
├── pubspec.yaml
├── build.yaml (only when code_generation=true)
├── assets/
│   └── .gitkeep
├── lib/
│   ├── core/
│   │   └── foundation/screen/{base_screen.dart, base_view_model.dart}
│   ├── features/
│   │   └── {{feature}}/
│   │       └── presentation/
│   │           ├── models/
│   │           ├── screen/{{feature}}_screen.dart
│   │           ├── screen/{{feature}}_view_model.dart
│   │           └── widgets/
│   ├── l10n/app_en.arb
│   └── shared/
│       ├── navigation/{app_navigator.dart, app_router.dart, feature_screen_type.dart}
│       └── themes/app_theme.dart
├── test/{{feature}}_screen_test.dart (only when with_tests=true)
└── .ai/project_context.md (only when ai_integration=true)
```

### Default Capabilities

- **Architecture:** MVVM via `FlyScreen`/`FlyViewModel` wrappers, Riverpod providers, feature-based
  modules.
- **Navigation:** `FeatureScreen` enum + `AppRouteConfig` with Material `onGenerateRoute`.
  `AppNavigator` bridges to `fly_navigation`.
- **Accessibility:** `BaseScreen` wraps every view in `Semantics`, `FocusTraversalGroup`, and
  `SafeArea`. Themes guarantee WCAG AA contrast.
- **Localization:** `l10n.yaml` plus starter `app_en.arb`, `flutter_gen` wiring, localized app
  shell.
- **Code generation:** Opinionated `build.yaml` enabling `riverpod_generator`, `drift_dev`,
  `auto_mappr`, `json_serializable`, and an incremental runner.
- **Testing:** Optional widget tests, provider overrides, and accessibility assertions.
- **AI/MCP:** `.ai/project_context.md` scaffold, MCP server config, and command recipes for
  `fly context export`/`fly mcp serve`.

---

## Component Modes

### Feature Mode

- Generates a `BaseScreen<ViewModel, State>` subclass with Semantics, refresh handling, and Riverpod
  provider wiring.
- Optional `BaseViewModel` descendant with `runAsyncOperation` hooks, typed state object, and
  notifier provider.
- Optional widget test verifying localization, navigation, and accessibility semantics.
- Recommended workflow:
  ```bash
  fly generate feature dashboard \
    --feature=home \
    --with-viewmodel=true \
    --with-tests=true
  ```

### Service Mode

- Creates a service class returning `AppResult<T>` from `fly_flow_guard` with optional retry +
  caching layers.
- Registers a provider under `core/services` and, if requested, matching Riverpod provider
  definitions.
- Test template stubs HTTP mocking, retry validation, and error handling scenarios.
  ```bash
  fly generate service auth \
    --feature=auth \
    --api-base-url=https://api.example.com \
    --with-retry-logic=true \
    --with-caching=false
  ```

### Provider Mode

- Produces `@riverpod` providers for notifier/future/stream/state patterns with optional explicit
  state classes.
- Honors `with_state_class` to scaffold sealed-state patterns or can remain stateless for
  lightweight providers.
  ```bash
  fly generate provider session \
    --provider-type=notifier \
    --with-state-class=true
  ```

---

## Architecture & Patterns

- **MVVM Foundation:** `BaseScreen` extends `FlyScreen` and standardizes Semantics, focus order,
  safe areas, and refresh handling. `BaseViewModel` extends `FlyViewModel`, wires `FlyLogger`, and
  exposes `runAsyncOperation` for AppResult-friendly async flows.
- **Feature Modules:** Each feature contains data/domain/presentation folders. Generated scaffolding
  includes presentation (screens/view models) by default; data/domain/applets can be enabled as
  custom features evolve.
- **Navigation System:** `FeatureScreen` enum defines routes, metadata, and semantics labels.
  `AppRouteConfig` configures Material routes, while `AppNavigator` wraps `NavigationManager` to
  provide typed navigation plus observer hooks for analytics/events.
- **Dependency Injection:** `GlobalContainer` initializes a singleton `ProviderContainer` before
  `runApp`, enabling application-wide Riverpod overrides, testing helpers, and service registration.
- **Repository, Service, Storage Patterns:** Templates encourage `BaseRepository` (Template Method
  hooks), services returning `AppResult<T>`, and storage interfaces + managers (SharedPreferences +
  SecureStorage) per plan recommendations.
- **Database:** Optional Drift integration with `drift_dev` builder ensures typed SQLite access when
  features demand persistence.
- **Events & Logging:** `fly_events` offers emitters for navigation or domain events; `fly_logger`
  supplies structured logging per ViewModel/service.

---

## Fly Ecosystem Packages

| Package            | Purpose                                                          |
|--------------------|------------------------------------------------------------------|
| `fly_core`         | Global container, application bootstrap helpers                  |
| `fly_mvvm`         | `FlyScreen`/`FlyViewModel`, async orchestration, state contracts |
| `fly_state`        | Shared state abstractions, view-state helpers                    |
| `fly_navigation`   | `NavigationManager`, typed navigation service                    |
| `fly_flow_guard`   | `AppResult<T>` pattern, async guardrails, retry helpers          |
| `fly_logger`       | Structured logging (auto-wired into base ViewModels/services)    |
| `fly_events`       | Event emitter / observer tooling                                 |
| `fly_networking`   | HTTP client conventions, interceptors, connectivity integrations |
| `fly_localization` | Localization helpers + bridging utilities                        |

Select packages via the `fly_packages` variable to slim down dependencies when needed.

---

## Template Structure & Files

- `.gitignore` filters Flutter build outputs, generated code, coverage, and IDE metadata.
- `analysis_options.yaml` excludes generated files (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`)
  and enforces curated lints.
- `build.yaml` (controlled by `code_generation`) preconfigures Riverpod/Drift/AutoMappr/JSON
  builders plus the incremental runner.
- `l10n.yaml` sets up Flutter localization with ARB inputs, paired with `lib/l10n/app_en.arb`.
- `.ai/project_context.md` is produced only when `ai_integration=true` to describe architecture for
  AI assistants.
- `assets/.gitkeep` keeps the assets directory tracked until real files exist.
- `test/{{feature}}_screen_test.dart` is emitted when `with_tests=true` and matches the feature list.

---

## Code Generation Workflow

1. **Single build:** `dart run build_runner build --delete-conflicting-outputs`
2. **Incremental dev loop:** `dart run build_runner watch --delete-conflicting-outputs`
3. **CI/CD tip:** Cache `.dart_tool/build` between runs and prefer `watch` locally for 50 %+ faster
   iteration.
4. **Generated files:** Commit manually authored code only—`.gitignore` already excludes `*.g.dart`,
   `*.freezed.dart`, etc.
5. **Generators enabled:** Riverpod 3 (`@riverpod`), Drift (database), AutoMappr (DTO mappers),
   `json_serializable`.

---

## Variable Reference

### Core Variables (all modes)

| Variable          | Type   | Default                        | Description / Validation                             |
|-------------------|--------|--------------------------------|------------------------------------------------------|
| `generation_mode` | enum   | `project`                      | `project`, `feature`, `service`, `provider`          |
| `project_name`    | string | —                              | Snake_case package name; required for project mode   |
| `organization`    | string | `com.example`                  | Reverse-DNS identifier; required for project mode    |
| `platforms`       | list   | `[ios, android]`               | Choose from ios/android/web/macos/windows/linux      |
| `description`     | string | `A new Fly foundation project` | Used inside `pubspec.yaml`                           |
| `template`        | enum   | `foundation`                   | Reserved for future variants                         |
| `features`        | list   | `[home]`                       | Initial feature modules scaffolded                   |
| `min_flutter_sdk` | string | `3.10.0`                       | Lower bound in `pubspec.yaml`                        |
| `min_dart_sdk`    | string | `3.0.0`                        | Lower bound in `pubspec.yaml`                        |
| `fly_packages`    | list   | see table above                | Controls which Fly packages are added to the pubspec |
| `code_generation` | bool   | `true`                         | Toggles `build.yaml` + generator dependencies        |
| `ai_integration`  | bool   | `true`                         | Adds `.ai/project_context.md` scaffolding            |
| `with_docs`       | bool   | `true`                         | Includes README + documentation helpers              |

### Project-Only Flags

| Variable     | Type | Default         | Description                                    |
|--------------|------|-----------------|------------------------------------------------|
| `with_mcp`   | bool | `true`          | Generates MCP server config + command helpers  |
| `with_tests` | bool | `true`          | Adds starter widget tests                      |
| `platforms`  | list | `[ios,android]` | Configures platform folders in Flutter tooling |

### Feature Mode

| Variable          | Type   | Default | Notes                                              |
|-------------------|--------|---------|----------------------------------------------------|
| `component_name`  | string | —       | Required; snake_case (e.g., `order_history`)       |
| `feature`         | string | `home`  | Target feature module                              |
| `screen_type`     | enum   | `list`  | `list`, `detail`, `form`, `auth`, `settings`       |
| `with_viewmodel`  | bool   | `true`  | Generates ViewModel + provider                     |
| `with_validation` | bool   | `false` | Adds form validation helpers (form/auth screens)   |
| `with_navigation` | bool   | `true`  | Wires screen into `FeatureScreen` + route registry |
| `with_tests`      | bool   | `true`  | Widget test scaffold                               |

### Service Mode

| Variable           | Type   | Default                   | Notes                                     |
|--------------------|--------|---------------------------|-------------------------------------------|
| `component_name`   | string | —                         | Required                                  |
| `feature`          | string | `home`                    | Service namespace                         |
| `api_base_url`     | string | `https://api.example.com` | Used inside generated HTTP client         |
| `with_retry_logic` | bool   | `true`                    | Adds connectivity-aware retry helpers     |
| `with_caching`     | bool   | `false`                   | Adds caching layer + storage dependencies |
| `with_tests`       | bool   | `true`                    | Service unit test scaffold                |

### Provider Mode

| Variable           | Type   | Default    | Notes                                       |
|--------------------|--------|------------|---------------------------------------------|
| `component_name`   | string | —          | Required                                    |
| `provider_type`    | enum   | `notifier` | `notifier`, `future`, `stream`, `state`     |
| `with_state_class` | bool   | `false`    | Generates explicit state class for provider |

---

## Accessibility & Localization

- **Semantics everywhere:** Screens and hero sections include descriptive labels; `FeatureScreen`
  stores semantics labels for navigation announcements.
- **Keyboard navigation:** `FocusTraversalGroup` with ordered traversal ensures predictable tab
  order.
- **Color contrast:** `AppTheme` uses harmonized Material 3 color schemes tuned for WCAG 2.1 AA.
- **Media & text scaling:** App shell forces `boldText` + `accessibleNavigation` flags for better
  legibility.
- **Localization pipeline:** `l10n.yaml` + `app_en.arb` ready for `flutter gen-l10n`; extend with
  more locales and rerun `flutter gen-l10n`.

---

## MCP & AI Integration

When `ai_integration=true`, the template adds `.ai/project_context.md`, which summarizes the
generated architecture for AI copilots (Cursor, MCP, etc.). Pair it with:

```bash
fly context export --format markdown
fly mcp serve --project .
```

---

## Usage Examples

1. **Minimal project**\
   `fly create starter_app --template=fly_foundation --fly-packages=fly_core,fly_mvvm`

2. **Production stack**\
   `fly create ops_app --template=fly_foundation --features=home,auth,settings --fly-packages=fly_core,fly_mvvm,fly_state,fly_navigation,fly_flow_guard,fly_logger,fly_events,fly_networking`

3. **Feature component**\
   `fly generate feature profile_overview --feature=profile --screen-type=detail`

4. **Service component**\
   `fly generate service payments --feature=billing --api-base-url=https://billing.example.com --with-retry-logic --with-caching`

5. **Provider component**\
   `fly generate provider session --provider-type=future --with-state-class`

---

## Troubleshooting

| Issue                        | Fix                                                                                    |
|------------------------------|----------------------------------------------------------------------------------------|
| `build_runner` conflicts     | `dart run build_runner build --delete-conflicting-outputs`                             |
| Missing Flutter SDK          | Install from [flutter.dev](https://flutter.dev) and ensure `flutter` is on `PATH`      |
| Template validation failed   | Verify `generation_mode`, `project_name`, `organization`, required mode-specific flags |
| Navigation not updating      | Confirm new routes were added to `FeatureScreen` enum and `AppRouteConfig`             |
| Localization strings missing | Run `flutter gen-l10n` after editing `.arb` files                                      |

---

## Migration Guide

1. **Archive old bricks:** Remove legacy template directories after exporting any local edits.
2. **Adopt unified template:** Point template manager to `fly_foundation`, ensuring CLI ≥ version
   that understands `generation_mode`.
3. **Map variables:** Translate existing template flags to the variables table above (e.g.,
   `--with-tests` → `with_tests`).
4. **Regenerate components:** Use the component modes to replace manual boilerplate (
   screens/services/providers).
5. **Validate & test:** Run `flutter analyze`, `dart run build_runner build`, and existing test
   suites before publishing.

---

## Best Practices Checklist

- Keep feature modules focused (data/domain/presentation) and favor vertical slicing.
- Reuse `runAsyncOperation` in ViewModels for any awaited work to automatically handle loading +
  error state.
- Centralize navigation side effects inside `AppNavigator` or middleware to keep screens
  declarative.
- Pin package versions inside `pubspec.yaml` for reproducible builds; bump intentionally with
  changelog entries.
- Use `build_runner watch` during active development and fall back to `build_runner build` for CI.
- Document feature decisions inside `.ai/project_context.md` so AI assistants remain accurate.
- Extend accessibility tests when adding custom widgets or gestures.

---

## Contributing

1. Clone the Fly monorepo and run `melos bootstrap`.
2. Modify template files under `packages/fly_cli/templates/projects/fly_foundation`.
3. Regenerate snapshots/tests as needed (`melos run test:templates` if available).
4. Update this README when changing generation modes, variables, or workflows.
5. Submit PRs with before/after screenshots, generated project diffs, and lint/test results.

---

## References

- `/docs/mason-brick-template-development-plan-40f4028d.plan.md`
- `/examples/foundation_project` (reference implementation)
- `/packages/fly_cli/lib/src/features` (command architecture)
- `/packages/fly_cli/lib/src/core/templates/ai_context_template.md`

Happy building! 🚀

