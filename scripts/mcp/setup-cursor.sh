#!/usr/bin/env bash

# Setup Cursor MCP integration
# Creates or updates .cursor/mcp.json configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Parse arguments
OVERWRITE=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --overwrite)
      OVERWRITE=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Setup Cursor MCP integration by creating/updating .cursor/mcp.json"
      echo ""
      echo "Options:"
      echo "  --overwrite       Overwrite existing configuration"
      echo "  -h, --help        Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0"
      echo "  $0 --overwrite"
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

# Check if fly command is available
if ! command -v fly &> /dev/null; then
  echo -e "${RED}Error: fly command not found${NC}"
  echo ""
  echo "Install Fly CLI:"
  echo "  ./scripts/setup/install.sh"
  exit 1
fi

CURSOR_DIR=".cursor"
MCP_CONFIG="${CURSOR_DIR}/mcp.json"

# Check if .cursor directory exists
if [ ! -d "$CURSOR_DIR" ]; then
  echo -e "${GREEN}Creating .cursor directory...${NC}"
  mkdir -p "$CURSOR_DIR"
fi

# Check if config already exists
if [ -f "$MCP_CONFIG" ] && [ "$OVERWRITE" = false ]; then
  echo -e "${YELLOW}Configuration already exists: ${MCP_CONFIG}${NC}"
  echo ""
  echo "Use --overwrite to replace existing configuration"
  echo ""
  echo "Current configuration:"
  cat "$MCP_CONFIG"
  exit 0
fi

echo -e "${GREEN}Setting up Cursor MCP integration...${NC}"
echo ""

# Create MCP configuration
cat > "$MCP_CONFIG" << 'EOF'
{
  "mcpServers": {
    "fly": {
      "command": "fly",
      "args": ["mcp", "serve", "--stdio"],
      "cwd": "${workspaceRoot}"
    }
  }
}
EOF

echo -e "${GREEN}✓ Cursor MCP configuration created${NC}"
echo ""
echo "Configuration file: ${MCP_CONFIG}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Restart Cursor to load the configuration"
echo "  2. Verify setup: ./scripts/mcp/verify.sh"
echo ""

