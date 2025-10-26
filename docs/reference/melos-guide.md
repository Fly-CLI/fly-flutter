# Melos Comprehensive Guide

A complete guide to using Melos for monorepo management, versioning, and workflow automation in the Fly CLI project.

## Table of Contents

- [Overview](#overview)
- [Configuration](#configuration)
- [Workspace Management](#workspace-management)
- [Commands Reference](#commands-reference)
- [Scripts and Automation](#scripts-and-automation)
- [Versioning Strategies](#versioning-strategies)
- [Publishing Workflows](#publishing-workflows)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

Melos is a powerful tool for managing Dart/Flutter monorepos. In the Fly CLI project, it's used to:

- **Coordinate packages**: Manage multiple packages (`fly_cli`, `fly_core`, `fly_networking`, `fly_state`)
- **Automate workflows**: Run commands across all packages simultaneously
- **Version management**: Coordinate version bumps and changelog generation
- **Publishing**: Streamline package publishing workflows
- **Development**: Provide consistent development experience across packages

## Configuration

### Melos Configuration File

The main configuration is in `pubspec.yaml` under the `melos` section:

```yaml
melos:
  repository: https://github.com/fly-cli/fly.git
  
  command:
    bootstrap:
      runPubGetInParallel: true
      environment:
        sdk: ">=3.5.0 <4.0.0"
        flutter: ">=3.10.0"
      
    version:
      linkToCommits: true
      workspaceChangelog: true
      commitMessageFormat: "chore: bump version to {{version}}"
```

### Key Configuration Options

#### Bootstrap Configuration
- **`runPubGetInParallel`**: Run `pub get` on all packages simultaneously for faster setup
- **`environment`**: Define SDK constraints for all packages in the workspace

#### Version Configuration
- **`linkToCommits`**: Link version bumps to specific commits
- **`workspaceChangelog`**: Generate changelog for the entire workspace
- **`commitMessageFormat`**: Customize commit message format for version bumps

#### Ignore Patterns
```yaml
ignore:
  - "**/*.g.dart"          # Generated files
  - "**/*.freezed.dart"    # Freezed generated files
  - "**/*.mocks.dart"      # Mock files
  - "**/build/**"          # Build outputs
  - "**/.dart_tool/**"     # Dart tool cache
  - "**/coverage/**"       # Test coverage
```

## Workspace Management

### Package Structure

The Fly CLI workspace includes these packages:

```
packages/
├── fly_cli/          # Main CLI package
├── fly_core/         # Core abstractions and utilities
├── fly_networking/   # HTTP client and networking
└── fly_state/        # State management utilities
```

### Workspace Commands

#### Bootstrap Workspace
```bash
# Set up the entire workspace
melos bootstrap

# Bootstrap with specific options
melos bootstrap --no-pub-get-in-parallel
```

#### Clean Workspace
```bash
# Clean all packages
melos clean

# Clean specific packages
melos clean --scope="fly_cli"
```

#### Get Dependencies
```bash
# Get dependencies for all packages
melos exec -- flutter pub get

# Get dependencies for changed packages only
melos exec -- flutter pub get --packageFilters="diff:HEAD~1"
```

## Commands Reference

### Core Melos Commands

#### `melos bootstrap`
Sets up the workspace by:
- Installing dependencies for all packages
- Creating symlinks between packages
- Running post-install scripts

```bash
# Basic bootstrap
melos bootstrap

# Bootstrap without parallel pub get
melos bootstrap --no-pub-get-in-parallel

# Bootstrap with verbose output
melos bootstrap --verbose
```

#### `melos exec`
Execute commands across packages:

```bash
# Run flutter analyze on all packages
melos exec -- flutter analyze

# Run tests on packages with test directory
melos exec -- flutter test --packageFilters="dirExists:test"

# Run command on specific package
melos exec -- flutter test --scope="fly_cli"
```

#### `melos list`
List packages in the workspace:

```bash
# List all packages
melos list

# List packages with details
melos list --long

# List packages matching pattern
melos list --scope="fly_*"
```

#### `melos run`
Execute predefined scripts:

```bash
# Run analysis script
melos run analyze

# Run test script
melos run test

# Run format check
melos run format:check
```

### Package Filtering

Melos supports powerful package filtering:

```bash
# Filter by package name pattern
--scope="fly_*"

# Filter by directory existence
--packageFilters="dirExists:test"

# Filter by git diff
--packageFilters="diff:HEAD~1"

# Filter by dependency graph
--packageFilters="dependsOn:fly_core"

# Filter by file changes
--packageFilters="fileExists:lib/main.dart"
```

## Scripts and Automation

### Analysis and Formatting Scripts

#### `analyze`
```yaml
analyze:
  run: melos exec -- flutter analyze
  description: Run analysis on all packages
```

#### `format`
```yaml
format:
  run: melos exec -- dart format --set-exit-if-changed .
  description: Format all Dart files
```

#### `format:check`
```yaml
format:check:
  run: melos exec -- dart format --set-exit-if-changed .
  description: Check formatting without changing files
```

### Testing Scripts

#### `test`
```yaml
test:
  run: melos exec -- flutter test --coverage
  description: Run tests with coverage
  packageFilters:
    dirExists: test
```

#### `test:changed`
```yaml
test:changed:
  run: melos exec -- flutter test
  description: Test only changed packages
  packageFilters:
    diff: HEAD~1
```

### Code Generation Scripts

#### `build_runner`
```yaml
build_runner:
  run: melos exec -- dart run build_runner build --delete-conflicting-outputs
  description: Run code generation for all packages
```

### Publishing Scripts

#### `publish:dry-run`
```yaml
publish:dry-run:
  run: melos publish --dry-run --yes
  description: Dry run publish to verify packages
```

### Development Scripts

#### `clean`
```yaml
clean:
  run: melos exec -- flutter clean
  description: Clean all packages
```

#### `get`
```yaml
get:
  run: melos exec -- flutter pub get
  description: Get dependencies for all packages
```

#### `outdated`
```yaml
outdated:
  run: melos exec -- flutter pub outdated
  description: Check for outdated dependencies
```

### CLI-Specific Scripts

#### `install`
```yaml
install:
  run: dart pub global activate --source path packages/fly_cli
  description: Install Fly CLI locally for development
```

#### `schema:export`
```yaml
schema:export:
  run: dart run packages/fly_cli/bin/fly.dart schema export --output=json
  description: Export CLI schema for AI integration
```

### Security and Compliance Scripts

#### `license:check`
```yaml
license:check:
  run: dart run tools/license_checker.dart
  description: Check license compatibility
```

#### `security:scan`
```yaml
security:scan:
  run: melos exec -- dart run packages/fly_cli/lib/src/security/template_validator.dart
  description: Run security validation on templates
```

## Versioning Strategies

### Version Command Configuration

```yaml
version:
  linkToCommits: true
  workspaceChangelog: true
  commitMessageFormat: "chore: bump version to {{version}}"
```

### Versioning Workflows

#### 1. Independent Versioning
Each package maintains its own version:

```bash
# Version specific package
melos version --scope="fly_cli"

# Version multiple packages
melos version --scope="fly_cli,fly_core"
```

#### 2. Workspace Versioning
Version all packages together:

```bash
# Version all packages
melos version

# Version with specific strategy
melos version --prerelease=beta
```

#### 3. Pre-release Versioning
```bash
# Create beta release
melos version --prerelease=beta

# Create alpha release
melos version --prerelease=alpha

# Create RC release
melos version --prerelease=rc
```

### Version Strategies

#### Patch Versioning
```bash
# Bump patch version (1.0.0 -> 1.0.1)
melos version --patch
```

#### Minor Versioning
```bash
# Bump minor version (1.0.0 -> 1.1.0)
melos version --minor
```

#### Major Versioning
```bash
# Bump major version (1.0.0 -> 2.0.0)
melos version --major
```

### Changelog Generation

Melos automatically generates changelogs when versioning:

```bash
# Generate changelog for all packages
melos version --changelog

# Generate changelog with specific format
melos version --changelog --changelog-format=markdown
```

### Version Constraints

#### Dependency Versioning
```yaml
# In package pubspec.yaml
dependencies:
  fly_core:
    path: ../fly_core
    version: ^1.0.0  # Use caret for compatible versions
```

#### Workspace Versioning
```yaml
# In root pubspec.yaml
melos:
  command:
    version:
      # Automatically update dependency versions
      updateDependencyVersions: true
      # Update dependency constraints
      updateDependencyConstraints: true
```

## Publishing Workflows

### Publishing Configuration

```yaml
melos:
  command:
    publish:
      # Dry run by default
      dryRun: true
      # Skip packages without changes
      skipIfNoChanges: true
      # Force publish
      force: false
```

### Publishing Commands

#### Dry Run Publishing
```bash
# Test publishing without actually publishing
melos publish --dry-run

# Dry run with specific packages
melos publish --dry-run --scope="fly_cli"
```

#### Actual Publishing
```bash
# Publish all packages
melos publish

# Publish specific packages
melos publish --scope="fly_cli,fly_core"

# Force publish (skip checks)
melos publish --force
```

#### Publishing with Versioning
```bash
# Version and publish in one command
melos version --patch && melos publish
```

### Publishing Strategies

#### 1. Independent Publishing
Each package is published independently:

```bash
# Publish only changed packages
melos publish --skip-if-no-changes
```

#### 2. Coordinated Publishing
All packages are published together:

```bash
# Publish all packages
melos publish --all
```

#### 3. Selective Publishing
Publish specific packages:

```bash
# Publish only CLI package
melos publish --scope="fly_cli"
```

### Pre-release Publishing

```bash
# Publish beta version
melos version --prerelease=beta
melos publish --prerelease=beta

# Publish alpha version
melos version --prerelease=alpha
melos publish --prerelease=alpha
```

## Best Practices

### Workspace Organization

#### 1. Package Naming
- Use consistent naming: `fly_*` for all packages
- Keep package names descriptive and concise
- Follow Dart package naming conventions

#### 2. Dependency Management
- Use path dependencies for local packages
- Specify version constraints appropriately
- Keep dependencies up to date

#### 3. Script Organization
- Group related scripts together
- Use descriptive script names
- Include helpful descriptions

### Development Workflow

#### 1. Daily Development
```bash
# Start development session
melos bootstrap

# Run analysis
melos run analyze

# Run tests
melos run test

# Format code
melos run format
```

#### 2. Before Committing
```bash
# Check formatting
melos run format:check

# Run analysis
melos run analyze

# Run tests
melos run test

# Check for outdated dependencies
melos run outdated
```

#### 3. Before Publishing
```bash
# Run full test suite
melos run test

# Run security scan
melos run security:scan

# Check licenses
melos run license:check

# Dry run publish
melos run publish:dry-run
```

### Versioning Best Practices

#### 1. Semantic Versioning
- Follow [SemVer](https://semver.org/) principles
- Use appropriate version bumps
- Document breaking changes

#### 2. Changelog Management
- Keep changelogs up to date
- Use consistent format
- Include migration guides for breaking changes

#### 3. Pre-release Strategy
- Use pre-releases for testing
- Clear naming convention (alpha, beta, rc)
- Document pre-release limitations

### CI/CD Integration

#### GitHub Actions Example
```yaml
name: Melos Workflow

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'
      
      - name: Install Melos
        run: dart pub global activate melos
      
      - name: Bootstrap
        run: melos bootstrap
      
      - name: Analyze
        run: melos run analyze
      
      - name: Test
        run: melos run test
      
      - name: Format Check
        run: melos run format:check
```

#### GitLab CI Example
```yaml
stages:
  - test
  - publish

variables:
  FLUTTER_VERSION: "3.10.0"

test:
  stage: test
  image: cirrusci/flutter:stable
  script:
    - dart pub global activate melos
    - melos bootstrap
    - melos run analyze
    - melos run test
    - melos run format:check

publish:
  stage: publish
  image: cirrusci/flutter:stable
  script:
    - dart pub global activate melos
    - melos bootstrap
    - melos run publish:dry-run
  only:
    - main
```

## Troubleshooting

### Common Issues

#### Bootstrap Issues

**Problem**: Bootstrap fails with dependency conflicts
```bash
# Solution: Clean and retry
melos clean
melos bootstrap
```

**Problem**: Symlink creation fails
```bash
# Solution: Check permissions and retry
sudo melos bootstrap
```

#### Version Issues

**Problem**: Version command fails
```bash
# Solution: Check git status
git status
git add .
git commit -m "chore: prepare for version bump"
melos version
```

**Problem**: Changelog generation fails
```bash
# Solution: Check git history
git log --oneline
melos version --changelog
```

#### Publishing Issues

**Problem**: Publishing fails with authentication
```bash
# Solution: Configure pub credentials
dart pub token add https://pub.dev
```

**Problem**: Package already exists
```bash
# Solution: Use force flag or bump version
melos publish --force
# or
melos version --patch
melos publish
```

### Debugging Commands

#### Verbose Output
```bash
# Enable verbose output for any command
melos bootstrap --verbose
melos version --verbose
melos publish --verbose
```

#### Dry Run
```bash
# Test commands without side effects
melos publish --dry-run
melos version --dry-run
```

#### Package Filtering
```bash
# Test on specific packages
melos exec -- flutter test --scope="fly_cli"
melos version --scope="fly_cli"
```

### Performance Optimization

#### Parallel Execution
```bash
# Use parallel execution for faster builds
melos exec -- flutter test --concurrency=4
```

#### Caching
```bash
# Use build cache
melos exec -- flutter build --cache
```

#### Selective Testing
```bash
# Test only changed packages
melos run test:changed
```

### Getting Help

#### Melos Help
```bash
# Get help for any command
melos --help
melos bootstrap --help
melos version --help
melos publish --help
```

#### Package Help
```bash
# Get help for specific package
melos exec -- flutter --help --scope="fly_cli"
```

#### Community Resources
- [Melos Documentation](https://melos.invertase.dev/)
- [Melos GitHub](https://github.com/invertase/melos)
- [Fly CLI GitHub](https://github.com/fly-cli/fly)

## Advanced Usage

### Custom Scripts

#### Complex Workflows
```yaml
# Custom script for full CI pipeline
ci:full:
  run: |
    melos run analyze
    melos run test
    melos run format:check
    melos run security:scan
    melos run license:check
  description: Run full CI pipeline
```

#### Conditional Scripts
```yaml
# Script that runs only on specific packages
test:integration:
  run: melos exec -- flutter test integration_test/
  description: Run integration tests
  packageFilters:
    dirExists: integration_test
```

### Environment Variables

#### Custom Environment
```bash
# Set custom environment variables
export MELOS_ROOT_PATH=/path/to/workspace
export FLUTTER_VERSION=3.10.0
melos bootstrap
```

#### Script Environment
```yaml
# Script with custom environment
build:release:
  run: melos exec -- flutter build apk --release
  description: Build release APK
  env:
    FLUTTER_BUILD_MODE: release
```

### Integration with Other Tools

#### Mason Integration
```yaml
# Mason brick generation
generate:bricks:
  run: melos exec -- mason make
  description: Generate code from Mason bricks
```

#### Very Good CLI Integration
```yaml
# Very Good CLI commands
very_good:create:
  run: melos exec -- very_good create
  description: Create packages with Very Good CLI
```

This comprehensive guide covers all aspects of using Melos in the Fly CLI project, from basic configuration to advanced workflows and troubleshooting. Use this as a reference for managing the monorepo effectively and efficiently.
