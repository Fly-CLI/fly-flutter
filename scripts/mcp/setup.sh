#!/usr/bin/env bash

# Setup MCP integration for Cursor and/or Claude Desktop
# Interactive setup script

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

# Parse arguments
SETUP_CURSOR=false
SETUP_CLAUDE=false
INTERACTIVE=true

while [[ $# -gt 0 ]]; do
  case $1 in
    --cursor)
      SETUP_CURSOR=true
      INTERACTIVE=false
      shift
      ;;
    --claude)
      SETUP_CLAUDE=true
      INTERACTIVE=false
      shift
      ;;
    --all)
      SETUP_CURSOR=true
      SETUP_CLAUDE=true
      INTERACTIVE=false
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Interactive setup script for MCP integration."
      echo ""
      echo "Options:"
      echo "  --cursor          Setup Cursor integration only"
      echo "  --claude          Setup Claude Desktop integration only"
      echo "  --all             Setup both Cursor and Claude Desktop"
      echo "  -h, --help        Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0                # Interactive setup"
      echo "  $0 --cursor       # Setup Cursor only"
      echo "  $0 --claude        # Setup Claude Desktop only"
      echo "  $0 --all           # Setup both"
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
echo -e "${BLUE}Fly MCP Integration Setup${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check prerequisites
if ! command -v fly &> /dev/null; then
  echo -e "${RED}Error: Fly CLI not found${NC}"
  echo ""
  echo "Install Fly CLI first:"
  echo "  ./scripts/setup/install.sh"
  exit 1
fi

# Interactive mode
if [ "$INTERACTIVE" = true ]; then
  echo "Which integrations would you like to setup?"
  echo ""
  echo "  1) Cursor only"
  echo "  2) Claude Desktop only"
  echo "  3) Both"
  echo "  4) Cancel"
  echo ""
  read -p "Enter choice [1-4]: " choice
  
  case $choice in
    1)
      SETUP_CURSOR=true
      ;;
    2)
      SETUP_CLAUDE=true
      ;;
    3)
      SETUP_CURSOR=true
      SETUP_CLAUDE=true
      ;;
    4)
      echo "Cancelled"
      exit 0
      ;;
    *)
      echo -e "${RED}Invalid choice${NC}"
      exit 1
      ;;
  esac
fi

# Setup Cursor
if [ "$SETUP_CURSOR" = true ]; then
  echo ""
  echo -e "${GREEN}Setting up Cursor integration...${NC}"
  ./scripts/mcp/setup-cursor.sh --overwrite
fi

# Setup Claude Desktop
if [ "$SETUP_CLAUDE" = true ]; then
  echo ""
  echo -e "${GREEN}Setting up Claude Desktop integration...${NC}"
  ./scripts/mcp/setup-claude.sh --overwrite
fi

# Final verification
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Restart Cursor and/or Claude Desktop"
echo "  2. Verify setup: ./scripts/mcp/verify.sh"
echo "  3. Test MCP server: ./scripts/mcp/test.sh"
echo ""
echo "To start the MCP server:"
echo "  ./scripts/mcp/serve.sh --stdio"
echo ""

