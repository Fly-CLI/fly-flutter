#!/usr/bin/env bash

# Master test runner script
# Runs all test suites and generates comprehensive report

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

# Parse arguments
SUITE=""
VERBOSE=false
CLEAN=false
SKIP_SETUP=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -s|--suite)
      SUITE="$2"
      shift 2
      ;;
    -c|--clean)
      CLEAN=true
      shift
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    --skip-setup)
      SKIP_SETUP=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Run comprehensive CLI test suite."
      echo ""
      echo "Options:"
      echo "  -s, --suite NAME     Run specific test suite (project|screen|service|other|all)"
      echo "  -c, --clean          Clean test environment before running"
      echo "  -v, --verbose        Enable verbose output"
      echo "  --skip-setup         Skip test environment setup"
      echo "  -h, --help           Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0                    # Run all tests"
      echo "  $0 -s project         # Run only project tests"
      echo "  $0 -c                 # Clean and run all tests"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

# Setup test environment
if [ "$SKIP_SETUP" = false ]; then
  echo -e "${BLUE}Setting up test environment...${NC}"
  if [ "$CLEAN" = true ]; then
    "$SCRIPT_DIR/clean-test-env.sh" --full
  fi
  "$SCRIPT_DIR/setup-test-env.sh"
  echo ""
fi

# Create results directory
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="${TEST_WORKSPACE}/results/${TIMESTAMP}"
mkdir -p "$RESULTS_DIR"

# Test results
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0
SUITE_RESULTS=()

# Run test suite
run_suite() {
  local suite_name="$1"
  local suite_script="$2"
  
  echo -e "${BLUE}Running ${suite_name} tests...${NC}"
  echo "=========================================="
  
  if [ -f "$suite_script" ]; then
    if bash "$suite_script" 2>&1 | tee "${RESULTS_DIR}/${suite_name}.log"; then
      SUITE_RESULTS+=("${suite_name}: PASS")
      return 0
    else
      SUITE_RESULTS+=("${suite_name}: FAIL")
      return 1
    fi
  else
    echo -e "${RED}Test script not found: ${suite_script}${NC}"
    SUITE_RESULTS+=("${suite_name}: SKIP (script not found)")
    return 1
  fi
}

# Determine which suites to run
if [ -z "$SUITE" ] || [ "$SUITE" = "all" ]; then
  SUITES=("project" "screen" "service" "other")
else
  SUITES=("$SUITE")
fi

# Run test suites
echo -e "${BLUE}Starting test suite execution...${NC}"
echo ""

for suite in "${SUITES[@]}"; do
  case $suite in
    project)
      run_suite "generate_project" "$SCRIPT_DIR/run-test-generate-project.sh"
      ;;
    screen)
      run_suite "generate_screen" "$SCRIPT_DIR/run-test-generate-screen.sh"
      ;;
    service)
      run_suite "generate_service" "$SCRIPT_DIR/run-test-generate-service.sh"
      ;;
    other)
      run_suite "other_commands" "$SCRIPT_DIR/run-test-other-commands.sh"
      ;;
    *)
      echo -e "${RED}Unknown test suite: ${suite}${NC}"
      SUITE_RESULTS+=("${suite}: SKIP (unknown)")
      ;;
  esac
  echo ""
done

# Generate summary report
SUMMARY_FILE="${RESULTS_DIR}/test_summary.txt"
cat > "$SUMMARY_FILE" <<EOF
Fly CLI Manual Test Suite Summary
=================================
Date: $(date)
Test Workspace: ${TEST_WORKSPACE}
Results Directory: ${RESULTS_DIR}

Test Suites Executed:
EOF

for result in "${SUITE_RESULTS[@]}"; do
  echo "  - ${result}" >> "$SUMMARY_FILE"
done

cat >> "$SUMMARY_FILE" <<EOF

Test Results:
- Total Test Suites: ${#SUITE_RESULTS[@]}
- Passed: $(echo "${SUITE_RESULTS[@]}" | grep -c "PASS" || echo "0")
- Failed: $(echo "${SUITE_RESULTS[@]}" | grep -c "FAIL" || echo "0")
- Skipped: $(echo "${SUITE_RESULTS[@]}" | grep -c "SKIP" || echo "0")

Detailed logs:
EOF

for suite in "${SUITES[@]}"; do
  echo "  - ${suite}: ${RESULTS_DIR}/${suite}.log" >> "$SUMMARY_FILE"
done

# Display summary
echo -e "${BLUE}Test Suite Summary${NC}"
echo "=================="
echo ""
cat "$SUMMARY_FILE"
echo ""

# Check if all tests passed
if echo "${SUITE_RESULTS[@]}" | grep -q "FAIL"; then
  echo -e "${RED}✗ Some test suites failed${NC}"
  echo "See detailed logs in: ${RESULTS_DIR}"
  exit 1
else
  echo -e "${GREEN}✓ All test suites passed${NC}"
  echo "See detailed logs in: ${RESULTS_DIR}"
  exit 0
fi

