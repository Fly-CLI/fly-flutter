#!/usr/bin/env bash

# Test execution script for other CLI commands
# Tests: version, doctor, context, schema, completion, MCP

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
TEST_WORKSPACE="${HOME}/fly_test_workspace"
RESULTS_DIR="${TEST_WORKSPACE}/results/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULTS_DIR"

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
TEST_LOG="${RESULTS_DIR}/other_commands_tests.log"

# Initialize log
cat > "$TEST_LOG" <<EOF
Other CLI Commands Test Results
================================
Date: $(date)
Test Workspace: ${TEST_WORKSPACE}
Results Directory: ${RESULTS_DIR}

EOF

# Helper function to run a test
run_test() {
  local test_name="$1"
  local command="$2"
  local expected_exit="${3:-0}"
  
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  
  echo -e "${BLUE}Test ${TOTAL_TESTS}: ${test_name}${NC}"
  echo "Command: $command" | tee -a "$TEST_LOG"
  
  # Run command
  if eval "$command" >> "$TEST_LOG" 2>&1; then
    EXIT_CODE=$?
  else
    EXIT_CODE=$?
  fi
  
  # Check exit code
  if [ "$EXIT_CODE" -eq "$expected_exit" ]; then
    echo -e "${GREEN}  ✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo "Status: PASS" >> "$TEST_LOG"
  else
    echo -e "${RED}  ✗ FAIL (expected exit code ${expected_exit}, got ${EXIT_CODE})${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo "Status: FAIL (expected exit code ${expected_exit}, got ${EXIT_CODE})" >> "$TEST_LOG"
  fi
  
  echo "" | tee -a "$TEST_LOG"
}

# Check if CLI is available
if ! command -v fly &> /dev/null; then
  echo -e "${RED}Error: 'fly' command not found${NC}"
  echo "Install CLI: cd ${PROJECT_ROOT} && ./scripts/setup/install.sh"
  exit 1
fi

echo -e "${BLUE}Running Other Commands Tests...${NC}"
echo ""

# Version Command Tests
echo -e "${YELLOW}Version Command Tests${NC}"
run_test "Display version" \
  "fly version" 0

run_test "Version in human format" \
  "fly version --output=human" 0

run_test "Version in JSON format" \
  "fly version --output=json" 0

run_test "Global version flag" \
  "fly --version" 0

# Doctor Command Tests
echo -e "${YELLOW}Doctor Command Tests${NC}"
run_test "Run all diagnostics" \
  "fly doctor" 0

run_test "Doctor with verbose" \
  "fly doctor --verbose" 0

run_test "Doctor with JSON output" \
  "fly doctor --output=json" 0

# Context Command Tests
echo -e "${YELLOW}Context Command Tests${NC}"
cd "$TEST_WORKSPACE/projects"

# Create test project if needed
if [ ! -d "test_flutter_project" ]; then
  fly create test_flutter_project --template=fly_foundation || \
  fly generate project test_flutter_project --template=fly_foundation || true
fi

if [ -d "test_flutter_project" ]; then
  cd test_flutter_project
  
  run_test "Export context" \
    "fly context export" 0
  
  run_test "Export context with custom output" \
    "fly context export --output=${RESULTS_DIR}/context.json" 0
else
  echo -e "${YELLOW}  Skipping context tests (no Flutter project)${NC}"
fi

cd "$TEST_WORKSPACE"

# Schema Command Tests
echo -e "${YELLOW}Schema Command Tests${NC}"
run_test "Export all schemas" \
  "fly schema export" 0

run_test "Export schema with JSON Schema format" \
  "fly schema export --format=json-schema" 0

run_test "Export schema with custom output" \
  "fly schema export --output=${RESULTS_DIR}/schema.json" 0

# Completion Command Tests
echo -e "${YELLOW}Completion Command Tests${NC}"
run_test "Generate bash completion" \
  "fly completion bash" 0

run_test "Generate zsh completion" \
  "fly completion zsh" 0

run_test "Generate fish completion" \
  "fly completion fish" 0

run_test "Generate PowerShell completion" \
  "fly completion powershell" 0

run_test "Invalid shell should fail" \
  "fly completion invalid" 1

# Summary
echo ""
echo -e "${BLUE}Test Summary${NC}"
echo "============"
echo "Total Tests: ${TOTAL_TESTS}"
echo -e "${GREEN}Passed: ${PASSED_TESTS}${NC}"
echo -e "${RED}Failed: ${FAILED_TESTS}${NC}"
echo ""

# Save summary
cat >> "$TEST_LOG" <<EOF

Test Summary
============
Total Tests: ${TOTAL_TESTS}
Passed: ${PASSED_TESTS}
Failed: ${FAILED_TESTS}
EOF

# Exit with appropriate code
if [ $FAILED_TESTS -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  echo "See log: $TEST_LOG"
  exit 1
fi

