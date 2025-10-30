#!/usr/bin/env bash

# Display help and usage information
# Shows available scripts and usage

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

# Category to show
CATEGORY=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: $0 [CATEGORY]"
      echo ""
      echo "Display help and usage information for scripts."
      echo ""
      echo "Arguments:"
      echo "  CATEGORY         (optional) Category to show help for"
      echo "                   Options: setup, development, cli, build, ci, tools"
      echo ""
      echo "Examples:"
      echo "  $0"
      echo "  $0 development"
      echo "  $0 cli"
      exit 0
      ;;
    setup|development|cli|mcp|build|ci|tools)
      CATEGORY="$1"
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Use -h or --help for usage information"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Fly CLI Development Scripts${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ -z "$CATEGORY" ]; then
  # Show all categories
  echo -e "${GREEN}Available Script Categories:${NC}"
  echo ""
  echo "  ${YELLOW}setup${NC}         - Initial setup and installation"
  echo "  ${YELLOW}development${NC}   - Development workflow (test, format, analyze)"
  echo "  ${YELLOW}cli${NC}            - Wrappers for Fly CLI commands"
  echo "  ${YELLOW}mcp${NC}            - MCP server and integration scripts"
  echo "  ${YELLOW}build${NC}          - Build scripts for examples and packages"
  echo "  ${YELLOW}ci${NC}             - CI/CD tests and checks"
  echo "  ${YELLOW}tools${NC}          - Utility scripts"
  echo ""
  echo "For detailed help on a category:"
  echo "  $0 [CATEGORY]"
  echo ""
  echo "For detailed documentation:"
  echo "  See scripts/README.md"
  exit 0
fi

# Show specific category
case "$CATEGORY" in
  setup)
    echo -e "${GREEN}Setup Scripts:${NC}"
    echo ""
    echo "  ./scripts/setup/bootstrap.sh       - Bootstrap monorepo with melos"
    echo "  ./scripts/setup/install.sh          - Install CLI locally for development"
    echo "  ./scripts/setup/verify.sh           - Verify installation"
    echo ""
    echo "For help on a specific script:"
    echo "  ./scripts/setup/bootstrap.sh --help"
    ;;
  development)
    echo -e "${GREEN}Development Scripts:${NC}"
    echo ""
    echo "  ./scripts/development/analyze.sh          - Run analysis on all packages"
    echo "  ./scripts/development/format.sh          - Format code"
    echo "  ./scripts/development/format-check.sh   - Check formatting"
    echo "  ./scripts/development/test.sh             - Run all tests with coverage"
    echo "  ./scripts/development/test-changed.sh   - Test only changed packages"
    echo "  ./scripts/development/test-unit.sh        - Run unit tests"
    echo "  ./scripts/development/test-integration.sh - Run integration tests"
    echo "  ./scripts/development/test-e2e.sh         - Run E2E tests"
    echo "  ./scripts/development/build-runner.sh     - Run code generation"
    echo "  ./scripts/development/clean.sh            - Clean all packages"
    echo "  ./scripts/development/get.sh               - Get dependencies"
    echo "  ./scripts/development/outdated.sh         - Check outdated dependencies"
    echo ""
    echo "For help on a specific script:"
    echo "  ./scripts/development/test.sh --help"
    ;;
  cli)
    echo -e "${GREEN}CLI Command Wrappers:${NC}"
    echo ""
    echo "  ./scripts/cli/create.sh          - Create new project"
    echo "  ./scripts/cli/doctor.sh          - System diagnostics"
    echo "  ./scripts/cli/version.sh         - Show version information"
    echo "  ./scripts/cli/schema-export.sh   - Export CLI schema"
    echo "  ./scripts/cli/context-export.sh  - Export project context"
    echo "  ./scripts/cli/completion.sh      - Generate shell completion"
    echo "  ./scripts/cli/add-screen.sh      - Add screen"
    echo "  ./scripts/cli/add-service.sh     - Add service"
    echo "  ./scripts/cli/mcp-doctor.sh      - MCP diagnostics"
    echo ""
    echo "For help on a specific script:"
    echo "  ./scripts/cli/create.sh --help"
    ;;
  mcp)
    echo -e "${GREEN}MCP Scripts:${NC}"
    echo ""
    echo "  ./scripts/mcp/serve.sh           - Start MCP server"
    echo "  ./scripts/mcp/doctor.sh          - Run MCP diagnostics"
    echo "  ./scripts/mcp/test.sh            - Run MCP conformance tests"
    echo "  ./scripts/mcp/conformance.sh     - Run MCP conformance tests directly"
    echo "  ./scripts/mcp/setup.sh            - Interactive MCP setup"
    echo "  ./scripts/mcp/setup-cursor.sh     - Setup Cursor integration"
    echo "  ./scripts/mcp/setup-claude.sh     - Setup Claude Desktop integration"
    echo "  ./scripts/mcp/verify.sh           - Verify MCP setup"
    echo ""
    echo "For help on a specific script:"
    echo "  ./scripts/mcp/serve.sh --help"
    ;;
  build)
    echo -e "${GREEN}Build Scripts:${NC}"
    echo ""
    echo "  ./scripts/build/examples.sh      - Build all example apps"
    echo "  ./scripts/build/package.sh       - Build specific package"
    echo ""
    echo "For help on a specific script:"
    echo "  ./scripts/build/examples.sh --help"
    ;;
  ci)
    echo -e "${GREEN}CI Scripts:${NC}"
    echo ""
    echo "  ./scripts/ci/test-all.sh          - Run all CI tests"
    echo "  ./scripts/mcp/conformance.sh    - MCP conformance tests"
    echo "  ./scripts/ci/license-check.sh      - License compatibility check"
    echo "  ./scripts/ci/security-scan.sh     - Security validation"
    echo ""
    echo "For help on a specific script:"
    echo "  ./scripts/ci/test-all.sh --help"
    ;;
  tools)
    echo -e "${GREEN}Tools Scripts:${NC}"
    echo ""
    echo "  ./scripts/tools/version-bump.sh    - Bump version"
    echo "  ./scripts/tools/coverage-report.sh  - Generate coverage report"
    echo "  ./scripts/tools/help.sh             - Display help (this script)"
    echo ""
    echo "For help on a specific script:"
    echo "  ./scripts/tools/version-bump.sh --help"
    ;;
  *)
    echo -e "${RED}Unknown category: $CATEGORY${NC}"
    exit 1
    ;;
esac

echo ""
echo "For comprehensive documentation:"
echo "  See scripts/README.md"

