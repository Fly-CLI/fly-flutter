# Fly CLI Manual Testing Scripts

This directory contains scripts and tools for manually testing Fly CLI commands during development.

## Quick Start

```bash
# 1. Setup test environment
./scripts/testing/setup-test-env.sh

# 2. Run all tests
./scripts/testing/run-test-suite.sh

# 3. Or run specific test suite
./scripts/testing/run-test-suite.sh --suite project
```

## Scripts

### Setup Scripts

- **`setup-test-env.sh`** - Setup test environment with isolated directories
  - Creates test workspace at `~/fly_test_workspace`
  - Sets up test directories (projects, screens, services, results, artifacts)
  - Creates environment variables file
  - Verifies CLI and Flutter installation

- **`clean-test-env.sh`** - Clean test environment
  - Removes test artifacts
  - Use `--full` to remove entire workspace including results

### Test Execution Scripts

- **`run-test-suite.sh`** - Master test runner
  - Runs all test suites or specific suite
  - Generates comprehensive test report
  - Options: `--suite`, `--clean`, `--verbose`, `--skip-setup`

- **`run-test-generate-project.sh`** - Test Generate Project command
  - Basic functionality tests
  - Template validation
  - Platform validation
  - Error scenarios
  - Plan mode tests

- **`run-test-generate-screen.sh`** - Test Generate Screen command
  - Basic functionality tests
  - Flag combinations
  - Screen type validation
  - Error scenarios
  - Requires Flutter project setup

- **`run-test-generate-service.sh`** - Test Generate Service command
  - Basic functionality tests
  - Service type validation
  - API-specific tests
  - Flag combinations
  - Error scenarios
  - Requires Flutter project setup

- **`run-test-other-commands.sh`** - Test other CLI commands
  - Version command
  - Doctor command
  - Context export
  - Schema export
  - Completion generation

### Integration Scenario Runner

- **`packages/fly_cli/tool/integration_scenarios/run-integration-scenarios.sh`** - Encapsulated integration scenario runner
  - Executes all JSON scenarios from `packages/fly_cli/tool/integration_scenarios/scenarios`
  - Supports both Fly CLI and Mason execution modes
  - Compares generated outputs against golden files in `packages/fly_cli/tool/integration_scenarios/goldens`
  - Provides comprehensive summary reporting suitable for CI/CD
  - Options: `--mode=fly|mason`, `--accept-missing-goldens`, `--keep-temp`, `--verbose`
  - See the script's `--help` for detailed usage

### Validation Scripts

- **`validate-output.sh`** - Validate command output and generated files
  - JSON file validation
  - Flutter project structure validation
  - Screen generation validation
  - Service generation validation

### Documentation

- **`test-checklist.md`** - Comprehensive checklist for manual testing
  - All test cases from the manual testing plan
  - Checkboxes for tracking progress
  - Organized by command category

- **`test-result-template.md`** - Template for documenting test results
  - Test information section
  - Test results tables
  - Error logs section
  - Performance observations
  - Recommendations

## Usage Examples

### Basic Testing Workflow

```bash
# 1. Setup environment
./scripts/testing/setup-test-env.sh

# 2. Run all tests
./scripts/testing/run-test-suite.sh

# 3. Review results
cat ~/fly_test_workspace/results/*/test_summary.txt
```

### Testing Specific Command

```bash
# Test only Generate Project command
./scripts/testing/run-test-suite.sh --suite project

# Test only Generate Screen command
./scripts/testing/run-test-suite.sh --suite screen

# Test only Generate Service command
./scripts/testing/run-test-suite.sh --suite service

# Test other commands
./scripts/testing/run-test-suite.sh --suite other
```

### Clean Testing

```bash
# Clean environment and run all tests
./scripts/testing/run-test-suite.sh --clean

# Clean artifacts only
./scripts/testing/clean-test-env.sh

# Full clean (remove entire workspace)
./scripts/testing/clean-test-env.sh --full
```

### Running Integration Scenarios

