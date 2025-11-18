#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BRICK_DIR="$ROOT_DIR"
OUT_DIR="$ROOT_DIR/.scenario_out"
GOLDENS_DIR="$ROOT_DIR/test/goldens"

run_scenario () {
  local scenario_path="$1"
  local name="$2"
  local output="$OUT_DIR/$name"
  rm -rf "$output"
  mkdir -p "$output"
  pushd "$output" >/dev/null
  mason make fly_foundation -c "$scenario_path" --on-conflict overwrite
  popd >/dev/null
  if [ -d "$GOLDENS_DIR/$name" ]; then
    diff -ru "$GOLDENS_DIR/$name" "$output" || {
      echo "Golden diff for $name"; exit 1;
    }
  else
    echo "No golden found for $name. You can accept the output as the new golden:"
    echo "  cp -R \"$output\" \"$GOLDENS_DIR/$name\""
  fi
}

# Project scenarios (all 3 presets)
run_scenario "$ROOT_DIR/tools/scenarios/project/default_foundation.json" "project/default_foundation"
run_scenario "$ROOT_DIR/tools/scenarios/project/minimal_no_tests.json" "project/minimal_no_tests"
run_scenario "$ROOT_DIR/tools/scenarios/project/starter_all_platforms.json" "project/starter_all_platforms"

# Service scenarios (all 5 service types)
run_scenario "$ROOT_DIR/tools/scenarios/services/api_minimal.json" "services/api_minimal"
run_scenario "$ROOT_DIR/tools/scenarios/services/api_retry_cache.json" "services/api_retry_cache"
run_scenario "$ROOT_DIR/tools/scenarios/services/local_minimal.json" "services/local_minimal"
run_scenario "$ROOT_DIR/tools/scenarios/services/cache_service.json" "services/cache_service"
run_scenario "$ROOT_DIR/tools/scenarios/services/analytics_service.json" "services/analytics_service"
run_scenario "$ROOT_DIR/tools/scenarios/services/storage_service.json" "services/storage_service"

# Feature scenarios (all 5 screen types)
run_scenario "$ROOT_DIR/tools/scenarios/features/list_riverpod.json" "features/list_riverpod"
run_scenario "$ROOT_DIR/tools/scenarios/features/detail_screen.json" "features/detail_screen"
run_scenario "$ROOT_DIR/tools/scenarios/features/form_with_validation.json" "features/form_with_validation"
run_scenario "$ROOT_DIR/tools/scenarios/features/auth_screen.json" "features/auth_screen"
run_scenario "$ROOT_DIR/tools/scenarios/features/settings_screen.json" "features/settings_screen"

echo "All scenarios executed."


