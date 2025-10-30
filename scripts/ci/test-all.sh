#!/usr/bin/env bash

# Run all CI tests (analysis, formatting, tests)
# Comprehensive CI test suite

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Verbose flag
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Run all CI tests (analysis, formatting, tests)."
      echo ""
      echo "Options:"
      echo "  -v, --verbose    Enable verbose output"
      echo "  -h, --help       Show this help message"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Use -h or --help for usage information"
      exit 1
      ;;
  esac
done

# Change to project root
cd "${PROJECT_ROOT}"

echo -e "${GREEN}Running CI test suite...${NC}"
echo ""

FAILED_STEPS=()

# Step 1: Run analysis
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1/3: Running analysis"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$VERBOSE" = true ]; then
  "${PROJECT_ROOT}/scripts/development/analyze.sh" --verbose
else
  "${PROJECT_ROOT}/scripts/development/analyze.sh"
fi

if [ $? -ne 0 ]; then
  FAILED_STEPS+=("analysis")
fi

echo ""

# Step 2: Check formatting
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2/3: Checking formatting"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$VERBOSE" = true ]; then
  "${PROJECT_ROOT}/scripts/development/format-check.sh" --verbose
else
  "${PROJECT_ROOT}/scripts/development/format-check.sh"
fi

if [ $? -ne 0 ]; then
  FAILED_STEPS+=("formatting")
fi

echo ""

# Step 3: Run tests
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3/3: Running tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$VERBOSE" = true ]; then
  "${PROJECT_ROOT}/scripts/development/test.sh" --verbose
else
  "${PROJECT_ROOT}/scripts/development/test.sh"
fi

if [ $? -ne 0 ]; then
  FAILED_STEPS+=("tests")
fi

echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "CI Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ${#FAILED_STEPS[@]} -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ All CI tests passed${NC}"
  exit 0
else
  echo ""
  echo -e "${RED}✗ CI tests failed in the following steps:${NC}"
  for step in "${FAILED_STEPS[@]}"; do
    echo "  - $step"
  done
  echo ""
  exit 1
fi

