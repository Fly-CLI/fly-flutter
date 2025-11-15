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

## 2. Mason Scenario: Multi-Feature Project

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
