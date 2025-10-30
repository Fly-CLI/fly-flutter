#!/usr/bin/env bash

# List MCP tools, prompts, and resources
# Discovers and lists all registered MCP components

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
VERBOSE=false
SHOW_PARSED=false
PARSE_ONLY=false

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
    --show-parsed)
      SHOW_PARSED=true
      ARGS+=("--show-parsed")
      shift
      ;;
    --parse-only)
      PARSE_ONLY=true
      ARGS+=("--parse-only")
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
      echo "List and discover MCP tools, prompts, and resources."
      echo ""
      echo "Options:"
      echo "  --type=TYPE         Filter by type (tools, prompts, resources)"
      echo "                      Default: list all types"
      echo "  --format=FORMAT     Output format (table, json, yaml)"
      echo "                      Default: table"
      echo "  --show-parsed       When listing prompts, show parsed YAML metadata"
      echo "                      and template content"
      echo "  --parse-only        Only show parsed template information (for testing)"
      echo "                      Only works with --type=prompts"
      echo "  -v, --verbose       Show verbose output (file paths, etc.)"
      echo "  -h, --help          Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0"
      echo "  $0 --type=tools"
      echo "  $0 --type=prompts --format=json"
      echo "  $0 --type=prompts --show-parsed"
      echo "  $0 --type=prompts --parse-only"
      echo "  $0 --format=yaml --verbose"
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
if [[ ! "$OUTPUT_FORMAT" =~ ^(table|json|yaml)$ ]]; then
  echo -e "${RED}Error: Invalid format '${OUTPUT_FORMAT}'${NC}"
  echo "Valid formats: table, json, yaml"
  exit 1
fi

# Validate parse-only usage
if [ "$PARSE_ONLY" = true ] && [ "$FILTER_TYPE" != "prompts" ]; then
  echo -e "${YELLOW}Warning: --parse-only only works with --type=prompts${NC}"
  echo "Setting --type=prompts automatically"
  FILTER_TYPE="prompts"
fi

# Build arguments for Dart script
DART_ARGS=()
if [ -n "$FILTER_TYPE" ]; then
  DART_ARGS+=("--type=${FILTER_TYPE}")
fi
if [ "$OUTPUT_FORMAT" != "table" ]; then
  DART_ARGS+=("--format=${OUTPUT_FORMAT}")
fi
if [ "$SHOW_PARSED" = true ]; then
  DART_ARGS+=("--show-parsed")
fi
if [ "$PARSE_ONLY" = true ]; then
  DART_ARGS+=("--parse-only")
fi
if [ "$VERBOSE" = true ]; then
  DART_ARGS+=("--verbose")
fi

# Run Dart script
if ! dart run tool/ci/mcp_list.dart "${DART_ARGS[@]}"; then
  echo ""
  echo -e "${RED}Error: Failed to list MCP components${NC}"
  exit 1
fi

