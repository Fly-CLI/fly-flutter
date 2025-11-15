#!/usr/bin/env bash

# Test execution script for Generate Project command
# Runs all test cases from the manual testing plan

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
TEST_LOG="${RESULTS_DIR}/generate_project_tests.log"

# Initialize log
cat > "$TEST_LOG" <<EOF
Generate Project Command Test Results
======================================
Date: $(date)
Test Workspace: ${TEST_WORKSPACE}
Results Directory: ${RESULTS_DIR}

EOF

# Helper function to run a test
run_test() {
  local test_name="$1"
  local command="$2"
  local expected_exit="${3:-0}"
  local expected_output="${4:-}"
  
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

echo -e "${BLUE}Running Generate Project Command Tests...${NC}"
echo ""

mkdir -p "$TEST_WORKSPACE/projects"
cd "$TEST_WORKSPACE/projects"

# Basic Functionality Tests
echo -e "${YELLOW}Basic Functionality Tests${NC}"
run_test "Default riverpod template" \
  "fly create test_app_default" 0

run_test "Minimal template" \
  "fly create test_app_minimal --template=fly_foundation" 0

run_test "Explicit platforms" \
  "fly create test_app_platforms --template=fly_foundation --platforms=ios,android" 0

run_test "Custom organization" \
  "fly create test_app_org --organization=com.test.app" 0

run_test "Custom output directory" \
  "fly create test_app_output --output-dir=${TEST_WORKSPACE}/artifacts" 0

# Template Validation Tests
echo -e "${YELLOW}Template Validation Tests${NC}"
run_test "Verify minimal structure exists" \
  "test -d test_app_minimal && test -f test_app_minimal/pubspec.yaml" 0

run_test "Verify riverpod structure exists" \
  "test -d test_app_default && test -f test_app_default/pubspec.yaml" 0

run_test "Invalid template should fail" \
  "fly create test_app_invalid --template=invalid" 1

# Platform Validation Tests
echo -e "${YELLOW}Platform Validation Tests${NC}"
run_test "Multiple platforms" \
  "fly create test_app_multi --platforms=ios,android,web" 0

run_test "Invalid platform should fail" \
  "fly create test_app_bad_platform --platforms=invalid" 1

# Error Scenarios
echo -e "${YELLOW}Error Scenario Tests${NC}"
run_test "Missing project name should fail" \
  "fly create" 1

run_test "Invalid name (uppercase) should fail" \
  "fly create TestApp" 1

# Plan Mode Tests
echo -e "${YELLOW}Plan Mode Tests${NC}"
run_test "Plan mode should show plan" \
  "fly create test_app_plan --plan" 0

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

