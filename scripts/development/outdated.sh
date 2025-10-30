#!/usr/bin/env bash

# Check for outdated dependencies
# Wraps melos run outdated

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
      echo "Check for outdated dependencies across all packages."
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

echo -e "${GREEN}Checking for outdated dependencies...${NC}"
echo ""

# Run outdated check
if [ "$VERBOSE" = true ]; then
  melos run outdated --verbose
else
  melos run outdated
fi

EXIT_CODE=$?

# Note: outdated command might exit with non-zero if outdated packages found
# This is expected behavior, so we don't fail the script
if [ $EXIT_CODE -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ All dependencies are up to date${NC}"
  exit 0
else
  echo ""
  echo -e "${YELLOW}⚠ Some dependencies may be outdated${NC}"
  echo "Review the output above for details"
  exit 0  # Don't fail - outdated check is informational
fi

