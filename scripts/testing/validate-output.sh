#!/usr/bin/env bash

# Validation script for checking command output
# Validates JSON output, file generation, and structure

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

# Parse arguments
FILE_PATH=""
JSON_FILE=""
PROJECT_DIR=""
SCREEN_DIR=""
SERVICE_DIR=""
VERBOSE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--file)
      FILE_PATH="$2"
      shift 2
      ;;
    -j|--json)
      JSON_FILE="$2"
      shift 2
      ;;
    -p|--project)
      PROJECT_DIR="$2"
      shift 2
      ;;
    -s|--screen)
      SCREEN_DIR="$2"
      shift 2
      ;;
    -e|--service)
      SERVICE_DIR="$2"
      shift 2
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Validate command output and generated files."
      echo ""
      echo "Options:"
      echo "  -f, --file PATH      Validate specific file exists"
      echo "  -j, --json PATH      Validate JSON file format"
      echo "  -p, --project DIR    Validate Flutter project structure"
      echo "  -s, --screen DIR     Validate screen generation"
      echo "  -e, --service DIR    Validate service generation"
      echo "  -v, --verbose        Enable verbose output"
      echo "  -h, --help           Show this help message"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

# Validate JSON file
validate_json() {
  local json_file="$1"
  
  if [ ! -f "$json_file" ]; then
    echo -e "${RED}✗ JSON file not found: ${json_file}${NC}"
    return 1
  fi
  
  # Check if jq is available
  if command -v jq &> /dev/null; then
    if jq empty "$json_file" 2>/dev/null; then
      echo -e "${GREEN}✓ JSON file is valid: ${json_file}${NC}"
      return 0
    else
      echo -e "${RED}✗ JSON file is invalid: ${json_file}${NC}"
      return 1
    fi
  else
    # Basic JSON validation without jq
    if grep -q '{' "$json_file" && grep -q '}' "$json_file"; then
      echo -e "${YELLOW}⚠ JSON file exists but jq not available for validation${NC}"
      return 0
    else
      echo -e "${RED}✗ JSON file appears invalid: ${json_file}${NC}"
      return 1
    fi
  fi
}

# Validate Flutter project structure
validate_project() {
  local project_dir="$1"
  
  if [ ! -d "$project_dir" ]; then
    echo -e "${RED}✗ Project directory not found: ${project_dir}${NC}"
    return 1
  fi
  
  local errors=0
  
  # Check required files
  if [ ! -f "${project_dir}/pubspec.yaml" ]; then
    echo -e "${RED}✗ Missing pubspec.yaml${NC}"
    errors=$((errors + 1))
  else
    echo -e "${GREEN}✓ pubspec.yaml exists${NC}"
  fi
  
  if [ ! -d "${project_dir}/lib" ]; then
    echo -e "${RED}✗ Missing lib directory${NC}"
    errors=$((errors + 1))
  else
    echo -e "${GREEN}✓ lib directory exists${NC}"
  fi
  
  if [ ! -f "${project_dir}/lib/main.dart" ]; then
    echo -e "${YELLOW}⚠ Missing lib/main.dart${NC}"
  else
    echo -e "${GREEN}✓ lib/main.dart exists${NC}"
  fi
  
  # Check platform directories if they exist
  if [ -d "${project_dir}/android" ]; then
    echo -e "${GREEN}✓ android directory exists${NC}"
  fi
  
  if [ -d "${project_dir}/ios" ]; then
    echo -e "${GREEN}✓ ios directory exists${NC}"
  fi
  
  if [ $errors -eq 0 ]; then
    echo -e "${GREEN}✓ Project structure is valid${NC}"
    return 0
  else
    echo -e "${RED}✗ Project structure has ${errors} error(s)${NC}"
    return 1
  fi
}

# Validate screen generation
validate_screen() {
  local screen_dir="$1"
  
  if [ ! -d "$screen_dir" ]; then
    echo -e "${RED}✗ Screen directory not found: ${screen_dir}${NC}"
    return 1
  fi
  
  # Check for screen file
  if find "$screen_dir" -name "*_screen.dart" -o -name "*screen*.dart" | grep -q .; then
    echo -e "${GREEN}✓ Screen file found${NC}"
  else
    echo -e "${YELLOW}⚠ No screen file found in expected format${NC}"
  fi
  
  # Check for test file if expected
  if find "$screen_dir" -name "*_test.dart" | grep -q .; then
    echo -e "${GREEN}✓ Test file found${NC}"
  fi
  
  return 0
}

# Validate service generation
validate_service() {
  local service_dir="$1"
  
  if [ ! -d "$service_dir" ]; then
    echo -e "${RED}✗ Service directory not found: ${service_dir}${NC}"
    return 1
  fi
  
  # Check for service file
  if find "$service_dir" -name "*_service.dart" -o -name "*service*.dart" | grep -q .; then
    echo -e "${GREEN}✓ Service file found${NC}"
  else
    echo -e "${YELLOW}⚠ No service file found in expected format${NC}"
  fi
  
  # Check for test file if expected
  if find "$service_dir" -name "*_test.dart" | grep -q .; then
    echo -e "${GREEN}✓ Test file found${NC}"
  fi
  
  return 0
}

# Main validation
VALIDATION_FAILED=false

if [ -n "$FILE_PATH" ]; then
  if [ -f "$FILE_PATH" ]; then
    echo -e "${GREEN}✓ File exists: ${FILE_PATH}${NC}"
  else
    echo -e "${RED}✗ File not found: ${FILE_PATH}${NC}"
    VALIDATION_FAILED=true
  fi
fi

if [ -n "$JSON_FILE" ]; then
  if ! validate_json "$JSON_FILE"; then
    VALIDATION_FAILED=true
  fi
fi

if [ -n "$PROJECT_DIR" ]; then
  if ! validate_project "$PROJECT_DIR"; then
    VALIDATION_FAILED=true
  fi
fi

if [ -n "$SCREEN_DIR" ]; then
  if ! validate_screen "$SCREEN_DIR"; then
    VALIDATION_FAILED=true
  fi
fi

if [ -n "$SERVICE_DIR" ]; then
  if ! validate_service "$SERVICE_DIR"; then
    VALIDATION_FAILED=true
  fi
fi

if [ "$VALIDATION_FAILED" = true ]; then
  exit 1
else
  exit 0
fi

