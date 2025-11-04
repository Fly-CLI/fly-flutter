#!/usr/bin/env bash

# Clean test environment
# Removes test artifacts and optionally the entire test workspace

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default test workspace
TEST_WORKSPACE="${HOME}/fly_test_workspace"

# Parse arguments
FULL_CLEAN=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -w|--workspace)
      TEST_WORKSPACE="$2"
      shift 2
      ;;
    -f|--full)
      FULL_CLEAN=true
      shift
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Clean test environment and artifacts."
      echo ""
      echo "Options:"
      echo "  -w, --workspace DIR   Test workspace directory (default: ~/fly_test_workspace)"
      echo "  -f, --full            Remove entire test workspace"
      echo "  -v, --verbose         Enable verbose output"
      echo "  -h, --help            Show this help message"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Use -h or --help for usage information"
      exit 1
      ;;
  esac
done

echo -e "${YELLOW}Cleaning test environment...${NC}"
echo ""

if [ ! -d "$TEST_WORKSPACE" ]; then
  echo -e "${GREEN}✓ Test workspace does not exist: ${TEST_WORKSPACE}${NC}"
  exit 0
fi

if [ "$FULL_CLEAN" = true ]; then
  echo -e "${YELLOW}Removing entire test workspace...${NC}"
  rm -rf "$TEST_WORKSPACE"
  echo -e "${GREEN}✓ Test workspace removed${NC}"
else
  # Clean artifacts only
  echo "Cleaning test artifacts..."
  
  if [ -d "${TEST_WORKSPACE}/projects" ]; then
    rm -rf "${TEST_WORKSPACE}/projects"/*
    echo "  - Cleaned projects directory"
  fi
  
  if [ -d "${TEST_WORKSPACE}/screens" ]; then
    rm -rf "${TEST_WORKSPACE}/screens"/*
    echo "  - Cleaned screens directory"
  fi
  
  if [ -d "${TEST_WORKSPACE}/services" ]; then
    rm -rf "${TEST_WORKSPACE}/services"/*
    echo "  - Cleaned services directory"
  fi
  
  if [ -d "${TEST_WORKSPACE}/artifacts" ]; then
    rm -rf "${TEST_WORKSPACE}/artifacts"/*
    echo "  - Cleaned artifacts directory"
  fi
  
  echo -e "${GREEN}✓ Test artifacts cleaned${NC}"
  echo ""
  echo "Note: Test results are preserved in ${TEST_WORKSPACE}/results"
  echo "Use --full to remove entire workspace including results"
fi

