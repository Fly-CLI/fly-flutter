#!/usr/bin/env bash

# Run end-to-end tests
# Runs tests from test/e2e/ directories

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
      echo "Run end-to-end tests from test/e2e/ directories."
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

echo -e "${GREEN}Running E2E tests...${NC}"
echo ""

# Find and run E2E tests
FOUND_TESTS=false

for package_dir in packages/*/; do
  e2e_test_dir="${package_dir}test/e2e"
  
  if [ -d "$e2e_test_dir" ]; then
    package_name=$(basename "$package_dir")
    echo "Testing package: $package_name"
    
    cd "$package_dir"
    
    if [ "$VERBOSE" = true ]; then
      flutter test test/e2e/ --verbose
    else
      flutter test test/e2e/
    fi
    
    cd "$PROJECT_ROOT"
    FOUND_TESTS=true
  fi
done

# Also check root test/e2e/
if [ -d "test/e2e" ]; then
  echo "Testing root E2E tests"
  
  if [ "$VERBOSE" = true ]; then
    flutter test test/e2e/ --verbose
  else
    flutter test test/e2e/
  fi
  
  FOUND_TESTS=true
fi

if [ "$FOUND_TESTS" = false ]; then
  echo -e "${YELLOW}No E2E tests found${NC}"
  exit 0
fi

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ E2E tests passed${NC}"
  exit 0
else
  echo ""
  echo -e "${RED}✗ E2E tests failed${NC}"
  exit $EXIT_CODE
fi

