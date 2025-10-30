#!/usr/bin/env bash

# Generate coverage report
# Collects coverage from all test runs and generates HTML report

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
OPEN_BROWSER=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    --open)
      OPEN_BROWSER=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Generate coverage report from test runs."
      echo ""
      echo "Options:"
      echo "  --open            Open coverage report in browser"
      echo "  -v, --verbose     Enable verbose output"
      echo "  -h, --help         Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0"
      echo "  $0 --open"
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

# Check if lcov is installed (for genhtml)
if ! command -v genhtml &> /dev/null; then
  echo -e "${YELLOW}Warning: genhtml not found. Install lcov to generate HTML reports.${NC}"
  echo ""
  echo "On macOS:"
  echo "  brew install lcov"
  echo ""
  echo "On Linux:"
  echo "  sudo apt-get install lcov"
  echo ""
  echo "Falling back to collecting coverage data only..."
  echo ""
  
  # Just collect coverage without HTML generation
  echo "Collecting coverage data..."
  
  # Find all lcov.info files
  COVERAGE_FILES=$(find . -name "lcov.info" -type f | grep -v node_modules | grep -v ".dart_tool")
  
  if [ -z "$COVERAGE_FILES" ]; then
    echo -e "${YELLOW}No coverage files found. Run tests first:${NC}"
    echo "  ./scripts/development/test.sh"
    exit 0
  fi
  
  echo "Found coverage files:"
  echo "$COVERAGE_FILES" | sed 's/^/  - /'
  echo ""
  echo -e "${GREEN}✓ Coverage data collected${NC}"
  exit 0
fi

# Run tests with coverage if not already done
echo -e "${GREEN}Collecting coverage...${NC}"
echo ""

# Run tests to generate coverage (test.sh handles coverage)
if [ "$VERBOSE" = true ]; then
  "${PROJECT_ROOT}/scripts/development/test.sh" --verbose
else
  "${PROJECT_ROOT}/scripts/development/test.sh"
fi

# Find all lcov.info files and combine them
COVERAGE_DIR="${PROJECT_ROOT}/coverage"
mkdir -p "$COVERAGE_DIR"

COVERAGE_OUTPUT="${COVERAGE_DIR}/lcov.info"

echo ""
echo "Combining coverage files..."
echo ""

# Combine all lcov.info files
COVERAGE_FILES=$(find . -name "lcov.info" -type f 2>/dev/null | grep -v node_modules | grep -v ".dart_tool" | grep -v coverage || true)

if [ -z "$COVERAGE_FILES" ]; then
  echo -e "${RED}Error: No coverage files found${NC}"
  echo ""
  echo "Run tests first:"
  echo "  ./scripts/development/test.sh"
  exit 1
fi

# Combine coverage files
if [ "$VERBOSE" = true ]; then
  lcov --add-tracefile "${COVERAGE_OUTPUT}" --output-file "${COVERAGE_OUTPUT}" 2>/dev/null || rm -f "${COVERAGE_OUTPUT}"
  for file in $COVERAGE_FILES; do
    if [ -f "$file" ]; then
      lcov --add-tracefile "$file" --output-file "${COVERAGE_OUTPUT}" 2>/dev/null || true
    fi
  done
else
  lcov --add-tracefile "${COVERAGE_OUTPUT}" --output-file "${COVERAGE_OUTPUT}" 2>/dev/null || rm -f "${COVERAGE_OUTPUT}"
  for file in $COVERAGE_FILES; do
    if [ -f "$file" ]; then
      lcov --add-tracefile "$file" --output-file "${COVERAGE_OUTPUT}" 2>/dev/null || true
    fi
  done 2>/dev/null
fi

# Generate HTML report
HTML_OUTPUT="${COVERAGE_DIR}/html"

echo "Generating HTML report..."
echo ""

if [ "$VERBOSE" = true ]; then
  genhtml "${COVERAGE_OUTPUT}" --output-directory "${HTML_OUTPUT}"
else
  genhtml "${COVERAGE_OUTPUT}" --output-directory "${HTML_OUTPUT}" 2>/dev/null
fi

if [ $? -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ Coverage report generated${NC}"
  echo ""
  echo "Report location: ${HTML_OUTPUT}/index.html"
  
  if [ "$OPEN_BROWSER" = true ]; then
    # Open in default browser
    if command -v open &> /dev/null; then
      open "${HTML_OUTPUT}/index.html"
    elif command -v xdg-open &> /dev/null; then
      xdg-open "${HTML_OUTPUT}/index.html"
    else
      echo ""
      echo "Open the report manually: ${HTML_OUTPUT}/index.html"
    fi
  else
    echo ""
    echo "Open with:"
    echo "  open ${HTML_OUTPUT}/index.html"
    echo "  or"
    echo "  ./scripts/tools/coverage-report.sh --open"
  fi
  exit 0
else
  echo ""
  echo -e "${RED}✗ Failed to generate coverage report${NC}"
  exit 1
fi

