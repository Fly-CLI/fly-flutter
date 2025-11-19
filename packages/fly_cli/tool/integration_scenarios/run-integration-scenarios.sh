#!/usr/bin/env bash
# Run Fly CLI integration scenarios via Fly or Mason and compare against goldens.
#
# This script:
# 1. Discovers all JSON scenario files under the scenarios directory
# 2. Parses each scenario JSON to extract parameters
# 3. Executes scenarios using either Fly CLI or Mason (based on mode)
# 4. Compares generated outputs against golden directories
# 5. Reports summary of all scenario execution results
#
# The JSON schema is shared with the Dart scenarios_test.dart harness.

set -euo pipefail

# ============================================================================
# Path Resolution
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Script is at: packages/fly_cli/tool/integration_scenarios/run-integration-scenarios.sh
# Need to go up 4 levels to reach repo root
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../" && pwd)"
FLY_CLI_DIR="${REPO_ROOT}/packages/fly_cli"
SCENARIOS_ROOT="${FLY_CLI_DIR}/tool/integration_scenarios"
SCENARIOS_DIR="${SCENARIOS_ROOT}/scenarios"
OUT_ROOT="${SCENARIOS_ROOT}/.scenario_out"
GOLDENS_DIR="${SCENARIOS_ROOT}/goldens"

# ============================================================================
# Configuration and State
# ============================================================================

MODE="${FLY_SCENARIO_MODE:-fly}"
ACCEPT_MISSING_GOLDENS=false
KEEP_TEMP=false
VERBOSE=false

# Counters for summary reporting
TOTAL_SCENARIOS=0
PASSED_SCENARIOS=0
FAILED_SCENARIOS=0
SKIPPED_SCENARIOS=0

# ============================================================================
# Helper Functions
# ============================================================================

# Print error message and exit
error_exit() {
  echo "Error: $1" >&2
  exit 1
}

# Print verbose message if verbose mode is enabled
verbose_log() {
  if [ "$VERBOSE" = true ]; then
    echo "[VERBOSE] $1" >&2
  fi
}

# Run a command and capture exit code (non-fatal)
run_command() {
  local cmd="$1"
  verbose_log "Executing: $cmd"
  if eval "$cmd"; then
    return 0
  else
    return 1
  fi
}

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# ============================================================================
# Pre-flight Checks
# ============================================================================

check_dependencies() {
  # Always require jq for JSON parsing
  if ! command_exists jq; then
    error_exit "jq is required but not found. Install it with: brew install jq (macOS) or apt-get install jq (Linux)"
  fi

  # Check mode-specific dependencies
  if [ "$MODE" = "fly" ]; then
    if ! command_exists fly; then
      error_exit "fly CLI is required but not found. Install it with: ./scripts/setup/install.sh"
    fi
  elif [ "$MODE" = "mason" ]; then
    if ! command_exists mason; then
      error_exit "mason CLI is required but not found. Install it with: dart pub global activate mason_cli"
    fi
    if [ ! -f "${REPO_ROOT}/mason.yaml" ]; then
      error_exit "mason.yaml not found at ${REPO_ROOT}/mason.yaml"
    fi
  else
    error_exit "Invalid mode: $MODE. Must be 'fly' or 'mason'"
  fi

  verbose_log "Mode: $MODE"
  verbose_log "Scenarios directory: $SCENARIOS_DIR"
  verbose_log "Goldens directory: $GOLDENS_DIR"
  verbose_log "Output root: $OUT_ROOT"
}

# ============================================================================
# CLI Argument Parsing
# ============================================================================

show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Run Fly CLI integration scenarios via Fly or Mason and compare against goldens.

Options:
  --mode=fly|mason          Execution mode (default: fly)
  --scenario-dir PATH       Override scenarios directory
  --out-dir PATH            Override output directory
  --accept-missing-goldens   Automatically accept missing goldens
  --keep-temp               Keep temporary output directories after completion
  --verbose                 Enable verbose logging
  -h, --help                Show this help message

Environment Variables:
  FLY_SCENARIO_MODE         Default execution mode (fly|mason)
  FLY_SCENARIO_OUT_DIR      Override output directory

Examples:
  $0 --mode=fly
  $0 --mode=mason --verbose
  FLY_SCENARIO_MODE=mason $0

EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --mode=*)
        MODE="${1#*=}"
        shift
        ;;
      --scenario-dir)
        SCENARIOS_DIR="$2"
        shift 2
        ;;
      --out-dir)
        OUT_ROOT="$2"
        shift 2
        ;;
      --accept-missing-goldens)
        ACCEPT_MISSING_GOLDENS=true
        shift
        ;;
      --keep-temp)
        KEEP_TEMP=true
        shift
        ;;
      --verbose)
        VERBOSE=true
        shift
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      *)
        error_exit "Unknown option: $1. Use --help for usage."
        ;;
    esac
  done

  # Apply environment variable overrides
  if [ -n "${FLY_SCENARIO_OUT_DIR:-}" ]; then
    OUT_ROOT="$FLY_SCENARIO_OUT_DIR"
  fi
}

