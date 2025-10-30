#!/usr/bin/env bash

# Setup Claude Desktop MCP integration
# Creates or updates Claude Desktop configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Detect platform
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  CLAUDE_CONFIG_DIR="$HOME/Library/Application Support/Claude"
  CLAUDE_CONFIG_FILE="${CLAUDE_CONFIG_DIR}/claude_desktop_config.json"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Linux
  CLAUDE_CONFIG_DIR="$HOME/.config/Claude"
  CLAUDE_CONFIG_FILE="${CLAUDE_CONFIG_DIR}/claude_desktop_config.json"
else
  echo -e "${RED}Error: Unsupported platform${NC}"
  echo "This script supports macOS and Linux only"
  echo "For Windows, manually configure Claude Desktop"
  exit 1
fi

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
      echo "Setup Claude Desktop MCP integration."
      echo ""
      echo "Options:"
      echo "  --overwrite       Overwrite existing configuration"
      echo "  -h, --help        Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0"
      echo "  $0 --overwrite"
      echo ""
      echo "Note: Claude Desktop must be restarted after configuration"
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

# Create Claude config directory if it doesn't exist
if [ ! -d "$CLAUDE_CONFIG_DIR" ]; then
  echo -e "${GREEN}Creating Claude config directory...${NC}"
  mkdir -p "$CLAUDE_CONFIG_DIR"
fi

# Check if config already exists
if [ -f "$CLAUDE_CONFIG_FILE" ]; then
  if [ "$OVERWRITE" = false ]; then
    echo -e "${YELLOW}Configuration already exists: ${CLAUDE_CONFIG_FILE}${NC}"
    echo ""
    echo "Use --overwrite to replace existing configuration"
    echo ""
    echo "Current configuration:"
    cat "$CLAUDE_CONFIG_FILE"
    exit 0
  else
    echo -e "${YELLOW}Backing up existing configuration...${NC}"
    cp "$CLAUDE_CONFIG_FILE" "${CLAUDE_CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
  fi
fi

echo -e "${GREEN}Setting up Claude Desktop MCP integration...${NC}"
echo ""

# Check if config file exists and has content
if [ -f "$CLAUDE_CONFIG_FILE" ] && [ -s "$CLAUDE_CONFIG_FILE" ]; then
  # Parse existing JSON and merge (requires jq)
  if command -v jq &> /dev/null; then
    echo "Merging with existing configuration..."
    # Read existing config
    if jq empty "$CLAUDE_CONFIG_FILE" 2>/dev/null; then
      # Valid JSON - merge
      jq '.mcpServers.fly = {
        "command": "fly",
        "args": ["mcp", "serve", "--stdio"],
        "cwd": "${workspaceRoot}"
      }' "$CLAUDE_CONFIG_FILE" > "${CLAUDE_CONFIG_FILE}.tmp" && mv "${CLAUDE_CONFIG_FILE}.tmp" "$CLAUDE_CONFIG_FILE"
    else
      # Invalid JSON - create new
      cat > "$CLAUDE_CONFIG_FILE" << 'EOF'
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
    fi
  else
    echo -e "${YELLOW}Warning: jq not found. Creating new configuration.${NC}"
    echo "Install jq for JSON merging: brew install jq (macOS) or apt-get install jq (Linux)"
    cat > "$CLAUDE_CONFIG_FILE" << 'EOF'
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
  fi
else
  # Create new config
  cat > "$CLAUDE_CONFIG_FILE" << 'EOF'
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
fi

echo -e "${GREEN}✓ Claude Desktop MCP configuration created${NC}"
echo ""
echo "Configuration file: ${CLAUDE_CONFIG_FILE}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Restart Claude Desktop to load the configuration"
echo "  2. Verify setup: ./scripts/mcp/verify.sh"
echo ""

