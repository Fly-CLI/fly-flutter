#!/usr/bin/env bash

# Install Fly CLI locally for development
# Activates the CLI from local source

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
      echo "Install Fly CLI locally for development."
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

# Check if packages/fly_cli exists
if [ ! -d "packages/fly_cli" ]; then
  echo -e "${RED}Error: packages/fly_cli not found${NC}"
  echo "Make sure you're running this from the project root"
  exit 1
fi

echo -e "${GREEN}Installing Fly CLI locally...${NC}"
echo ""

# Install CLI
if [ "$VERBOSE" = true ]; then
  dart pub global activate --source path packages/fly_cli
else
  dart pub global activate --source path packages/fly_cli 2>&1 | grep -v "^Resolving\|^Got\|^Precompiling"
fi

# Check exit code
if [ $? -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ CLI installed successfully${NC}"
  echo ""
  
  # Check if fly command is available
  if command -v fly &> /dev/null; then
    echo "Fly CLI is now available as 'fly' command"
    fly --version 2>/dev/null || echo "Run 'fly --version' to verify"
  else
    echo -e "${YELLOW}Warning: 'fly' command not found in PATH${NC}"
    echo ""
    echo "Add to PATH:"
    echo "  export PATH=\"\$PATH:\$HOME/.pub-cache/bin\""
    echo ""
    echo "Or run directly:"
    echo "  dart pub global run fly_cli:fly"
  fi
  
  echo ""
  echo "Next step:"
  echo "  Verify installation: ./scripts/setup/verify.sh"
  exit 0
else
  echo ""
  echo -e "${RED}✗ Installation failed${NC}"
  exit 1
fi

