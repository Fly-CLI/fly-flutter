#!/usr/bin/env bash

# Create a new Flutter project using Fly CLI
# Wrapper for fly create command

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
      echo "Usage: $0 PROJECT_NAME [OPTIONS]"
      echo ""
      echo "Create a new Flutter project using Fly CLI."
      echo ""
      echo "Arguments:"
      echo "  PROJECT_NAME    Name of the project to create (required)"
      echo ""
      echo "Options:"
      echo "  All options from 'fly create' command are supported"
      echo "  Common options:"
      echo "    --template=TEMPLATE       Project template (default: riverpod)"
      echo "    --organization=ORG       Organization identifier"
      echo "    --platforms=PLATFORMS    Target platforms (comma-separated)"
      echo "    --output=json            JSON output for AI integration"
      echo "    --interactive            Interactive mode"
      echo "  -h, --help                 Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0 my_app"
      echo "  $0 my_app --template=riverpod"
      echo "  $0 my_app --template=riverpod --output=json"
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

# Check for project name
if [ $# -eq 0 ]; then
  echo -e "${RED}Error: PROJECT_NAME is required${NC}"
  echo ""
  echo "Usage: $0 PROJECT_NAME [OPTIONS]"
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
  echo "  dart pub global run fly_cli:fly create \"$@\""
  exit 1
fi

# Run fly create with all arguments
fly create "$@"

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ Project created successfully${NC}"
  exit 0
else
  echo ""
  echo -e "${RED}✗ Project creation failed${NC}"
  exit $EXIT_CODE
fi

