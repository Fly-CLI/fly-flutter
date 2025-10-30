# Fly CLI Development Scripts

This directory contains comprehensive shell scripts for automating CLI commands and development workflows in the Fly CLI project.

## Quick Start

All scripts should be run from the project root directory:

```bash
# Setup the project
./scripts/setup/bootstrap.sh

# Run tests
./scripts/development/test.sh

# Use CLI commands
./scripts/cli/create.sh my_app
```

## Script Organization

Scripts are organized into logical groups:

- **setup/** - Initial setup and installation
- **development/** - Development workflow (test, format, analyze)
- **cli/** - Wrappers for Fly CLI commands
- **mcp/** - MCP (Model Context Protocol) server and integration scripts
- **build/** - Build scripts for examples and packages
- **ci/** - CI/CD tests and checks
- **tools/** - Utility scripts

## Setup Scripts

### `setup/bootstrap.sh`

Bootstrap the monorepo with melos. Installs all package dependencies.

**Usage:**
```bash
./scripts/setup/bootstrap.sh
./scripts/setup/bootstrap.sh --verbose
```

**What it does:**
- Checks if melos is installed
- Runs `melos bootstrap` to install all package dependencies
- Verifies the bootstrap was successful

### `setup/install.sh`

Install Fly CLI locally for development.

**Usage:**
```bash
./scripts/setup/install.sh
```

**What it does:**
- Activates the CLI from local source using `dart pub global activate --source path packages/fly_cli`
- Makes the `fly` command available globally

### `setup/verify.sh`

Verify the installation is working correctly.

**Usage:**
```bash
./scripts/setup/verify.sh
```

**What it does:**
- Runs `fly doctor` to check system configuration
- Verifies all dependencies are properly installed

## Development Scripts

### `development/analyze.sh`

Run static analysis on all packages.

**Usage:**
```bash
./scripts/development/analyze.sh
./scripts/development/analyze.sh --verbose
```

**What it does:**
- Runs `melos run analyze` to execute `flutter analyze` on all packages
- Reports any analysis issues

### `development/format.sh`

Format all Dart files in the project.

**Usage:**
```bash
./scripts/development/format.sh
```

**What it does:**
- Runs `melos run format` to format all Dart files
- Uses `dart format --set-exit-if-changed .`

### `development/format-check.sh`

Check if all Dart files are properly formatted without changing them.

**Usage:**
```bash
./scripts/development/format-check.sh
```

**What it does:**
- Runs `melos run format:check` to verify formatting
- Exits with error code if formatting issues are found

### `development/test.sh`

Run all tests with coverage.

**Usage:**
```bash
./scripts/development/test.sh
./scripts/development/test.sh --verbose
```

**What it does:**
- Runs `melos run test` to execute all tests with coverage
- Only runs tests in packages that have a `test/` directory

### `development/test-changed.sh`

Run tests only for packages that have changed.

**Usage:**
```bash
./scripts/development/test-changed.sh
```

**What it does:**
- Runs `melos run test:changed` to test only packages changed since last commit
- Useful for quick feedback during development

### `development/test-unit.sh`

Run unit tests only.

**Usage:**
```bash
./scripts/development/test-unit.sh [package_name]
```

**Examples:**
```bash
# Run all unit tests
./scripts/development/test-unit.sh

# Run unit tests for specific package
./scripts/development/test-unit.sh fly_cli
```

### `development/test-integration.sh`

Run integration tests.

**Usage:**
```bash
./scripts/development/test-integration.sh
```

**What it does:**
- Runs integration tests from `test/integration/` directories

### `development/test-e2e.sh`

Run end-to-end tests.

**Usage:**
```bash
./scripts/development/test-e2e.sh
```

**What it does:**
- Runs E2E tests from `test/e2e/` directories

### `development/test-mcp.sh`

Run MCP conformance tests.

**Usage:**
```bash
./scripts/development/test-mcp.sh
```

**What it does:**
- Runs `dart run tool/ci/mcp_conformance_test.dart`
- Tests MCP protocol compliance

### `development/build-runner.sh`

Run code generation with build_runner.

**Usage:**
```bash
./scripts/development/build-runner.sh
```

**What it does:**
- Runs `melos run build_runner` to generate code for all packages
- Uses `build_runner build --delete-conflicting-outputs`

### `development/clean.sh`

Clean all packages (remove build artifacts).

**Usage:**
```bash
./scripts/development/clean.sh
```

**What it does:**
- Runs `melos run clean` to execute `flutter clean` on all packages

### `development/get.sh`

Get dependencies for all packages.

**Usage:**
```bash
./scripts/development/get.sh
```

**What it does:**
- Runs `melos run get` to execute `flutter pub get` on all packages

### `development/outdated.sh`

Check for outdated dependencies.

**Usage:**
```bash
./scripts/development/outdated.sh
```

**What it does:**
- Runs `melos run outdated` to check for outdated packages

## CLI Command Wrappers

These scripts wrap Fly CLI commands for convenience.

### `cli/create.sh`

Create a new Flutter project.

**Usage:**
```bash
./scripts/cli/create.sh PROJECT_NAME [OPTIONS]
```

**Examples:**
```bash
# Basic project creation
./scripts/cli/create.sh my_app

# With template
./scripts/cli/create.sh my_app --template=riverpod

# With JSON output for AI integration
./scripts/cli/create.sh my_app --template=riverpod --output=json
```

**Options:** All Fly CLI `create` command options are supported.

### `cli/doctor.sh`

Run system diagnostics.

**Usage:**
```bash
./scripts/cli/doctor.sh [--fix] [--output=json]
```

**Examples:**
```bash
# Check system status
./scripts/cli/doctor.sh

# Attempt to fix issues
./scripts/cli/doctor.sh --fix

# JSON output
./scripts/cli/doctor.sh --output=json
```

### `cli/schema-export.sh`

Export CLI schema for AI integration.

**Usage:**
```bash
./scripts/cli/schema-export.sh [OPTIONS]
```

**Examples:**
```bash
# Export to stdout
./scripts/cli/schema-export.sh

# Export to file
./scripts/cli/schema-export.sh --file=schema.json

# Include examples
./scripts/cli/schema-export.sh --include-examples
```

### `cli/context-export.sh`

Export project context for AI assistants.

**Usage:**
```bash
./scripts/cli/context-export.sh [OPTIONS]
```

**Examples:**
```bash
# Export to stdout
./scripts/cli/context-export.sh

# Export to file with code
./scripts/cli/context-export.sh --file=context.json --include-code

# Full export
./scripts/cli/context-export.sh --file=context.json --include-code --include-dependencies
```

### `cli/add-screen.sh`

Add a new screen to a project.

**Usage:**
```bash
./scripts/cli/add-screen.sh SCREEN_NAME [OPTIONS]
```

**Examples:**
```bash
# Basic screen
./scripts/cli/add-screen.sh home --feature=auth

# With viewmodel
./scripts/cli/add-screen.sh profile --feature=user --with-viewmodel=true
```

### `cli/add-service.sh`

Add a new service to a project.

**Usage:**
```bash
./scripts/cli/add-service.sh SERVICE_NAME [OPTIONS]
```

**Examples:**
```bash
# API service
./scripts/cli/add-service.sh api --feature=core --type=api

# Database service
./scripts/cli/add-service.sh database --feature=core --type=database
```

### `cli/mcp-doctor.sh`

Run MCP diagnostics.

**Usage:**
```bash
./scripts/cli/mcp-doctor.sh [OPTIONS]
```

**Examples:**
```bash
# Run MCP diagnostics
./scripts/cli/mcp-doctor.sh

# JSON output
./scripts/cli/mcp-doctor.sh --output=json
```

### `cli/version.sh`

Show Fly CLI version information.

**Usage:**
```bash
./scripts/cli/version.sh [OPTIONS]
```

**Examples:**
```bash
# Show version
./scripts/cli/version.sh

# JSON output
./scripts/cli/version.sh --output=json
```

### `cli/completion.sh`

Generate shell completion for Fly CLI.

**Usage:**
```bash
./scripts/cli/completion.sh [SHELL] [OPTIONS]
```

**Examples:**
```bash
# Generate bash completion
./scripts/cli/completion.sh bash

# Generate zsh completion
./scripts/cli/completion.sh zsh

# Output to file
./scripts/cli/completion.sh bash --output=/path/to/completion
```

**To install completion:**
```bash
# Bash
./scripts/cli/completion.sh bash > /etc/bash_completion.d/fly

# Zsh
./scripts/cli/completion.sh zsh > ~/.zsh/completion/_fly
```

## MCP Scripts

These scripts help you set up and use the MCP (Model Context Protocol) server for AI integration.

### `mcp/serve.sh`

Start the MCP server for Cursor/Claude integration.

**Usage:**
```bash
./scripts/mcp/serve.sh [OPTIONS]
```

**Examples:**
```bash
# Start with stdio (for Cursor/Claude)
./scripts/mcp/serve.sh --stdio

# Custom timeout
./scripts/mcp/serve.sh --stdio --default-timeout-seconds=600
```

### `mcp/doctor.sh`

Run MCP diagnostics to check server configuration.

**Usage:**
```bash
./scripts/mcp/doctor.sh [OPTIONS]
```

**Examples:**
```bash
# Check MCP configuration
./scripts/mcp/doctor.sh

# JSON output
./scripts/mcp/doctor.sh --output=json
```

### `mcp/test.sh`

Run MCP conformance tests.

**Usage:**
```bash
./scripts/mcp/test.sh [OPTIONS]
```

**What it does:**
- Runs `./scripts/mcp/conformance.sh` to test MCP protocol compliance

### `mcp/conformance.sh`

Run MCP conformance tests directly.

**Usage:**
```bash
./scripts/mcp/conformance.sh [OPTIONS]
```

**What it does:**
- Runs `dart run tool/ci/mcp_conformance_test.dart`
- Tests MCP protocol compliance

### `mcp/setup.sh`

Interactive setup script for MCP integration.

**Usage:**
```bash
./scripts/mcp/setup.sh [OPTIONS]
```

**Examples:**
```bash
# Interactive setup
./scripts/mcp/setup.sh

# Setup Cursor only
./scripts/mcp/setup.sh --cursor

# Setup Claude Desktop only
./scripts/mcp/setup.sh --claude

# Setup both
./scripts/mcp/setup.sh --all
```

### `mcp/setup-cursor.sh`

Setup Cursor MCP integration by creating `.cursor/mcp.json`.

**Usage:**
```bash
./scripts/mcp/setup-cursor.sh [OPTIONS]
```

**Examples:**
```bash
# Create configuration
./scripts/mcp/setup-cursor.sh

# Overwrite existing configuration
./scripts/mcp/setup-cursor.sh --overwrite
```

**What it does:**
- Creates `.cursor/mcp.json` with Fly MCP server configuration
- Configures MCP server to run with stdio transport

### `mcp/setup-claude.sh`

Setup Claude Desktop MCP integration.

**Usage:**
```bash
./scripts/mcp/setup-claude.sh [OPTIONS]
```

**Examples:**
```bash
# Create configuration
./scripts/mcp/setup-claude.sh

# Overwrite existing configuration
./scripts/mcp/setup-claude.sh --overwrite
```

**What it does:**
- Creates or updates Claude Desktop configuration
- Configures MCP server for Claude Desktop
- Works on macOS and Linux

### `mcp/verify.sh`

Verify MCP server setup and configuration.

**Usage:**
```bash
./scripts/mcp/verify.sh [OPTIONS]
```

**What it does:**
- Checks if Fly CLI is installed
- Verifies Flutter SDK is available
- Checks MCP configuration files (Cursor/Claude)
- Runs MCP diagnostics

**Examples:**
```bash
# Basic verification
./scripts/mcp/verify.sh

# Verbose output
./scripts/mcp/verify.sh --verbose
```

## Build Scripts

### `build/examples.sh`

Build all example apps.

**Usage:**
```bash
./scripts/build/examples.sh [PLATFORM]
```

**Examples:**
```bash
# Build all examples as APK
./scripts/build/examples.sh

# Build for specific platform
./scripts/build/examples.sh apk
./scripts/build/examples.sh ios
```

### `build/package.sh`

Build a specific package.

**Usage:**
```bash
./scripts/build/package.sh PACKAGE_NAME [OPTIONS]
```

**Examples:**
```bash
# Build fly_cli package
./scripts/build/package.sh fly_cli

# Build with specific mode
./scripts/build/package.sh fly_cli --mode=release
```

## CI Scripts

### `ci/test-all.sh`

Run all CI tests (analysis, formatting, tests).

**Usage:**
```bash
./scripts/ci/test-all.sh
```

**What it does:**
- Runs analysis
- Checks formatting
- Runs all tests
- Exits with error if any step fails

### `ci/license-check.sh`

Check license compatibility.

**Usage:**
```bash
./scripts/ci/license-check.sh
```

**What it does:**
- Runs `melos run license:check`
- Verifies all licenses are compatible (MIT)

### `ci/security-scan.sh`

Run security validation on templates.

**Usage:**
```bash
./scripts/ci/security-scan.sh
```

**What it does:**
- Runs `melos run security:scan`
- Validates template security

## Tools Scripts

### `tools/version-bump.sh`

Bump version across packages.

**Usage:**
```bash
./scripts/tools/version-bump.sh [VERSION]
```

**Examples:**
```bash
# Bump patch version (0.1.0 -> 0.1.1)
./scripts/tools/version-bump.sh

# Bump to specific version
./scripts/tools/version-bump.sh 0.2.0
```

### `tools/coverage-report.sh`

Generate coverage report.

**Usage:**
```bash
./scripts/tools/coverage-report.sh
```

**What it does:**
- Collects coverage from all test runs
- Generates HTML coverage report
- Opens report in browser (if available)

### `tools/help.sh`

Display help and usage information.

**Usage:**
```bash
./scripts/tools/help.sh [CATEGORY]
```

**Examples:**
```bash
# Show all help
./scripts/tools/help.sh

# Show help for specific category
./scripts/tools/help.sh development
./scripts/tools/help.sh cli
```

## Common Options

Most scripts support these common options:

- `-v, --verbose` - Enable verbose output
- `-h, --help` - Display help information

## Workflow Examples

### Initial Setup

```bash
# 1. Bootstrap the monorepo
./scripts/setup/bootstrap.sh

# 2. Install CLI locally
./scripts/setup/install.sh

# 3. Verify installation
./scripts/setup/verify.sh
```

### Daily Development

```bash
# Run tests for changed packages
./scripts/development/test-changed.sh

# Format code
./scripts/development/format.sh

# Run analysis
./scripts/development/analyze.sh
```

### Before Committing

```bash
# Check formatting
./scripts/development/format-check.sh

# Run all tests
./scripts/development/test.sh

# Run analysis
./scripts/development/analyze.sh
```

### CI/CD Pipeline

```bash
# Run all CI checks
./scripts/ci/test-all.sh

# Check licenses
./scripts/ci/license-check.sh

# Security scan
./scripts/ci/security-scan.sh
```

### Using CLI Commands

```bash
# Create a new project
./scripts/cli/create.sh my_app --template=riverpod

# Check system status
./scripts/cli/doctor.sh

# Export schema for AI integration
./scripts/cli/schema-export.sh --file=schema.json
```

## Troubleshooting

### Script Permission Errors

If you get permission errors, make scripts executable:

```bash
chmod +x scripts/**/*.sh
```

### Melos Not Found

If melos is not found, install it:

```bash
dart pub global activate melos
```

Add to PATH if needed:

```bash
export PATH="$PATH:$HOME/.pub-cache/bin"
```

### Fly CLI Not Found

If `fly` command is not found after installation:

1. Ensure `scripts/setup/install.sh` completed successfully
2. Check that `$HOME/.pub-cache/bin` is in your PATH
3. Verify installation: `dart pub global list | grep fly_cli`

### Script Fails with Error

1. Check if you're in the project root directory
2. Verify melos is installed and in PATH
3. Run with `--verbose` flag for detailed output:
   ```bash
   ./scripts/development/test.sh --verbose
   ```

## Cross-Platform Notes

All scripts are designed to work on:
- **macOS** (tested and primary)
- **Linux** (should work)
- **Windows** (may require Git Bash or WSL)

For Windows users, use Git Bash or WSL to run these scripts.

## Contributing

When adding new scripts:

1. Place in appropriate subdirectory
2. Use consistent error handling (`set -e`)
3. Support `-v/--verbose` and `-h/--help` flags
4. Update this README with documentation
5. Test on macOS before committing

## See Also

- [Melos Documentation](https://melos.invertase.dev/)
- [Fly CLI Documentation](../../docs/README.md)
- [Project Lifecycle Documentation](../../docs/Project_Lifecycle_Documentation.md)

