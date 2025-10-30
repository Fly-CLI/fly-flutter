#!/usr/bin/env bash

# Add a new screen to a project
# Wrapper for fly add screen command

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
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: $0 SCREEN_NAME [OPTIONS]"
      echo ""
      echo "Add a new screen to a Flutter project using Fly CLI."
      echo ""
      echo "Arguments:"
      echo "  SCREEN_NAME      Name of the screen to add (required)"
      echo ""
      echo "Options:"
      echo "  --feature=FEATURE           Feature module name (required)"
      echo "  --type=TYPE                 Screen type (generic, list, detail, form, settings)"
      echo "  --with-viewmodel            Include viewmodel"
      echo "  --with-tests                Include tests"
      echo "  --output=json               JSON output for AI integration"
      echo "  -h, --help                  Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0 home --feature=auth"
      echo "  $0 profile --feature=user --with-viewmodel"
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

# Check for screen name
if [ $# -eq 0 ]; then
  echo -e "${RED}Error: SCREEN_NAME is required${NC}"
  echo ""
  echo "Usage: $0 SCREEN_NAME [OPTIONS]"
  echo "Use -h or --help for more information"
  exit 1
fi

# Check if fly command is available
if ! command -v fly &> /dev/null; then
  echo -e "${RED}Error: fly command not found${NC}"
  echo ""
  echo "Install Fly CLI:"
  echo "  ./scripts/setup/install.sh"
  echo ""
  echo "Or run directly:"
  echo "  dart pub global run fly_cli:fly add screen \"$@\""
  exit 1
fi

# Run fly add screen with all arguments
fly add screen "$@"

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ Screen added successfully${NC}"
  exit 0
else
  echo ""
  echo -e "${RED}✗ Failed to add screen${NC}"
  exit $EXIT_CODE
fi

