#!/usr/bin/env bash
# Convenience wrapper for the integration scenarios runner
# This script delegates to the actual runner in packages/fly_cli/tool/integration_scenarios/

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ACTUAL_SCRIPT="${REPO_ROOT}/packages/fly_cli/tool/integration_scenarios/run-integration-scenarios.sh"

if [ ! -f "$ACTUAL_SCRIPT" ]; then
  echo "Error: Integration scenarios runner not found at: $ACTUAL_SCRIPT" >&2
  exit 1
fi

exec "$ACTUAL_SCRIPT" "$@"

