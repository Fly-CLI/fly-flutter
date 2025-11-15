#!/usr/bin/env bash

# Test execution script for Generate Service command
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
TEST_LOG="${RESULTS_DIR}/generate_service_tests.log"

# Initialize log
cat > "$TEST_LOG" <<EOF
Generate Service Command Test Results
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

# Create test Flutter project first
echo -e "${BLUE}Setting up test Flutter project...${NC}"
cd "$TEST_WORKSPACE/projects"

if [ ! -d "test_flutter_project" ]; then
  echo "Creating test Flutter project..."
  # Use fly create (alias for generate project)
  fly create test_flutter_project --template=fly_foundation || {
    echo -e "${YELLOW}Warning: Could not create test project. Some tests may fail.${NC}"
    echo "You may need to create the project manually:"
    echo "  cd ${TEST_WORKSPACE}/projects"
    echo "  fly create test_flutter_project --template=fly_foundation"
  }
fi

if [ -d "test_flutter_project" ]; then
  cd test_flutter_project
else
  echo -e "${RED}Failed: test_flutter_project not found after creation attempt${NC}"
  exit 1
fi

echo -e "${BLUE}Running Generate Service Command Tests...${NC}"
echo ""

# Basic Functionality Tests
echo -e "${YELLOW}Basic Functionality Tests${NC}"
run_test "Default API service" \
  "fly generate service auth_service" 0

run_test "Explicit API type" \
  "fly generate service user_service --type=api" 0

run_test "Cache service type" \
  "fly generate service cache_service --type=cache" 0

run_test "Storage service type" \
  "fly generate service storage_service --type=storage" 0

run_test "Analytics service type" \
  "fly generate service analytics_service --type=analytics" 0

run_test "Local service type" \
  "fly generate service local_service --type=local" 0

# API Service Specific Tests
echo -e "${YELLOW}API Service Specific Tests${NC}"
run_test "API with base URL" \
  "fly generate service api_service --type=api --base-url=https://api.example.com" 0

run_test "API with interceptors" \
  "fly generate service api_interceptors --type=api --with-interceptors" 0

# Flag Combinations
echo -e "${YELLOW}Flag Combination Tests${NC}"
run_test "With tests" \
  "fly generate service auth_tests --with-tests" 0

run_test "With mocks" \
  "fly generate service auth_mocks --with-mocks" 0

run_test "With tests and mocks" \
  "fly generate service auth_both --with-tests --with-mocks" 0

# Error Scenarios
echo -e "${YELLOW}Error Scenario Tests${NC}"
run_test "Missing service name should fail" \
  "fly generate service" 1

run_test "Invalid name (uppercase) should fail" \
  "fly generate service AuthService" 1

run_test "Invalid type should fail" \
  "fly generate service auth --type=invalid" 1

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

