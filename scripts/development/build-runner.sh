#!/usr/bin/env bash

# Run code generation with build_runner
# Wraps melos run build_runner

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
      echo "Run code generation with build_runner for all packages."
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

# Check if melos is installed
if ! command -v melos &> /dev/null; then
  echo -e "${RED}Error: melos is not installed${NC}"
  echo ""
  echo "Install melos with:"
  echo "  dart pub global activate melos"
  exit 1
fi

echo -e "${GREEN}Running code generation...${NC}"
echo ""

# Run build_runner
if [ "$VERBOSE" = true ]; then
  melos run build_runner --verbose
else
  melos run build_runner
fi

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ Code generation complete${NC}"
  exit 0
else
  echo ""
  echo -e "${RED}✗ Code generation failed${NC}"
  exit $EXIT_CODE
fi

