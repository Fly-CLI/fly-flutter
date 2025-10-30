#!/usr/bin/env bash

# Run unit tests only
# Allows filtering by package name

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
PACKAGE_NAME=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [PACKAGE_NAME] [OPTIONS]"
      echo ""
      echo "Run unit tests only. Optionally filter by package name."
      echo ""
      echo "Arguments:"
      echo "  PACKAGE_NAME    (optional) Package name to test (e.g., fly_cli)"
      echo ""
      echo "Options:"
      echo "  -v, --verbose    Enable verbose output"
      echo "  -h, --help       Show this help message"
      exit 0
      ;;
    -*)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Use -h or --help for usage information"
      exit 1
      ;;
    *)
      PACKAGE_NAME="$1"
      shift
      ;;
  esac
done

# Change to project root
cd "${PROJECT_ROOT}"

echo -e "${GREEN}Running unit tests...${NC}"
echo ""

# If package name specified, run tests for that package
if [ -n "$PACKAGE_NAME" ]; then
  PACKAGE_DIR="packages/${PACKAGE_NAME}"
  
  if [ ! -d "$PACKAGE_DIR" ]; then
    echo -e "${RED}Error: Package '$PACKAGE_NAME' not found${NC}"
    echo ""
    echo "Available packages:"
    ls -1 packages/ | sed 's/^/  - /'
    exit 1
  fi
  
  echo "Testing package: $PACKAGE_NAME"
  echo ""
  
  cd "$PACKAGE_DIR"
  
  if [ "$VERBOSE" = true ]; then
    flutter test --verbose
  else
    flutter test
  fi
else
  # Run unit tests for all packages
  for package_dir in packages/*/; do
    if [ -d "${package_dir}test" ]; then
      package_name=$(basename "$package_dir")
      echo "Testing package: $package_name"
      
      cd "$package_dir"
      if [ "$VERBOSE" = true ]; then
        flutter test --verbose
      else
        flutter test
      fi
      cd "$PROJECT_ROOT"
    fi
  done
fi

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ Unit tests passed${NC}"
  exit 0
else
  echo ""
  echo -e "${RED}✗ Unit tests failed${NC}"
  exit $EXIT_CODE
fi

