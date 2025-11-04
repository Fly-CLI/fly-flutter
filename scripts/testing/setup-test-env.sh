#!/usr/bin/env bash

# Setup test environment for manual CLI testing
# Creates isolated test directories and sets up environment variables

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Default test workspace
TEST_WORKSPACE="${HOME}/fly_test_workspace"

# Parse arguments
VERBOSE=false
CLEAN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -w|--workspace)
      TEST_WORKSPACE="$2"
      shift 2
      ;;
    -c|--clean)
      CLEAN=true
      shift
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Setup test environment for manual CLI testing."
      echo ""
      echo "Options:"
      echo "  -w, --workspace DIR   Test workspace directory (default: ~/fly_test_workspace)"
      echo "  -c, --clean           Clean existing test workspace"
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

echo -e "${BLUE}Setting up test environment...${NC}"
echo ""

# Clean workspace if requested
if [ "$CLEAN" = true ] && [ -d "$TEST_WORKSPACE" ]; then
  echo -e "${YELLOW}Cleaning existing test workspace...${NC}"
  rm -rf "$TEST_WORKSPACE"
fi

# Create test workspace
mkdir -p "$TEST_WORKSPACE"
cd "$TEST_WORKSPACE"

echo -e "${GREEN}Test workspace: ${TEST_WORKSPACE}${NC}"

# Create test directories
echo "Creating test directories..."
mkdir -p projects
mkdir -p screens
mkdir -p services
mkdir -p results
mkdir -p artifacts

# Create environment setup file
cat > .env.test <<EOF
# Fly CLI Test Environment Variables
export FLY_TEST_WORKSPACE="${TEST_WORKSPACE}"
export FLY_OUTPUT_DIR="${TEST_WORKSPACE}/artifacts"
export FLY_VERBOSE=true
export FLY_TEST_MODE=true
EOF

# Create test results directory with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="${TEST_WORKSPACE}/results/${TIMESTAMP}"
mkdir -p "$RESULTS_DIR"

echo -e "${GREEN}Test results directory: ${RESULTS_DIR}${NC}"

# Verify CLI installation
echo ""
echo "Verifying CLI installation..."

if ! command -v fly &> /dev/null; then
  echo -e "${YELLOW}Warning: 'fly' command not found in PATH${NC}"
  echo ""
  echo "Install CLI:"
  echo "  cd ${PROJECT_ROOT}"
  echo "  ./scripts/setup/install.sh"
  echo ""
  echo "Or run directly:"
  echo "  dart run ${PROJECT_ROOT}/packages/fly_cli/bin/fly.dart"
else
  VERSION=$(fly --version 2>/dev/null | head -n 1 || echo "unknown")
  echo -e "${GREEN}✓ CLI found: ${VERSION}${NC}"
fi

# Verify Flutter SDK
echo ""
echo "Verifying Flutter SDK..."
if command -v flutter &> /dev/null; then
  FLUTTER_VERSION=$(flutter --version | head -n 1)
  echo -e "${GREEN}✓ Flutter found: ${FLUTTER_VERSION}${NC}"
else
  echo -e "${RED}✗ Flutter not found${NC}"
  echo "Install Flutter: https://docs.flutter.dev/get-started/install"
fi

# Create summary
cat > "${RESULTS_DIR}/setup_summary.txt" <<EOF
Test Environment Setup Summary
==============================
Date: $(date)
Test Workspace: ${TEST_WORKSPACE}
Results Directory: ${RESULTS_DIR}
CLI Version: ${VERSION:-"not found"}
Flutter Version: ${FLUTTER_VERSION:-"not found"}

Test Directories:
- Projects: ${TEST_WORKSPACE}/projects
- Screens: ${TEST_WORKSPACE}/screens
- Services: ${TEST_WORKSPACE}/services
- Results: ${TEST_WORKSPACE}/results
- Artifacts: ${TEST_WORKSPACE}/artifacts

Environment Variables:
- FLY_TEST_WORKSPACE: ${TEST_WORKSPACE}
- FLY_OUTPUT_DIR: ${TEST_WORKSPACE}/artifacts
- FLY_VERBOSE: true
EOF

echo ""
echo -e "${GREEN}✓ Test environment setup complete${NC}"
echo ""
echo "Next steps:"
echo "  1. Source environment: source ${TEST_WORKSPACE}/.env.test"
echo "  2. Run test scripts: cd ${PROJECT_ROOT}/scripts/testing"
echo "  3. Start testing: ./run-test-suite.sh"

