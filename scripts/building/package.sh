#!/usr/bin/env bash

# Build a specific package
# Builds a Flutter package

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Package name and build mode
PACKAGE_NAME=""
BUILD_MODE="release"

# Verbose flag
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    --mode=*)
      BUILD_MODE="${1#*=}"
      shift
      ;;
    -h|--help)
      echo "Usage: $0 PACKAGE_NAME [OPTIONS]"
      echo ""
      echo "Build a specific package."
      echo ""
      echo "Arguments:"
      echo "  PACKAGE_NAME     Name of the package to build (required)"
      echo ""
      echo "Options:"
      echo "  --mode=MODE      Build mode (debug, release, profile)"
      echo "                   Default: release"
      echo "  -v, --verbose    Enable verbose output"
      echo "  -h, --help       Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0 fly_cli"
      echo "  $0 fly_cli --mode=debug"
      exit 0
      ;;
    -*)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Use -h or --help for usage information"
      exit 1
      ;;
    *)
      if [ -z "$PACKAGE_NAME" ]; then
        PACKAGE_NAME="$1"
      else
        echo -e "${RED}Error: Multiple package names provided${NC}"
        exit 1
      fi
      shift
      ;;
  esac
done

# Check for package name
if [ -z "$PACKAGE_NAME" ]; then
  echo -e "${RED}Error: PACKAGE_NAME is required${NC}"
  echo ""
  echo "Usage: $0 PACKAGE_NAME [OPTIONS]"
  echo "Use -h or --help for more information"
  echo ""
  echo "Available packages:"
  ls -1 packages/ | sed 's/^/  - /'
  exit 1
fi

# Change to project root
cd "${PROJECT_ROOT}"

# Check if package exists
PACKAGE_DIR="packages/${PACKAGE_NAME}"
if [ ! -d "$PACKAGE_DIR" ]; then
  echo -e "${RED}Error: Package '$PACKAGE_NAME' not found${NC}"
  echo ""
  echo "Available packages:"
  ls -1 packages/ | sed 's/^/  - /'
  exit 1
fi

# Check if it's a Flutter package
if [ ! -f "${PACKAGE_DIR}pubspec.yaml" ]; then
  echo -e "${RED}Error: Package '$PACKAGE_NAME' is not a Flutter package${NC}"
  exit 1
fi

echo -e "${GREEN}Building package: $PACKAGE_NAME${NC}"
echo "Build mode: $BUILD_MODE"
echo ""

cd "$PACKAGE_DIR"

# Build the package
if [ "$VERBOSE" = true ]; then
  flutter build --mode="$BUILD_MODE" --verbose
else
  flutter build --mode="$BUILD_MODE"
fi

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ Package built successfully${NC}"
  exit 0
else
  echo ""
  echo -e "${RED}✗ Build failed${NC}"
  exit $EXIT_CODE
fi

