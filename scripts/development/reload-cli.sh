#!/usr/bin/env bash

# Reload Fly CLI after code changes
# Reinstalls CLI locally and reminds about Cursor restart

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
      echo "Reload Fly CLI after code changes."
      echo "Reinstalls CLI locally and reminds about Cursor restart."
      echo ""
      echo "Options:"
      echo "  -v, --verbose    Enable verbose output"
      echo "  -h, --help       Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0                # Reload CLI"
      echo "  $0 --verbose      # Reload CLI with verbose output"
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

echo -e "${BLUE}Reloading Fly CLI...${NC}"
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
  echo -e "${GREEN}✓ CLI reloaded successfully${NC}"
  echo ""
  
  # Check if fly command is available
  if command -v fly &> /dev/null; then
    echo -e "${GREEN}Fly CLI is available as 'fly' command${NC}"
    if fly --version > /dev/null 2>&1; then
      VERSION=$(fly --version 2>/dev/null | head -n 1)
      echo "Version: ${VERSION}"
    fi
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
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}⚠ IMPORTANT: Restart Cursor${NC}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "The CLI has been reloaded with your latest changes."
  echo "Cursor's MCP server needs to be restarted to use the new CLI version."
  echo ""
  echo "Next steps:"
  echo "  1. ${BLUE}Restart Cursor${NC} (quit and reopen)"
  echo "  2. Test your changes via Cursor using MCP tools"
  echo "  3. Validate test project: ./scripts/mcp/test-project.sh validate"
  echo ""
  echo "Or run full development cycle:"
  echo "  ${BLUE}./scripts/development/dev-cycle.sh${NC}"
  echo ""
  exit 0
else
  echo ""
  echo -e "${RED}✗ CLI reload failed${NC}"
  exit 1
fi

