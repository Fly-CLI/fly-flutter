#!/usr/bin/env bash

# Start the MCP server
# Wrapper for fly mcp serve command

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
      echo "Start the MCP server for Cursor/Claude integration."
      echo ""
      echo "Options:"
      echo "  --stdio                      Use stdio transport (required for Cursor/Claude)"
      echo "  --max-message-mb=SIZE         Maximum message size in MB (default: 2)"
      echo "  --default-timeout-seconds=TIMEOUT  Default tool timeout in seconds (default: 300)"
      echo "  --max-concurrency=N          Maximum concurrent tool executions (default: 10)"
      echo "  -h, --help                   Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0 --stdio"
      echo "  $0 --stdio --default-timeout-seconds=600"
      echo "  $0 --stdio --default-timeout-seconds=600 --max-concurrency=5"
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
  echo "  dart pub global run fly_cli:fly mcp serve ${ARGS[*]}"
  exit 1
fi

# Run fly mcp serve
echo -e "${GREEN}Starting MCP server...${NC}"
echo ""
fly mcp serve "${ARGS[@]}"

EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  echo ""
  echo -e "${RED}✗ MCP server failed${NC}"
  exit $EXIT_CODE
fi

