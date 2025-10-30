#!/usr/bin/env bash

# Generate shell completion for Fly CLI
# Wrapper for fly completion command

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
      echo "Usage: $0 [SHELL] [OPTIONS]"
      echo ""
      echo "Generate shell completion for Fly CLI."
      echo ""
      echo "Arguments:"
      echo "  SHELL              Shell type (bash, zsh, fish, powershell)"
      echo ""
      echo "Options:"
      echo "  --output=FILE      Output to file instead of stdout"
      echo "  -h, --help         Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0 bash"
      echo "  $0 zsh"
      echo "  $0 bash --output=/path/to/completion"
      echo ""
      echo "To install completion:"
      echo "  bash: $0 bash > /etc/bash_completion.d/fly"
      echo "  zsh:  $0 zsh > ~/.zsh/completion/_fly"
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
  echo "  dart pub global run fly_cli:fly completion ${ARGS[*]}"
  exit 1
fi

# Run fly completion
fly completion "${ARGS[@]}"

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  exit 0
else
  echo ""
  echo -e "${RED}✗ Failed to generate completion${NC}"
  exit $EXIT_CODE
fi

