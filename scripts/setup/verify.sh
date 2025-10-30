#!/usr/bin/env bash

# Verify Fly CLI installation
# Runs fly doctor to check system configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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
      echo "Verify Fly CLI installation by running diagnostics."
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

echo -e "${GREEN}Verifying Fly CLI installation...${NC}"
echo ""

# Check if fly command is available
if ! command -v fly &> /dev/null; then
  echo -e "${YELLOW}Warning: 'fly' command not found in PATH${NC}"
  echo ""
  echo "Try running fly directly:"
  echo "  dart pub global run fly_cli:fly doctor"
  echo ""
  echo "Or add to PATH:"
  echo "  export PATH=\"\$PATH:\$HOME/.pub-cache/bin\""
  echo ""
  
  # Try running directly
  echo "Attempting to run fly doctor directly..."
  if dart pub global run fly_cli:fly doctor; then
    echo ""
    echo -e "${GREEN}✓ CLI is working${NC}"
    exit 0
  else
    echo ""
    echo -e "${RED}✗ CLI verification failed${NC}"
    echo ""
    echo "Make sure CLI is installed:"
    echo "  ./scripts/setup/install.sh"
    exit 1
  fi
fi

# Run fly doctor
if [ "$VERBOSE" = true ]; then
  fly doctor --verbose
else
  fly doctor
fi

# Check exit code
if [ $? -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ Installation verified${NC}"
  exit 0
else
  echo ""
  echo -e "${RED}✗ Verification failed${NC}"
  echo ""
  echo "Try running with --fix:"
  echo "  fly doctor --fix"
  exit 1
fi

