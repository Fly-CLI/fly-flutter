#!/usr/bin/env bash

# Validate MCP tools, prompts, and resources
# Checks schemas, template files, and strategy implementations

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
FILTER_TYPE=""
OUTPUT_FORMAT="table"
STRICT=false
VERBOSE=false

# Parse arguments
ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --type=*)
      FILTER_TYPE="${1#*=}"
      shift
      ;;
    --format=*)
      OUTPUT_FORMAT="${1#*=}"
      shift
      ;;
    --strict)
      STRICT=true
      ARGS+=("--strict")
      shift
      ;;
    -v|--verbose)
      VERBOSE=true
      ARGS+=("--verbose")
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Validate and verify MCP tools, prompts, and resources."
      echo ""
      echo "Options:"
      echo "  --type=TYPE         Filter by type (tools, prompts, resources)"
      echo "                      Default: validate all types"
      echo "  --format=FORMAT     Output format (table, json)"
      echo "                      Default: table"
      echo "  --strict            Exit with error code on validation failures"
      echo "                      Default: exit with error code if errors found"
      echo "  -v, --verbose       Show verbose output"
      echo "  -h, --help         Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0"
      echo "  $0 --type=tools"
      echo "  $0 --type=prompts --format=json"
      echo "  $0 --strict"
      exit 0
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

# Change to project root
cd "${PROJECT_ROOT}"

# Validate filter type
if [ -n "$FILTER_TYPE" ] && [[ ! "$FILTER_TYPE" =~ ^(tools|prompts|resources)$ ]]; then
  echo -e "${RED}Error: Invalid type '${FILTER_TYPE}'${NC}"
  echo "Valid types: tools, prompts, resources"
  exit 1
fi

# Validate output format
if [[ ! "$OUTPUT_FORMAT" =~ ^(table|json)$ ]]; then
  echo -e "${RED}Error: Invalid format '${OUTPUT_FORMAT}'${NC}"
  echo "Valid formats: table, json"
  exit 1
fi

# Build arguments for Dart script
DART_ARGS=()
if [ -n "$FILTER_TYPE" ]; then
  DART_ARGS+=("--type=${FILTER_TYPE}")
fi
if [ "$OUTPUT_FORMAT" != "table" ]; then
  DART_ARGS+=("--format=${OUTPUT_FORMAT}")
fi
if [ "$STRICT" = true ]; then
  DART_ARGS+=("--strict")
fi
if [ "$VERBOSE" = true ]; then
  DART_ARGS+=("--verbose")
fi

# Run Dart validation script
if ! dart run tool/ci/mcp_validate.dart "${DART_ARGS[@]}"; then
  echo ""
  echo -e "${RED}✗ MCP validation failed${NC}"
  exit 1
fi

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ MCP validation passed${NC}"
  exit 0
else
  echo ""
  echo -e "${RED}✗ MCP validation failed${NC}"
  exit $EXIT_CODE
fi