```bash
# Run all scenarios using Fly CLI (default)
./packages/fly_cli/tool/integration_scenarios/run-integration-scenarios.sh

# Run scenarios using Mason
./packages/fly_cli/tool/integration_scenarios/run-integration-scenarios.sh --mode=mason

# Run with verbose output
./packages/fly_cli/tool/integration_scenarios/run-integration-scenarios.sh --verbose

# Accept missing goldens automatically
./packages/fly_cli/tool/integration_scenarios/run-integration-scenarios.sh --accept-missing-goldens

# Keep temporary output for inspection
./packages/fly_cli/tool/integration_scenarios/run-integration-scenarios.sh --keep-temp
```

### Validating Output

```bash
# Validate JSON output
./scripts/testing/validate-output.sh --json results/context.json

# Validate Flutter project structure
./scripts/testing/validate-output.sh --project ~/fly_test_workspace/projects/test_app

# Validate screen generation
./scripts/testing/validate-output.sh --screen ~/fly_test_workspace/projects/test_app/lib/features/auth/screens

# Validate service generation
./scripts/testing/validate-output.sh --service ~/fly_test_workspace/projects/test_app/lib/features/core/services
```

## Test Results

Test results are stored in:
```
~/fly_test_workspace/results/TIMESTAMP/
```

Each test run creates:
- `test_summary.txt` - Summary of all test suites
- `generate_project_tests.log` - Detailed project command test log
- `generate_screen_tests.log` - Detailed screen command test log
- `generate_service_tests.log` - Detailed service command test log
- `other_commands_tests.log` - Detailed other commands test log

## Manual Testing Checklist

Use `test-checklist.md` to track manual testing progress:

```bash
# Open checklist in editor
code scripts/testing/test-checklist.md

# Or view in terminal
cat scripts/testing/test-checklist.md
```

## Test Result Documentation

Use `test-result-template.md` to document test results:

```bash
# Copy template
cp scripts/testing/test-result-template.md ~/fly_test_workspace/results/test_results.md

# Fill in results
code ~/fly_test_workspace/results/test_results.md
```

## Environment Variables

Test scripts use these environment variables (set by `setup-test-env.sh`):

- `FLY_TEST_WORKSPACE` - Test workspace directory
- `FLY_OUTPUT_DIR` - Output directory for artifacts
- `FLY_VERBOSE` - Enable verbose output
- `FLY_TEST_MODE` - Enable test mode

## Troubleshooting

### CLI Not Found

```bash
# Install CLI locally
cd /path/to/Fly
./scripts/setup/install.sh

# Verify installation
./scripts/setup/verify.sh
```

### Flutter Project Required

Some tests require a Flutter project. The test scripts will create one automatically, but if it fails:

```bash
# Manually create test project
cd ~/fly_test_workspace/projects
fly generate project test_flutter_project --template=minimal
```

### Permission Issues

If you get permission errors:

```bash
# Make scripts executable
chmod +x scripts/testing/*.sh
```

### Test Environment Issues

If test environment is corrupted:

```bash
# Full clean
./scripts/testing/clean-test-env.sh --full

# Re-setup
./scripts/testing/setup-test-env.sh
```

## Integration with Development Workflow

### Before Committing

```bash
# Run manual tests
./scripts/testing/run-test-suite.sh

# Check results
cat ~/fly_test_workspace/results/*/test_summary.txt
```

### During Development

```bash
# Test specific command you're working on
./scripts/testing/run-test-suite.sh --suite project

# Validate output
./scripts/testing/validate-output.sh --project ~/fly_test_workspace/projects/test_app
```

### Before Release

```bash
# Clean and run all tests
./scripts/testing/run-test-suite.sh --clean

# Document results using template
cp scripts/testing/test-result-template.md test_results_RELEASE.md
```

## Notes

- Test scripts are designed for manual testing and validation
- They complement automated tests but don't replace them
- Results should be reviewed and documented manually
- Use the checklist to ensure comprehensive coverage
- Test results are preserved in timestamped directories