# ============================================================================
# Scenario Discovery and JSON Parsing
# ============================================================================

# Derive screen_type from scenario_id for features
derive_screen_type() {
  local scenario_id="$1"
  case "$scenario_id" in
    list_riverpod) echo "list" ;;
    detail_screen) echo "detail" ;;
    form_with_validation) echo "form" ;;
    auth_screen) echo "auth" ;;
    settings_screen) echo "settings" ;;
    *) echo "" ;;
  esac
}

# Derive service_type from scenario_id for services
derive_service_type() {
  local scenario_id="$1"
  case "$scenario_id" in
    api_*) echo "api" ;;
    local_minimal) echo "local" ;;
    cache_service) echo "cache" ;;
    analytics_service) echo "analytics" ;;
    storage_service) echo "storage" ;;
    *)
      echo "api"  # Default
      echo "Warning: Could not derive service type from scenario_id: $scenario_id, defaulting to 'api'" >&2
      ;;
  esac
}

# Extract JSON field with jq
get_json_field() {
  local json_file="$1"
  local field="$2"
  jq -r ".${field} // empty" "$json_file" 2>/dev/null || echo ""
}

# Extract JSON array field and join with commas
get_json_array_field() {
  local json_file="$1"
  local field="$2"
  jq -r ".${field} // [] | join(\",\")" "$json_file" 2>/dev/null || echo ""
}

# ============================================================================
# Scenario Execution (Fly CLI Mode)
# ============================================================================

execute_fly_project() {
  local scenario_path="$1"
  local scenario_out_dir="$2"
  local name="$3"
  local description="$4"
  local organization="$5"
  local platforms="$6"
  local preset="$7"

  local cmd="fly generate project \"${name}\" --output-dir=\"${scenario_out_dir}\""

  if [ -n "$description" ]; then
    cmd="${cmd} --description=\"${description}\""
  fi
  if [ -n "$organization" ]; then
    cmd="${cmd} --organization=\"${organization}\""
  fi
  if [ -n "$platforms" ]; then
    cmd="${cmd} --platforms=${platforms}"
  fi
  if [ -n "$preset" ]; then
    cmd="${cmd} --template=fly_foundation"
  fi

  run_command "$cmd"
}

execute_fly_feature() {
  local scenario_path="$1"
  local scenario_out_dir="$2"
  local name="$3"
  local screen_type="$4"

  local base_project_dir="${scenario_out_dir}/test_project"

  # Ensure base project exists
  if [ ! -d "$base_project_dir" ]; then
    verbose_log "Creating base project for feature scenario"
    if ! run_command "fly generate project test_project --template=fly_foundation --output-dir=\"${scenario_out_dir}\""; then
      return 1
    fi
  fi

  local cmd="fly generate feature \"${name}\" --output-dir=\"${base_project_dir}\""
  if [ -n "$screen_type" ]; then
    cmd="${cmd} --type=\"${screen_type}\""
  fi

  run_command "$cmd"
}

execute_fly_service() {
  local scenario_path="$1"
  local scenario_out_dir="$2"
  local name="$3"
  local service_type="$4"

  local base_project_dir="${scenario_out_dir}/test_project"

  # Ensure base project exists
  if [ ! -d "$base_project_dir" ]; then
    verbose_log "Creating base project for service scenario"
    if ! run_command "fly generate project test_project --template=fly_foundation --output-dir=\"${scenario_out_dir}\""; then
      return 1
    fi
  fi

  local cmd="fly generate service \"${name}\" --output-dir=\"${base_project_dir}\" --type=\"${service_type}\""
  run_command "$cmd"
}

# ============================================================================
# Scenario Execution (Mason Mode)
# ============================================================================

execute_mason_project() {
  local scenario_path="$1"
  local scenario_out_dir="$2"

  # Change to output directory and run mason
  (
    cd "$scenario_out_dir" || return 1
    run_command "mason make fly_foundation_project -c \"${scenario_path}\" --on-conflict overwrite"
  )
}

