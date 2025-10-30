#!/usr/bin/env bash

# Complete development iteration cycle
# Reloads CLI, validates test project, and provides next steps

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

# Flags
VERBOSE=false
SKIP_VALIDATE=false
SKIP_RELOAD=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    --skip-validate)
      SKIP_VALIDATE=true
      shift
      ;;
    --skip-reload)
      SKIP_RELOAD=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Complete development iteration cycle."
      echo "Reloads CLI, validates test project, and provides next steps."
      echo ""
      echo "Options:"
      echo "  -v, --verbose       Enable verbose output"
      echo "  --skip-validate    Skip test project validation"
      echo "  --skip-reload       Skip CLI reload"
      echo "  -h, --help         Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0                 # Full cycle (reload + validate)"
      echo "  $0 --skip-validate # Reload only"
      echo "  $0 --skip-reload   # Validate only"
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

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Fly CLI Development Cycle${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Step 1: Reload CLI
if [ "$SKIP_RELOAD" = false ]; then
  echo -e "${BLUE}Step 1: Reloading CLI...${NC}"
  echo ""
  
  if [ ! -d "packages/fly_cli" ]; then
    echo -e "${RED}Error: packages/fly_cli not found${NC}"
    echo "Make sure you're running this from the project root"
    exit 1
  fi
  
  if [ "$VERBOSE" = true ]; then
    dart pub global activate --source path packages/fly_cli
  else
    dart pub global activate --source path packages/fly_cli 2>&1 | grep -v "^Resolving\|^Got\|^Precompiling"
  fi
  
  if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ CLI reloaded successfully${NC}"
    
    # Check if fly command is available
    if command -v fly &> /dev/null; then
      if fly --version > /dev/null 2>&1; then
        VERSION=$(fly --version 2>/dev/null | head -n 1)
        echo "Version: ${VERSION}"
      fi
    fi
  else
    echo ""
    echo -e "${RED}✗ CLI reload failed${NC}"
    exit 1
  fi
  
  echo ""
else
  echo -e "${YELLOW}Step 1: Skipping CLI reload${NC}"
  echo ""
fi

# Step 2: Validate test project
if [ "$SKIP_VALIDATE" = false ]; then
  echo -e "${BLUE}Step 2: Validating test project...${NC}"
  echo ""
  
  if [ -f "${PROJECT_ROOT}/scripts/mcp/test-project.sh" ]; then
    "${PROJECT_ROOT}/scripts/mcp/test-project.sh" validate
    VALIDATE_EXIT=$?
    
    if [ $VALIDATE_EXIT -eq 0 ]; then
      echo ""
      echo -e "${GREEN}✓ Test project validation passed${NC}"
    else
      echo ""
      echo -e "${YELLOW}⚠ Test project validation had issues${NC}"
      echo "You may want to reset it: ./scripts/mcp/test-project.sh reset"
    fi
  else
    echo -e "${YELLOW}Warning: test-project.sh not found, skipping validation${NC}"
  fi
  
  echo ""
else
  echo -e "${YELLOW}Step 2: Skipping test project validation${NC}"
  echo ""
fi

# Step 3: Summary and next steps
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Development Cycle Complete${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ "$SKIP_RELOAD" = false ]; then
  echo -e "${YELLOW}⚠ IMPORTANT: Restart Cursor${NC}"
  echo ""
  echo "The CLI has been reloaded with your latest changes."
  echo "Cursor's MCP server needs to be restarted to use the new CLI version."
  echo ""
fi

echo "Next steps:"
echo ""
echo "  1. ${BLUE}Restart Cursor${NC} (quit and reopen)"
echo ""
echo "  2. Test your changes via Cursor:"
echo "     - Ask Cursor to test CLI features using MCP tools"
echo "     - Example: 'Add a ProductDetail screen to the catalog feature'"
echo "     - Example: 'Add an ApiService to the core feature'"
echo ""
echo "  3. Validate results:"
echo "     ${BLUE}./scripts/mcp/test-project.sh validate${NC}"
echo ""
echo "  4. Check generated files in:"
echo "     ${BLUE}examples/test_project/${NC}"
echo ""
echo "  5. If needed, reset test project:"
echo "     ${BLUE}./scripts/mcp/test-project.sh reset${NC}"
echo ""

# Check if test project exists
TEST_PROJECT_DIR="${PROJECT_ROOT}/examples/test_project"
if [ ! -d "$TEST_PROJECT_DIR" ]; then
  echo -e "${YELLOW}Note: Test project doesn't exist yet.${NC}"
  echo "Create it with: ${BLUE}./scripts/mcp/test-project.sh reset${NC}"
  echo ""
fi

# Check if Cursor MCP is configured
CURSOR_MCP="${PROJECT_ROOT}/.cursor/mcp.json"
if [ ! -f "$CURSOR_MCP" ]; then
  echo -e "${YELLOW}Note: Cursor MCP not configured.${NC}"
  echo "Set it up with: ${BLUE}./scripts/mcp/setup-cursor.sh${NC}"
  echo ""
fi

echo "For more details, see:"
echo "  ${BLUE}docs/testing/ai-assisted-development.md${NC}"
echo ""

