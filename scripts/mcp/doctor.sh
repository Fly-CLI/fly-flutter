#!/usr/bin/env bash

# Run MCP diagnostics
# Wrapper for fly mcp doctor command

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
ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Run MCP diagnostics to check server configuration."
      echo ""
      echo "Options:"
      echo "  --output=FORMAT    Output format (human, json)"
      echo "  -h, --help         Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0"
      echo "  $0 --output=json"
      exit 0
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

# Check if fly command is available
if ! command -v fly &> /dev/null; then
  echo -e "${RED}Error: fly command not found${NC}"
  echo ""
  echo "Install Fly CLI:"
  echo "  ./scripts/setup/install.sh"
  echo ""
  echo "Or run directly:"
  echo "  dart pub global run fly_cli:fly mcp doctor ${ARGS[*]}"
  exit 1
fi

# Run fly mcp doctor
fly mcp doctor "${ARGS[@]}"

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ MCP diagnostics passed${NC}"
  exit 0
else
  echo ""
  echo -e "${RED}✗ MCP diagnostics failed${NC}"
  exit $EXIT_CODE
fi

