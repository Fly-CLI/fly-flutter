# fly_foundation Template Test Plan

This document captures the exact commands used to verify the `fly_foundation` brick across common configurations. All commands were executed from `/Users/apple/Desktop/dev/flutter/me/projects/Fly` on macOS.

## 0. Environment Prep

```bash
cd /Users/apple/Desktop/dev/flutter/me/projects/Fly
flutter pub run melos bootstrap
flutter pub global activate --source path packages/fly_cli
flutter pub global activate mason_cli
export FLY_TEMPLATES_DIR="/Users/apple/Desktop/dev/flutter/me/projects/Fly/packages/fly_cli/templates"
```

## 1. Baseline Project via Fly CLI (defaults)

```bash
rm -rf /tmp/fly/fly_foundation_default
FLY_TEMPLATES_DIR=$FLY_TEMPLATES_DIR \
  dart run packages/fly_cli/bin/fly.dart generate project fly_default \
  --template=fly_foundation \
  --organization=com.example.default \
  --platforms=ios,android,web \
  --output-dir=/tmp/fly/fly_foundation_default
```

### 1a. Verify Generated Structure

From `/tmp/fly/fly_foundation_default` confirm:

- Root files: `.gitignore`, `analysis_options.yaml`, `build.yaml` (only when `code_generation=true`), `l10n.yaml`, `main.dart`, `pubspec.yaml`, `README.md`.
- Hidden assets: `.ai/project_context.md` exists only when `ai_integration=true`; delete when the flag is false (see Scenario 4).
- Assets + localization: `assets/.gitkeep`, `lib/l10n/app_en.arb`.
- Core layer: `lib/core/foundation/screen/{base_screen.dart,base_view_model.dart}`.
- Feature scaffolding (per feature name):
  - `lib/features/<feature>/presentation/models/`
  - `lib/features/<feature>/presentation/screen/{<feature>_screen.dart,<feature>_view_model.dart}`
  - `lib/features/<feature>/presentation/widgets/`
- Shared layers:
  - `lib/shared/navigation/{app_navigator.dart,app_router.dart,feature_screen_type.dart}`
  - `lib/shared/themes/app_theme.dart`
- Testing: `test/<feature>_screen_test.dart` present only when `with_tests=true`.

Spot check contents (imports, class names, Riverpod providers) to ensure they match the current brick files under `__brick__`.

## 1b. Baseline Feature Generation via Fly CLI (defaults)

Generate a standalone feature component into an existing project:

```bash
# First create a base project
rm -rf /tmp/fly/fly_foundation_feature_test
FLY_TEMPLATES_DIR=$FLY_TEMPLATES_DIR \
  dart run packages/fly_cli/bin/fly.dart generate project fly_feature_test \
  --template=fly_foundation \
  --organization=com.example.features \
  --platforms=ios,android \
  --output-dir=/tmp/fly/fly_foundation_feature_test

# Then generate a feature component into it
FLY_TEMPLATES_DIR=$FLY_TEMPLATES_DIR \
  dart run packages/fly_cli/bin/fly.dart generate feature dashboard \
  --feature=analytics \
  --type=list \
  --with-viewmodel \
  --with-tests \
  --with-navigation \
  --output-dir=/tmp/fly/fly_foundation_feature_test/fly_feature_test
```

### 1b-1. Verify Generated Feature Structure

From `/tmp/fly/fly_foundation_feature_test/fly_feature_test` confirm:

- Feature screen: `lib/features/analytics/presentation/screen/dashboard_screen.dart`
- Feature ViewModel: `lib/features/analytics/presentation/screen/dashboard_view_model.dart` (when `--with-viewmodel`)
- Feature test: `test/features/analytics/dashboard_screen_test.dart` (when `--with-tests`)
- Models/widgets folders: `lib/features/analytics/presentation/models/`, `lib/features/analytics/presentation/widgets/`

Spot check that:
- `dashboard_screen.dart` extends `BaseScreen` with proper Riverpod provider wiring
- ViewModel contains `DashboardViewModelState` and `DashboardViewModel` classes
- Test file imports and references the generated screen correctly
- All class names use PascalCase (`DashboardScreen`, `DashboardViewModel`, etc.)

## 1c. Baseline Service Generation via Fly CLI (defaults)

Generate a standalone service component into an existing project:

```bash
# Use the same base project or create a new one
cd /tmp/fly/fly_foundation_feature_test/fly_feature_test
FLY_TEMPLATES_DIR=$FLY_TEMPLATES_DIR \
  dart run packages/fly_cli/bin/fly.dart generate service auth \
  --feature=auth \
  --type=api \
  --base-url=https://api.example.com \
  --with-tests \
  --with-mocks \
  --with-interceptors \
  --output-dir=/tmp/fly/fly_foundation_feature_test/fly_feature_test

```

### 1c-1. Verify Generated Service Structure

