#!/usr/bin/env bash

# Bootstrap script for Fly CLI monorepo
# Bootstraps the monorepo using melos to install all package dependencies

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
      echo "Bootstrap the Fly CLI monorepo with melos."
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

# Check if melos is installed
if ! command -v melos &> /dev/null; then
  echo -e "${RED}Error: melos is not installed${NC}"
  echo ""
  echo "Install melos with:"
  echo "  dart pub global activate melos"
  echo ""
  echo "Then add to PATH:"
  echo "  export PATH=\"\$PATH:\$HOME/.pub-cache/bin\""
  exit 1
fi

# Change to project root
cd "${PROJECT_ROOT}"

# Check if melos.yaml exists
if [ ! -f "pubspec.yaml" ]; then
  echo -e "${RED}Error: pubspec.yaml not found${NC}"
  echo "Make sure you're running this from the project root"
  exit 1
fi

echo -e "${GREEN}Bootstraping Fly CLI monorepo...${NC}"
echo ""

# Run melos bootstrap
if [ "$VERBOSE" = true ]; then
  melos bootstrap --verbose
else
  melos bootstrap
fi

# Check exit code
if [ $? -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ Bootstrap successful${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. Install CLI: ./scripts/setup/install.sh"
  echo "  2. Verify installation: ./scripts/setup/verify.sh"
  exit 0
else
  echo ""
  echo -e "${RED}✗ Bootstrap failed${NC}"
  exit 1
fi

