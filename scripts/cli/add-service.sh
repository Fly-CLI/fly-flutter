#!/usr/bin/env bash

# Add a new service to a project
# Wrapper for fly add service command

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
      echo "Usage: $0 SERVICE_NAME [OPTIONS]"
      echo ""
      echo "Add a new service to a Flutter project using Fly CLI."
      echo ""
      echo "Arguments:"
      echo "  SERVICE_NAME     Name of the service to add (required)"
      echo ""
      echo "Options:"
      echo "  --feature=FEATURE           Feature module name (required)"
      echo "  --type=TYPE                 Service type (api, repository, storage, analytics)"
      echo "  --base-url=URL              Base URL for API services"
      echo "  --with-tests                Include tests"
      echo "  --with-mocks                Include mocks"
      echo "  --output=json               JSON output for AI integration"
      echo "  -h, --help                  Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0 api --feature=core --type=api"
      echo "  $0 database --feature=core --type=database"
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

# Check for service name
if [ $# -eq 0 ]; then
  echo -e "${RED}Error: SERVICE_NAME is required${NC}"
  echo ""
  echo "Usage: $0 SERVICE_NAME [OPTIONS]"
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
  echo "  dart pub global run fly_cli:fly add service \"$@\""
  exit 1
fi

# Run fly add service with all arguments
fly add service "$@"

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ Service added successfully${NC}"
  exit 0
else
  echo ""
  echo -e "${RED}✗ Failed to add service${NC}"
  exit $EXIT_CODE
fi

