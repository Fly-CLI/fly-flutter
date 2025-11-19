#!/usr/bin/env bash

# Compile Fly CLI to native binary for optimal performance
# This script compiles the Dart CLI to a native executable, eliminating
# JIT compilation overhead and providing 20-30x faster startup times.

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
FLY_CLI_DIR="${PROJECT_ROOT}/packages/fly_cli"
BIN_DIR="${FLY_CLI_DIR}/bin"
BINARY_PATH="${BIN_DIR}/fly"
BINARY_PATH_WIN="${BIN_DIR}/fly.exe"

# Verbose flag
VERBOSE=false
FORCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -f|--force)
      FORCE=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Compile Fly CLI to native binary for optimal performance."
      echo ""
      echo "The compiled binary provides:"
      echo "  - 20-30x faster startup (0.6s vs 20-26s)"
      echo "  - No JIT compilation overhead"
      echo "  - Better performance for CI/CD and integration tests"
      echo ""
      echo "Options:"
      echo "  -v, --verbose    Enable verbose output"
      echo "  -f, --force      Force recompilation even if binary exists"
      echo "  -h, --help       Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0                # Compile if binary doesn't exist"
      echo "  $0 --force        # Force recompilation"
      echo "  $0 --verbose      # Show detailed compilation output"
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

# Check if Dart is installed
if ! command -v dart &> /dev/null; then
  echo -e "${RED}Error: Dart is not installed${NC}"
  echo ""
  echo "Install Dart SDK from: https://dart.dev/get-dart"
  exit 1
fi

# Check if source file exists
if [ ! -f "${FLY_CLI_DIR}/bin/fly.dart" ]; then
  echo -e "${RED}Error: Source file not found: ${FLY_CLI_DIR}/bin/fly.dart${NC}"
  exit 1
fi

# Check if binary already exists
if [[ -f "${BINARY_PATH}" ]] || [[ -f "${BINARY_PATH_WIN}" ]]; then
  if [ "$FORCE" = false ]; then
    echo -e "${YELLOW}Binary already exists at: ${BINARY_PATH}${NC}"
    echo ""
    echo "Use --force to recompile, or delete the binary manually:"
    echo "  rm ${BINARY_PATH}"
    echo ""
    echo "For development, you can use 'dart run' instead:"
    echo "  dart run ${FLY_CLI_DIR}/bin/fly.dart <command>"
    exit 0
  else
    echo -e "${YELLOW}Force recompilation requested${NC}"
    # Remove existing binary
    [[ -f "${BINARY_PATH}" ]] && rm -f "${BINARY_PATH}"
    [[ -f "${BINARY_PATH_WIN}" ]] && rm -f "${BINARY_PATH_WIN}"
  fi
fi

echo -e "${BLUE}Compiling Fly CLI to native binary...${NC}"
echo ""
echo -e "  Source: ${FLY_CLI_DIR}/bin/fly.dart"
echo -e "  Output: ${BINARY_PATH}"
echo ""

# Change to fly_cli directory
cd "${FLY_CLI_DIR}"

# Compile the binary
if [ "$VERBOSE" = true ]; then
  dart compile exe bin/fly.dart -o bin/fly --verbose
else
  dart compile exe bin/fly.dart -o bin/fly
fi

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  # Make binary executable (Unix)
  if [ -f "${BINARY_PATH}" ]; then
    chmod +x "${BINARY_PATH}"
    
    # Get binary size
    BINARY_SIZE=$(du -h "${BINARY_PATH}" | cut -f1)
    
    echo ""
    echo -e "${GREEN}✓ CLI compiled successfully${NC}"
    echo ""
    echo -e "  Binary: ${BINARY_PATH}"
    echo -e "  Size: ${BINARY_SIZE}"
    echo ""
    echo -e "${GREEN}Performance improvements:${NC}"
    echo "  - Startup time: ~0.6s (vs 20-26s with dart run)"
    echo "  - Integration tests: ~21s (vs 336s with dart run)"
    echo ""
    echo -e "${BLUE}Usage:${NC}"
    echo "  ${BINARY_PATH} --version"
    echo "  ${BINARY_PATH} generate project <name>"
    echo ""
    echo -e "${YELLOW}Note:${NC} The binary is git-ignored. Recompile after code changes."
  fi
  exit 0
else
  echo ""
  echo -e "${RED}✗ Compilation failed${NC}"
  exit $EXIT_CODE
fi

