#!/usr/bin/env bash

# Verify MCP server setup
# Checks if MCP server can start and responds correctly

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
      echo "Verify MCP server setup and configuration."
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

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}MCP Server Verification${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Step 1: Check Fly CLI
echo -e "${GREEN}[1/4] Checking Fly CLI...${NC}"
if command -v fly &> /dev/null; then
  FLY_VERSION=$(fly --version 2>/dev/null || echo "unknown")
  echo -e "  ✓ Fly CLI found (version: $FLY_VERSION)"
else
  echo -e "  ${RED}✗ Fly CLI not found${NC}"
  echo ""
  echo "  Install Fly CLI:"
  echo "    ./scripts/setup/install.sh"
  exit 1
fi
echo ""

# Step 2: Check Flutter SDK
echo -e "${GREEN}[2/4] Checking Flutter SDK...${NC}"
if command -v flutter &> /dev/null; then
  FLUTTER_VERSION=$(flutter --version 2>/dev/null | head -n 1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n 1 || echo "unknown")
  echo -e "  ✓ Flutter SDK found (version: $FLUTTER_VERSION)"
else
  echo -e "  ${YELLOW}⚠ Flutter SDK not found${NC}"
  echo "  (MCP server can still run, but Flutter tools won't work)"
fi
echo ""

# Step 3: Check MCP configuration files
echo -e "${GREEN}[3/4] Checking MCP configuration...${NC}"

# Check Cursor config
CURSOR_CONFIG=".cursor/mcp.json"
if [ -f "$CURSOR_CONFIG" ]; then
  echo -e "  ✓ Cursor configuration found: $CURSOR_CONFIG"
  if [ "$VERBOSE" = true ]; then
    echo "    Configuration:"
    cat "$CURSOR_CONFIG" | sed 's/^/      /'
  fi
else
  echo -e "  ${YELLOW}⚠ Cursor configuration not found${NC}"
  echo "    Run: ./scripts/mcp/setup-cursor.sh"
fi

# Check Claude Desktop config
if [[ "$OSTYPE" == "darwin"* ]]; then
  CLAUDE_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  CLAUDE_CONFIG="$HOME/.config/Claude/claude_desktop_config.json"
else
  CLAUDE_CONFIG=""
fi

if [ -n "$CLAUDE_CONFIG" ] && [ -f "$CLAUDE_CONFIG" ]; then
  echo -e "  ✓ Claude Desktop configuration found: $CLAUDE_CONFIG"
  if [ "$VERBOSE" = true ]; then
    if command -v jq &> /dev/null; then
      echo "    MCP Servers configured:"
      jq -r '.mcpServers | keys[]' "$CLAUDE_CONFIG" 2>/dev/null | sed 's/^/      - /' || echo "      (Could not parse)"
    fi
  fi
else
  echo -e "  ${YELLOW}⚠ Claude Desktop configuration not found${NC}"
  echo "    Run: ./scripts/mcp/setup-claude.sh"
fi
echo ""

# Step 4: Run MCP diagnostics
echo -e "${GREEN}[4/4] Running MCP diagnostics...${NC}"
if [ "$VERBOSE" = true ]; then
  ./scripts/mcp/doctor.sh --verbose
else
  ./scripts/mcp/doctor.sh
fi

DIAG_EXIT=$?

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ $DIAG_EXIT -eq 0 ]; then
  echo -e "${GREEN}✓ MCP server verification passed${NC}"
  echo ""
  echo "To start the MCP server:"
  echo "  ./scripts/mcp/serve.sh --stdio"
  echo ""
  echo "To run conformance tests:"
  echo "  ./scripts/mcp/test.sh"
  exit 0
else
  echo -e "${RED}✗ MCP server verification failed${NC}"
  echo ""
  echo "Check the diagnostics output above for details"
  exit 1
fi