execute_mason_feature() {
  local scenario_path="$1"
  local scenario_out_dir="$2"

  local base_project_dir="${scenario_out_dir}/test_project"

  # Ensure base project exists using Mason
  if [ ! -d "$base_project_dir" ]; then
    verbose_log "Creating base project for feature scenario using Mason"
    # Create a minimal config for base project
    local base_config="${scenario_out_dir}/.base_project_config.json"
    cat > "$base_config" <<EOF
{
  "generation_mode": "project",
  "name": "test_project",
  "organization": "com.example",
  "platforms": ["ios", "android"],
  "preset": "minimal"
}
EOF
    (
      cd "$scenario_out_dir" || return 1
      if ! run_command "mason make fly_foundation_project -c \"${base_config}\" --on-conflict overwrite"; then
        rm -f "$base_config"
        return 1
      fi
      rm -f "$base_config"
    )
  fi

  # Run feature generation from within base project
  (
    cd "$base_project_dir" || return 1
    run_command "mason make fly_foundation_feature -c \"${scenario_path}\" --on-conflict overwrite"
  )
}

execute_mason_service() {
  local scenario_path="$1"
  local scenario_out_dir="$2"

  local base_project_dir="${scenario_out_dir}/test_project"

  # Ensure base project exists using Mason
  if [ ! -d "$base_project_dir" ]; then
    verbose_log "Creating base project for service scenario using Mason"
    # Create a minimal config for base project
    local base_config="${scenario_out_dir}/.base_project_config.json"
    cat > "$base_config" <<EOF
{
  "generation_mode": "project",
  "name": "test_project",
  "organization": "com.example",
  "platforms": ["ios", "android"],
  "preset": "minimal"
}
EOF
    (
      cd "$scenario_out_dir" || return 1
      if ! run_command "mason make fly_foundation_project -c \"${base_config}\" --on-conflict overwrite"; then
        rm -f "$base_config"
        return 1
      fi
      rm -f "$base_config"
    )
  fi

  # Run service generation from within base project
  (
    cd "$base_project_dir" || return 1
    run_command "mason make fly_foundation_service -c \"${scenario_path}\" --on-conflict overwrite"
  )
}

# ============================================================================
# Golden Comparison
# ============================================================================

