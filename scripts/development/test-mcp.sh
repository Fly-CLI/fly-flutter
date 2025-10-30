#!/usr/bin/env bash

# Run MCP conformance tests
# Runs the MCP conformance test script

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
      echo "Run MCP conformance tests."
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

# Check if test file exists
TEST_FILE="tool/ci/mcp_conformance_test.dart"
if [ ! -f "$TEST_FILE" ]; then
  echo -e "${RED}Error: MCP conformance test not found${NC}"
  echo "Expected: $TEST_FILE"
  exit 1
fi

echo -e "${GREEN}Running MCP conformance tests...${NC}"
echo ""

# Run MCP conformance test
if [ "$VERBOSE" = true ]; then
  dart run "$TEST_FILE" --verbose
else
  dart run "$TEST_FILE"
fi

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ MCP conformance tests passed${NC}"
  exit 0
else
  echo ""
  echo -e "${RED}✗ MCP conformance tests failed${NC}"
  exit $EXIT_CODE
fi

