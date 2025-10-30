#!/usr/bin/env bash

# Manage test project for Fly CLI testing
# This script helps manage the test project used for validating CLI features

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

# Default values
TEST_PROJECT_DIR="${PROJECT_ROOT}/examples/test_project"
ACTION="help"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    reset|recreate)
      ACTION="reset"
      shift
      ;;
    status|info)
      ACTION="status"
      shift
      ;;
    validate|check)
      ACTION="validate"
      shift
      ;;
    -h|--help)
      ACTION="help"
      shift
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

# Functions
show_help() {
  echo "Usage: $0 [COMMAND]"
  echo ""
  echo "Manage test project for Fly CLI testing"
  echo ""
  echo "Commands:"
  echo "  reset, recreate    Delete and recreate test project"
  echo "  status, info       Show test project status"
  echo "  validate, check    Validate test project structure"
  echo "  -h, --help         Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 reset           # Reset test project"
  echo "  $0 status          # Show project status"
  echo "  $0 validate        # Validate project structure"
}

reset_project() {
  echo -e "${BLUE}Resetting test project...${NC}"
  echo ""
  
  # Check if test project exists
  if [ -d "$TEST_PROJECT_DIR" ]; then
    echo -e "${YELLOW}Deleting existing test project...${NC}"
    rm -rf "$TEST_PROJECT_DIR"
  fi
  
  echo -e "${GREEN}Creating new test project...${NC}"
  cd "${PROJECT_ROOT}/examples"
  
  # Create project using Fly CLI
  if command -v fly &> /dev/null; then
    fly create test_project --template=riverpod
    echo ""
    echo -e "${GREEN}✓ Test project created${NC}"
  else
    echo -e "${RED}Error: fly command not found${NC}"
    echo "Install Fly CLI: ./scripts/setup/install.sh"
    exit 1
  fi
}

show_status() {
  echo -e "${BLUE}Test Project Status${NC}"
  echo ""
  
  if [ ! -d "$TEST_PROJECT_DIR" ]; then
    echo -e "${YELLOW}Test project does not exist${NC}"
    echo ""
    echo "Create it with: $0 reset"
    exit 0
  fi
  
  echo "Location: ${TEST_PROJECT_DIR}"
  echo ""
  
  # Check if it's a valid Flutter project
  if [ -f "${TEST_PROJECT_DIR}/pubspec.yaml" ]; then
    echo -e "${GREEN}✓ Valid Flutter project${NC}"
  else
    echo -e "${RED}✗ Not a valid Flutter project (missing pubspec.yaml)${NC}"
  fi
  
  # Check structure
  echo ""
  echo "Project Structure:"
  if [ -d "${TEST_PROJECT_DIR}/lib" ]; then
    echo "  ✓ lib/ directory exists"
    if [ -d "${TEST_PROJECT_DIR}/lib/features" ]; then
      echo "    ✓ features/ directory exists"
    fi
    if [ -d "${TEST_PROJECT_DIR}/lib/core" ]; then
      echo "    ✓ core/ directory exists"
    fi
  else
    echo "  ✗ lib/ directory missing"
  fi
  
  if [ -d "${TEST_PROJECT_DIR}/test" ]; then
    echo "  ✓ test/ directory exists"
  else
    echo "  ✗ test/ directory missing"
  fi
  
  echo ""
  echo "Usage:"
  echo "  Use AI assistants via MCP to test CLI features on this project"
  echo "  See docs/testing/ai-testing-guide.md for details"
}

validate_project() {
  echo -e "${BLUE}Validating test project...${NC}"
  echo ""
  
  if [ ! -d "$TEST_PROJECT_DIR" ]; then
    echo -e "${RED}✗ Test project does not exist${NC}"
    echo ""
    echo "Create it with: $0 reset"
    exit 1
  fi
  
  local errors=0
  
  # Check required files
  if [ ! -f "${TEST_PROJECT_DIR}/pubspec.yaml" ]; then
    echo -e "${RED}✗ Missing pubspec.yaml${NC}"
    errors=$((errors + 1))
  else
    echo -e "${GREEN}✓ pubspec.yaml exists${NC}"
  fi
  
  if [ ! -f "${TEST_PROJECT_DIR}/lib/main.dart" ]; then
    echo -e "${RED}✗ Missing lib/main.dart${NC}"
    errors=$((errors + 1))
  else
    echo -e "${GREEN}✓ lib/main.dart exists${NC}"
  fi
  
  # Check structure
  if [ ! -d "${TEST_PROJECT_DIR}/lib" ]; then
    echo -e "${RED}✗ Missing lib/ directory${NC}"
    errors=$((errors + 1))
  else
    echo -e "${GREEN}✓ lib/ directory exists${NC}"
  fi
  
  if [ ! -d "${TEST_PROJECT_DIR}/test" ]; then
    echo -e "${YELLOW}⚠ Missing test/ directory${NC}"
  else
    echo -e "${GREEN}✓ test/ directory exists${NC}"
  fi
  
  # Check if it compiles
  if command -v flutter &> /dev/null; then
    cd "$TEST_PROJECT_DIR"
    if flutter pub get > /dev/null 2>&1; then
      echo -e "${GREEN}✓ Dependencies can be fetched${NC}"
    else
      echo -e "${RED}✗ Failed to fetch dependencies${NC}"
      errors=$((errors + 1))
    fi
  fi
  
  echo ""
  if [ $errors -eq 0 ]; then
    echo -e "${GREEN}✓ Test project validation passed${NC}"
    exit 0
  else
    echo -e "${RED}✗ Test project validation failed (${errors} errors)${NC}"
    exit 1
  fi
}

# Execute action
case $ACTION in
  help)
    show_help
    ;;
  reset)
    reset_project
    ;;
  status)
    show_status
    ;;
  validate)
    validate_project
    ;;
  *)
    show_help
    exit 1
    ;;
esac