compare_with_golden() {
  local scenario_id="$1"
  local actual_dir="$2"
  local generation_mode="$3"
  local project_name="$4"

  local golden_dir="${GOLDENS_DIR}/${scenario_id}"

  if [ ! -d "$golden_dir" ]; then
    if [ "$ACCEPT_MISSING_GOLDENS" = true ]; then
      echo "  → Accepting output as new golden for ${scenario_id}"
      mkdir -p "$golden_dir"
      cp -R "$actual_dir"/* "$golden_dir/" 2>/dev/null || true
      return 0
    else
      echo "  ⚠ No golden found for ${scenario_id}. You can accept the output as the new golden:"
      echo "    cp -R \"${actual_dir}\" \"${golden_dir}\""
      return 0  # Not a failure, just missing golden
    fi
  fi

  # Run diff comparison
  if diff -ru "$golden_dir" "$actual_dir" >/dev/null 2>&1; then
    return 0
  else
    echo "  ✗ Golden diff detected for ${scenario_id}"
    echo "    Run 'diff -ru \"${golden_dir}\" \"${actual_dir}\"' to see differences"
    return 1
  fi
}

# ============================================================================
# Main Scenario Processing
# ============================================================================

process_scenario() {
  local scenario_path="$1"
  local scenario_id="$(basename "$scenario_path" .json)"
  local scenario_group="$(basename "$(dirname "$scenario_path")")"

  TOTAL_SCENARIOS=$((TOTAL_SCENARIOS + 1))

  echo "[${TOTAL_SCENARIOS}] Processing scenario: ${scenario_id} (${scenario_group})"

  # Parse JSON fields
  local generation_mode="$(get_json_field "$scenario_path" "generation_mode")"
  local name="$(get_json_field "$scenario_path" "name")"
  local description="$(get_json_field "$scenario_path" "description")"
  local organization="$(get_json_field "$scenario_path" "organization")"
  local platforms="$(get_json_array_field "$scenario_path" "platforms")"
  local preset="$(get_json_field "$scenario_path" "preset")"
  local screen_type="$(get_json_field "$scenario_path" "screen_type")"
  local service_type=""

  # Derive screen_type or service_type if missing
  if [ "$generation_mode" = "feature" ] && [ -z "$screen_type" ]; then
    screen_type="$(derive_screen_type "$scenario_id")"
  elif [ "$generation_mode" = "service" ]; then
    service_type="$(derive_service_type "$scenario_id")"
  fi

  # Create scenario output directory
  local scenario_out_dir="${OUT_ROOT}/${scenario_id}"
  if [ "$KEEP_TEMP" != true ]; then
    rm -rf "$scenario_out_dir"
  fi
  mkdir -p "$scenario_out_dir"

  # Execute scenario based on mode and generation_mode
  local execution_success=false
  local actual_dir=""

  if [ "$MODE" = "fly" ]; then
    case "$generation_mode" in
      project)
        if execute_fly_project "$scenario_path" "$scenario_out_dir" "$name" "$description" "$organization" "$platforms" "$preset"; then
          execution_success=true
          actual_dir="${scenario_out_dir}/${name}"
        fi
        ;;
      feature)
        if execute_fly_feature "$scenario_path" "$scenario_out_dir" "$name" "$screen_type"; then
          execution_success=true
          actual_dir="${scenario_out_dir}/test_project"
        fi
        ;;
      service)
        if execute_fly_service "$scenario_path" "$scenario_out_dir" "$name" "$service_type"; then
          execution_success=true
          actual_dir="${scenario_out_dir}/test_project"
        fi
        ;;
      *)
        echo "  ⚠ Unknown generation_mode: $generation_mode, skipping"
        SKIPPED_SCENARIOS=$((SKIPPED_SCENARIOS + 1))
        return
        ;;
    esac
  elif [ "$MODE" = "mason" ]; then
    case "$generation_mode" in
      project)
        if execute_mason_project "$scenario_path" "$scenario_out_dir"; then
          execution_success=true
          actual_dir="${scenario_out_dir}/${name}"
        fi
        ;;
      feature)
        if execute_mason_feature "$scenario_path" "$scenario_out_dir"; then
          execution_success=true
          actual_dir="${scenario_out_dir}/test_project"
        fi
        ;;
      service)
        if execute_mason_service "$scenario_path" "$scenario_out_dir"; then
          execution_success=true
          actual_dir="${scenario_out_dir}/test_project"
        fi
        ;;
      *)
        echo "  ⚠ Unknown generation_mode: $generation_mode, skipping"
        SKIPPED_SCENARIOS=$((SKIPPED_SCENARIOS + 1))
        return
        ;;
    esac
  fi

  if [ "$execution_success" != true ]; then
    echo "  ✗ Execution failed for ${scenario_id}"
    FAILED_SCENARIOS=$((FAILED_SCENARIOS + 1))
    return
  fi

  # Compare with golden
  if [ -d "$actual_dir" ]; then
    if compare_with_golden "$scenario_id" "$actual_dir" "$generation_mode" "$name"; then
      echo "  ✓ Scenario ${scenario_id} passed"
      PASSED_SCENARIOS=$((PASSED_SCENARIOS + 1))
    else
      echo "  ✗ Scenario ${scenario_id} failed (golden mismatch)"
      FAILED_SCENARIOS=$((FAILED_SCENARIOS + 1))
    fi
  else
    echo "  ✗ Output directory not found: ${actual_dir}"
    FAILED_SCENARIOS=$((FAILED_SCENARIOS + 1))
  fi
}

# ============================================================================
# Main Entry Point
# ============================================================================

main() {
  parse_args "$@"
  check_dependencies

  # Clean up output directory unless keep-temp is set
  if [ "$KEEP_TEMP" != true ] && [ -d "$OUT_ROOT" ]; then
    verbose_log "Cleaning up output directory: $OUT_ROOT"
    rm -rf "$OUT_ROOT"
  fi
  mkdir -p "$OUT_ROOT"

  # Discover and process all scenario files
  if [ ! -d "$SCENARIOS_DIR" ]; then
    error_exit "Scenarios directory not found: $SCENARIOS_DIR"
  fi

  local scenario_files
  scenario_files=$(find "$SCENARIOS_DIR" -type f -name '*.json' | sort)

  if [ -z "$scenario_files" ]; then
    echo "No scenario files found in $SCENARIOS_DIR"
    exit 0
  fi

  echo "Found $(echo "$scenario_files" | wc -l | tr -d ' ') scenario file(s)"
  echo ""

  # Process each scenario
  while IFS= read -r scenario_file; do
    [ -n "$scenario_file" ] && process_scenario "$scenario_file"
  done <<< "$scenario_files"

  # Print summary
  echo ""
  echo "=========================================="
  echo "Summary"
  echo "=========================================="
  echo "Scenarios: ${TOTAL_SCENARIOS} total, ${PASSED_SCENARIOS} passed, ${FAILED_SCENARIOS} failed, ${SKIPPED_SCENARIOS} skipped"
  echo ""

  # Clean up output directory unless keep-temp is set
  if [ "$KEEP_TEMP" != true ] && [ -d "$OUT_ROOT" ]; then
    verbose_log "Cleaning up output directory: $OUT_ROOT"
    rm -rf "$OUT_ROOT"
  fi

  # Exit with appropriate code
  if [ $FAILED_SCENARIOS -eq 0 ]; then
    exit 0
  else
    exit 1
  fi
}

main "$@"

