#!/usr/bin/env bash

# Bump version across packages
# Uses melos version command if available, otherwise manual bump

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Version to bump to
VERSION=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: $0 [VERSION]"
      echo ""
      echo "Bump version across packages."
      echo ""
      echo "Arguments:"
      echo "  VERSION          (optional) Version to bump to (e.g., 0.2.0)"
      echo "                   If not provided, melos will suggest a version"
      echo ""
      echo "Options:"
      echo "  -h, --help       Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0                # Bump patch version (0.1.0 -> 0.1.1)"
      echo "  $0 0.2.0          # Bump to specific version"
      exit 0
      ;;
    *)
      if [ -z "$VERSION" ]; then
        VERSION="$1"
      else
        echo -e "${RED}Error: Multiple versions provided${NC}"
        exit 1
      fi
      shift
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

echo -e "${GREEN}Bumping version...${NC}"
echo ""

# Use melos version command
if [ -n "$VERSION" ]; then
  echo "Bumping to version: $VERSION"
  melos version "$VERSION"
else
  echo "Bumping patch version (melos will suggest version)"
  melos version
fi

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ Version bumped successfully${NC}"
  exit 0
else
  echo ""
  echo -e "${RED}✗ Version bump failed${NC}"
  exit $EXIT_CODE
fi