From `/tmp/fly/fly_foundation_feature_test/fly_feature_test` confirm:

- Service class: `lib/core/services/auth/auth_service.dart`
- Service test: `test/core/services/auth/auth_service_test.dart` (when `--with-tests`)
- Mock implementation: `test/core/services/auth/mocks/auth_service_mock.dart` (when `--with-mocks`)

Spot check that:
- `auth_service.dart` imports `AppResult` from `fly_flow_guard`
- Service methods return `Future<AppResult<T>>` for type-safe error handling
- Retry logic uses `RetryConfig` when `--with-retry-logic` is enabled
- Interceptors are included when `--with-interceptors` is enabled
- Mock class extends or implements the service interface when `--with-mocks` is enabled
- Test file includes basic service test scaffolding

## 2. Multi-Feature Project via Fly CLI

```bash
rm -rf /tmp/fly/fly_foundation_features
FLY_TEMPLATES_DIR=$FLY_TEMPLATES_DIR \
  dart run packages/fly_cli/bin/fly.dart generate project fly_features \
  --template=fly_foundation \
  --organization=com.example.features \
  --platforms=ios,android \
  --features=home,profile,settings \
  --output-dir=/tmp/fly/fly_foundation_features
```

### 2a. Structure Expectations

Confirm each feature folder (`home`, `profile`, `settings`) contains:

- `presentation/models/` (empty folder retained)
- `presentation/screen/{feature}_screen.dart`
- `presentation/screen/{feature}_view_model.dart`
- `presentation/widgets/`
- `test/{feature}_screen_test.dart` for every feature when `with_tests=true`.

Validate shared layers (`lib/core`, `lib/shared`, `.ai/`, `assets/.gitkeep`) remain singletons reused by all features.

## 2b. Mason Scenario: Multi-Feature Project (Alternative)

```bash
cat <<'JSON' > /tmp/fly/mason_fly_features.json
{
  "generation_mode": "project",
  "project_name": "fly_features",
  "organization": "com.example.features",
  "description": "Multi-feature scenario",
  "template": "foundation",
  "platforms": ["ios", "android"],
  "features": ["home", "profile", "settings"],
  "min_flutter_sdk": "3.10.0",
  "min_dart_sdk": "3.0.0",
  "with_mcp": true,
  "with_tests": true,
  "with_docs": true,
  "fly_packages": [
    "fly_core",
    "fly_mvvm",
    "fly_state",
    "fly_navigation",
    "fly_flow_guard",
    "fly_logger"
  ],
  "code_generation": true,
  "ai_integration": true,
  "component_name": "component",
  "feature": "home",
  "screen_type": "list",
  "with_viewmodel": true,
  "with_validation": false,
  "with_navigation": true,
  "api_base_url": "https://api.example.com",
  "with_retry_logic": true,
  "with_caching": false,
  "provider_type": "notifier",
  "with_state_class": false
}
JSON

rm -rf /tmp/fly/fly_foundation_features
script -q /dev/null mason make fly_foundation \
  -o /tmp/fly/fly_foundation_features \
  --on-conflict overwrite \
  --config-path /tmp/fly/mason_fly_features.json
```

After generation confirm `build.yaml` is absent and no `targets` section is emitted. Run `flutter analyze` to ensure the missing file does not break linting.

## 3. Mason Scenario: Code Generation Disabled

```bash
cat <<'JSON' > /tmp/fly/mason_fly_nocodegen.json
{
  "generation_mode": "project",
  "project_name": "fly_nocodegen",
  "organization": "com.example.nocodegen",
  "description": "Code generation disabled",
  "template": "foundation",
  "platforms": ["ios", "android"],
  "features": ["home"],
  "min_flutter_sdk": "3.10.0",
  "min_dart_sdk": "3.0.0",
  "with_mcp": true,
  "with_tests": true,
  "with_docs": true,
  "fly_packages": [
    "fly_core",
    "fly_mvvm",
    "fly_state",
    "fly_navigation",
    "fly_flow_guard",
    "fly_logger"
  ],
  "code_generation": false,
  "ai_integration": true,
  "component_name": "component",
  "feature": "home",
  "screen_type": "list",
  "with_viewmodel": true,
  "with_validation": false,
  "with_navigation": true,
  "api_base_url": "https://api.example.com",
  "with_retry_logic": true,
  "with_caching": false,
  "provider_type": "notifier",
  "with_state_class": false
}
JSON

rm -rf /tmp/fly/fly_foundation_nocodegen
script -q /dev/null mason make fly_foundation \
  -o /tmp/fly/fly_foundation_nocodegen \
  --on-conflict overwrite \
  --config-path /tmp/fly/mason_fly_nocodegen.json
```

Post-check: `build.yaml` should NOT be generated, while other gated files (analysis options, l10n, `.gitignore`, `.ai/project_context.md`) should remain.

## 4. Mason Scenario: AI Integration Disabled

