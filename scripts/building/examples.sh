#!/usr/bin/env bash

# Build all example apps
# Wraps melos run build:examples

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Platform filter
PLATFORM="apk"

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
      echo "Usage: $0 [PLATFORM] [OPTIONS]"
      echo ""
      echo "Build all example apps."
      echo ""
      echo "Arguments:"
      echo "  PLATFORM         (optional) Platform to build (apk, ios, web, etc.)"
      echo "                   Default: apk"
      echo ""
      echo "Options:"
      echo "  -v, --verbose    Enable verbose output"
      echo "  -h, --help       Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0"
      echo "  $0 apk"
      echo "  $0 ios"
      exit 0
      ;;
    apk|ios|web|macos|windows|linux)
      PLATFORM="$1"
      shift
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

echo -e "${GREEN}Building all example apps for $PLATFORM...${NC}"
echo ""

# Build examples
# Note: melos build:examples only supports apk, so we may need to customize
if [ "$PLATFORM" = "apk" ]; then
  if [ "$VERBOSE" = true ]; then
    melos run build:examples --verbose
  else
    melos run build:examples
  fi
else
  # For other platforms, we need to build manually
  echo "Building examples for $PLATFORM..."
  for example_dir in examples/*/; do
    if [ -f "${example_dir}pubspec.yaml" ]; then
      example_name=$(basename "$example_dir")
      echo "Building $example_name for $PLATFORM..."
      cd "$example_dir"
      flutter build "$PLATFORM"
      cd "$PROJECT_ROOT"
    fi
  done
fi

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ Examples built successfully${NC}"
  exit 0
else
  echo ""
  echo -e "${RED}✗ Build failed${NC}"
  exit $EXIT_CODE
fi