```bash
cat <<'JSON' > /tmp/fly/mason_fly_noai.json
{
  "generation_mode": "project",
  "project_name": "fly_noai",
  "organization": "com.example.noai",
  "description": "AI integration disabled",
  "template": "foundation",
  "platforms": ["ios", "android", "web"],
  "features": ["home"],
  "min_flutter_sdk": "3.10.0",
  "min_dart_sdk": "3.0.0",
  "with_mcp": false,
  "with_tests": true,
  "with_docs": true,
  "fly_packages": [
    "fly_core",
    "fly_mvvm",
    "fly_state",
    "fly_navigation",
    "fly_flow_guard",
    "fly_logger"
  ],
  "code_generation": true,
  "ai_integration": false,
  "component_name": "component",
  "feature": "home",
  "screen_type": "list",
  "with_viewmodel": true,
  "with_validation": false,
  "with_navigation": true,
  "api_base_url": "https://api.example.com",
  "with_retry_logic": true,
  "with_caching": false,
  "provider_type": "notifier",
  "with_state_class": false
}
JSON

rm -rf /tmp/fly/fly_foundation_noai
script -q /dev/null mason make fly_foundation \
  -o /tmp/fly/fly_foundation_noai \
  --on-conflict overwrite \
  --config-path /tmp/fly/mason_fly_noai.json
```

Validate `.ai/` directory and `fly_mcp` dependency are omitted from the project when `ai_integration=false`.

## 5. Mason Scenario: Tests Disabled

```bash
cat <<'JSON' > /tmp/fly/mason_fly_notests.json
{
  "generation_mode": "project",
  "project_name": "fly_notests",
  "organization": "com.example.notests",
  "description": "Tests disabled",
  "template": "foundation",
  "platforms": ["ios", "android"],
  "features": ["home"],
  "min_flutter_sdk": "3.10.0",
  "min_dart_sdk": "3.0.0",
  "with_mcp": true,
  "with_tests": false,
  "with_docs": true,
  "fly_packages": [
    "fly_core",
    "fly_mvvm",
    "fly_state",
    "fly_navigation",
    "fly_flow_guard",
    "fly_logger"
  ],
  "code_generation": true,
  "ai_integration": true,
  "component_name": "component",
  "feature": "home",
  "screen_type": "list",
  "with_viewmodel": true,
  "with_validation": false,
  "with_navigation": true,
  "api_base_url": "https://api.example.com",
  "with_retry_logic": true,
  "with_caching": false,
  "provider_type": "notifier",
  "with_state_class": false
}
JSON

rm -rf /tmp/fly/fly_foundation_notests
script -q /dev/null mason make fly_foundation \
  -o /tmp/fly/fly_foundation_notests \
  --on-conflict overwrite \
  --config-path /tmp/fly/mason_fly_notests.json
```

Ensure `test/<feature>_screen_test.dart` is not emitted and no empty `test/` directory remains when `with_tests=false`.

## 6. Mason Scenario: Desktop Platforms + Docs Disabled

```bash
cat <<'JSON' > /tmp/fly/mason_fly_docsoff.json
{
  "generation_mode": "project",
  "project_name": "fly_docs_off",
  "organization": "com.example.docsoff",
  "description": "Docs disabled for desktop targets",
  "template": "foundation",
  "platforms": ["macos", "windows", "linux"],
  "features": ["home"],
  "min_flutter_sdk": "3.10.0",
  "min_dart_sdk": "3.0.0",
  "with_mcp": true,
  "with_tests": true,
  "with_docs": false,
  "fly_packages": [
    "fly_core",
    "fly_mvvm",
    "fly_state",
    "fly_navigation",
    "fly_flow_guard",
    "fly_logger"
  ],
  "code_generation": true,
  "ai_integration": true,
  "component_name": "component",
  "feature": "home",
  "screen_type": "list",
  "with_viewmodel": true,
  "with_validation": false,
  "with_navigation": true,
  "api_base_url": "https://api.example.com",
  "with_retry_logic": true,
  "with_caching": false,
  "provider_type": "notifier",
  "with_state_class": false
}
JSON

rm -rf /tmp/fly/fly_foundation_docs_off
script -q /dev/null mason make fly_foundation \
  -o /tmp/fly/fly_foundation_docs_off \
  --on-conflict overwrite \
  --config-path /tmp/fly/mason_fly_docsoff.json
```

Verify documentation artifacts (e.g., README content) remain but no extra docs directory is generated, and desktop platforms are included in the `platforms` list within `README.md` and `pubspec.yaml`.

## 7. Post-Generation Verification

For each generated output directory:

```bash
cd /tmp/fly/<folder>
flutter pub get
if [ -f build.yaml ]; then dart run build_runner build --delete-conflicting-outputs; fi
flutter analyze
flutter test || true
```

Record any deviations or errors alongside the scenario for traceability.
