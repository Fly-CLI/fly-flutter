# Fly CLI Project Lifecycle Documentation

**Version:** 0.1.0  
**Last Updated:** December 2024  
**Status:** Phase 0 - Critical Foundation

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Prerequisites and System Requirements](#prerequisites-and-system-requirements)
3. [Project Architecture Overview](#project-architecture-overview)
4. [Installation and Setup Workflow](#installation-and-setup-workflow)
5. [Core Command Reference and Usage Patterns](#core-command-reference-and-usage-patterns)
6. [Template System Deep Dive](#template-system-deep-dive)
7. [AI Integration and Machine-Readable Interfaces](#ai-integration-and-machine-readable-interfaces)
8. [Development Workflow and Best Practices](#development-workflow-and-best-practices)
9. [Package Management and Dependencies](#package-management-and-dependencies)
10. [Testing and Quality Assurance](#testing-and-quality-assurance)
11. [Build and Deployment Process](#build-and-deployment-process)
12. [Troubleshooting and Common Issues](#troubleshooting-and-common-issues)
13. [Advanced Features and Customization](#advanced-features-and-customization)
14. [Security and Compliance](#security-and-compliance)
15. [Performance Optimization](#performance-optimization)
16. [Integration with Development Tools](#integration-with-development-tools)
17. [Community and Contribution Guidelines](#community-and-contribution-guidelines)
18. [Future Roadmap and Extensibility](#future-roadmap-and-extensibility)

---

## 1. Executive Summary

### 1.1 Project Overview

Fly CLI is the first AI-native Flutter CLI tool designed specifically for the era of AI-assisted
development. It provides intelligent automation, multi-architecture support, and seamless
integration with modern AI coding assistants like Cursor, GitHub Copilot, and ChatGPT.

**Key Differentiators:**

- AI-first architecture with JSON output for all commands
- Declarative project manifests for reproducible project generation
- Template-based code generation using Mason
- Comprehensive foundation packages for networking, state management, and core abstractions
- Cross-platform support for Windows, macOS, and Linux
- Multi-architecture templates (Minimal, Riverpod with planned MVVM, Clean, BLoC)

### 1.2 Key Value Propositions

1. **AI Integration**: Every command outputs machine-readable JSON, making it perfect for AI tool
   integration
2. **Production-Ready Templates**: Battle-tested project structures following Flutter best practices
3. **Rapid Development**: Create complete Flutter projects in under 30 seconds
4. **Developer Experience**: Interactive wizards, comprehensive error messages, and actionable
   suggestions
5. **Foundation Packages**: Built-in packages eliminate the need to rebuild common abstractions
6. **Cross-Platform**: Generate projects that run on iOS, Android, Web, macOS, Windows, and Linux

### 1.3 Target Audience

- **Flutter Developers**: Teams and individuals building Flutter applications
- **AI Coding Assistants**: AI tools like Cursor, Copilot, and ChatGPT that need structured project
  information
- **Enterprise Teams**: Organizations requiring standardized project structures and governance
- **Contributors**: Open-source community members extending Fly CLI functionality

### 1.4 Current Status

**Phase:** Phase 0 - Critical Foundation  
**Version:** 0.1.0  
**Delivery Timeline:** Foundation establishment (7 days) before MVP delivery

**Completed Foundations:**

- ✅ Monorepo structure with Melos
- ✅ Core CLI package architecture
- ✅ Minimal and Riverpod templates
- ✅ Foundation packages (fly_core, fly_networking, fly_state)
- ✅ Basic command structure
- ✅ Template system with Mason integration
- ✅ JSON output format
- ✅ E2E test framework

**Phase 0 In Progress:**

- 🔄 Security framework (template validation, dependency scanning, sandboxing)
- 🔄 License compliance (MIT compatibility, attribution system)
- 🔄 Platform testing (cross-platform CI/CD, platform-specific utilities)
- 🔄 Offline mode architecture (template caching, network resilience)

---

## 2. Prerequisites and System Requirements

### 2.1 Development Environment

#### Required Software

| Software    | Minimum Version    | Purpose                   |
|-------------|--------------------|---------------------------|
| Dart SDK    | 3.0.0+             | Core development language |
| Flutter SDK | 3.10.0+            | Flutter framework         |
| Git         | 2.0.0+             | Version control           |
| Node.js     | 16.0.0+ (optional) | Documentation generation  |

#### Platform Support

- **macOS**: 10.15 (Catalina) or later
- **Linux**: Ubuntu 18.04+ or equivalent
- **Windows**: Windows 10 or later

### 2.2 Required Tools

**Essential:**

- Terminal/Command Prompt with shell access
- Git client
- IDE with Dart/Flutter support (VS Code, Android Studio, Cursor recommended)

**Optional:**

- Docker (for containerized development and testing)
- GitHub CLI (for Git operations)
- Homebrew (macOS) or Chocolatey (Windows) for package management

### 2.3 Optional Tools

- **CI/CD Access**: GitHub Actions, GitLab CI, or Jenkins
- **API Documentation Tools**: OpenAPI, Postman
- **Performance Profiling**: Flutter DevTools, Android Studio Profiler

### 2.4 System Capabilities

- **Disk Space**: Minimum 5GB free space for development environment
- **RAM**: 8GB minimum, 16GB recommended
- **Network**: Internet connection for package downloads and template retrieval
- **Permissions**: Write access to project directories, system path modification

---

## 3. Project Architecture Overview

### 3.1 Monorepo Structure

Fly CLI uses a Melos-based monorepo structure for managing multiple packages:

```
fly/
├── packages/
│   ├── fly_cli/          # Main CLI package
│   ├── fly_core/         # Core abstractions and utilities
│   ├── fly_networking/   # Networking layer
│   └── fly_state/        # State management abstractions
├── templates/            # Project templates
│   ├── minimal/          # Minimal template
│   └── riverpod/         # Riverpod template
├── examples/             # Example projects
├── docs/                 # Documentation
├── test/                 # Cross-package tests
└── melos.yaml           # Melos configuration
```

### 3.2 Core Packages

#### 3.2.1 fly_cli

**Purpose**: Main CLI application with command handling and user interaction

**Key Responsibilities:**

- Command parsing and execution
- Template management and project generation
- System diagnostics and validation
- JSON output formatting for AI integration
- Schema export for AI tools

**Dependencies:**

- `args`: Command-line argument parsing
- `mason_logger`: Logging and progress indicators
- `mason`: Template generation engine
- `path`, `yaml`, `http`: Core utilities

#### 3.2.2 fly_core

**Purpose**: Core abstractions and utilities shared across Fly packages

**Key Responsibilities:**

- Common data structures and types
- Shared utilities and helpers
- Core business logic abstractions
- Platform detection and capabilities

#### 3.2.3 fly_networking

**Purpose**: Networking layer for API communication

**Key Responsibilities:**

- HTTP client abstraction
- Request/response handling
- Error handling and retries
- API rate limiting

#### 3.2.4 fly_state

**Purpose**: State management abstractions

**Key Responsibilities:**

- State management interfaces
- Provider abstractions
- State persistence utilities

### 3.3 Template System

Templates use Mason bricks for code generation:

**Structure:**

```
template_name/
├── __brick__/           # Mason brick files
│   ├── lib/
│   ├── pubspec.yaml
│   └── README.md
└── template.yaml        # Template metadata
```

**Template Metadata (`template.yaml`):**

- Template name, version, description
- Minimum Flutter/Dart SDK versions
- Configurable variables (project_name, organization, platforms, etc.)
- Feature list
- Required packages

### 3.4 AI Integration

**JSON Output Format**: All commands support `--output=json` for machine-readable output

**Schema Export**: `fly schema export` generates complete CLI schema for AI integration

**Context Export**: `fly context-export` generates project-specific context for AI assistants

### 3.5 Testing Framework

**Test Categories:**

- **Unit Tests**: Individual package functionality
- **Integration Tests**: CLI command execution
- **E2E Tests**: Complete project creation workflows
- **Performance Tests**: Creation speed and resource usage
- **Security Tests**: Template validation and sandboxing

---

## 4. Installation and Setup Workflow

### 4.1 Local Development Setup

#### Step 1: Clone Repository

```bash
# Clone repository
git clone https://github.com/fly-cli/fly.git
cd fly
```

#### Step 2: Bootstrap Monorepo

```bash
# Install all package dependencies
melos bootstrap

# Verify installation
melos run analyze
```

#### Step 3: Install CLI Locally

```bash
# Install CLI for local development
melos run install

# Verify installation
fly doctor
```

#### Step 4: Verify Installation

```bash
# Check system setup
fly doctor

# Run tests
melos run test

# Build examples
melos run build:examples
```

### 4.2 Global Installation

```bash
# Activate CLI globally
dart pub global activate fly_cli

# Add to PATH if needed
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Verify installation
fly --version
```

### 4.3 CI/CD Setup

#### GitHub Actions Configuration

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on: [ push, pull_request ]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ ubuntu-latest, windows-latest, macos-latest ]
        sdk: [ '3.0.0' ]
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'
          channel: 'stable'
      - name: Install dependencies
        run: |
          dart pub global activate melos
          melos bootstrap
      - name: Run tests
        run: melos run test
      - name: Run analysis
        run: melos run analyze
```

### 4.4 Development Environment Validation

```bash
# Run comprehensive system diagnostics
fly doctor

# Check for common issues
fly doctor --fix

# Validate Flutter setup
flutter doctor -v

# Check Dart version
dart --version
```

---

## 5. Core Command Reference and Usage Patterns

### 5.1 Project Creation Commands

#### Basic Project Creation

```bash
# Create project with default settings
fly create my_app

# Specify template
fly create my_app --template=riverpod

# Specify platforms
fly create my_app --platforms=ios,android,web

# Specify organization
fly create my_app --organization=com.mycompany

# JSON output for AI integration
fly create my_app --output=json
```

#### Advanced Project Creation

```bash
# Create from manifest file
fly create my_app --from-manifest=fly_project.yaml

# Interactive mode
fly create my_app --interactive

# Combined options
fly create my_app \
  --template=riverpod \
  --organization=com.mycompany \
  --platforms=ios,android,web \
  --output=json
```

#### Command Options

| Option            | Short | Description                        | Default       |
|-------------------|-------|------------------------------------|---------------|
| `--template`      | `-t`  | Project template to use            | `riverpod`    |
| `--organization`  | `-o`  | Organization identifier            | `com.example` |
| `--platforms`     | -     | Target platforms (comma-separated) | `ios,android` |
| `--interactive`   | `-i`  | Run in interactive mode            | `false`       |
| `--from-manifest` | -     | Create project from manifest       | -             |
| `--output`        | -     | Output format (`human`, `json`)    | `human`       |

### 5.2 Component Generation Commands

#### Add Screen Command

```bash
# Basic screen creation
fly add screen home

# With feature
fly add screen home --feature=auth

# With viewmodel
fly add screen profile --feature=user --with-viewmodel=true

# With JSON output
fly add screen settings --output=json
```

#### Add Service Command

```bash
# Basic service
fly add service api --feature=core

# API service with networking
fly add service api --feature=core --type=api

# Database service
fly add service database --feature=core --type=database

# Custom service
fly add service cache --feature=core --type=cache
```

### 5.3 System Commands

#### Doctor Command

```bash
# Run system diagnostics
fly doctor

# Attempt to fix issues
fly doctor --fix

# JSON output
fly doctor --output=json
```

**Diagnostic Checks:**

- Flutter SDK installation and version
- Dart SDK availability
- Android SDK configuration
- iOS SDK availability (macOS only)
- Network connectivity
- Template availability

#### Schema Export Command

```bash
# Export schema to stdout
fly schema export

# Export to file
fly schema export --file=schema.json

# Include examples
fly schema export --include-examples

# Combined
fly schema export --file=schema.json --include-examples
```

**Schema Contents:**

- CLI version and metadata
- Available commands and subcommands
- Command options and flags
- Command descriptions and examples
- Output format specifications
- Error codes and messages

#### Context Export Command

```bash
# Export to stdout
fly context-export

# Export to file
fly context-export --file=context.json

# Include source code
fly context-export --include-code

# Include dependencies
fly context-export --include-dependencies

# Full export
fly context-export --file=context.json --include-code --include-dependencies
```

**Context Contents:**

- Project structure
- Configuration files
- Source code (optional)
- Dependencies (optional)
- Build configuration
- Platform support

#### Version Command

```bash
# Display version
fly version

# Check for updates
fly version --check

# Verbose output
fly version --verbose
```

### 5.4 Command Output Formats

#### Human-Readable Output (Default)

```bash
fly create my_app
# Output:
# Creating Flutter project...
# Template: riverpod
# Organization: com.example
# Platforms: ios, android
# ✅ Project created successfully
```

#### JSON Output

```bash
fly create my_app --output=json
```

**Output Structure:**

```json
{
  "success": true,
  "command": "create",
  "message": "Project created successfully",
  "data": {
    "project_name": "my_app",
    "template": "riverpod",
    "organization": "com.example",
    "platforms": [
      "ios",
      "android"
    ],
    "files_generated": 25,
    "duration_ms": 12450,
    "target_directory": "/path/to/my_app"
  },
  "next_steps": [
    {
      "command": "cd my_app",
      "description": "Navigate to project directory"
    },
    {
      "command": "flutter run",
      "description": "Run the application"
    }
  ]
}
```

**Error Output:**

```json
{
  "success": false,
  "command": "create",
  "error": "Project name is required",
  "suggestion": "Provide a project name: fly create <project_name>"
}
```

---

## 6. Template System Deep Dive

### 6.1 Available Templates

#### Minimal Template

**Description**: Bare-bones Flutter structure for developers who want full control

**Features:**

- Basic project structure
- Minimal dependencies
- Clean slate for customization

**Use Cases:**

- Learning Flutter
- Prototyping
- Custom architecture implementation

**Structure:**

```
project_name/
├── lib/
│   └── main.dart
├── test/
│   └── widget_test.dart
├── pubspec.yaml
└── README.md
```

#### Riverpod Template

**Description**: Production-ready architecture with state management

**Features:**

- Riverpod state management
- GoRouter navigation
- Theming system
- Error handling
- Networking layer
- Clean architecture pattern

**Use Cases:**

- Production applications
- Team projects requiring structure
- Applications with complex state

**Structure:**

```
project_name/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── router/
│   │   └── theme/
│   └── features/
│       ├── home/
│       └── profile/
├── test/
│   └── widget_test.dart
├── pubspec.yaml
└── README.md
```

### 6.2 Template Customization

#### Template Variables

Each template supports configurable variables defined in `template.yaml`:

**Common Variables:**

- `project_name`: Name of the project (required)
- `organization`: Organization identifier (required, default: com.example)
- `platforms`: Target platforms (required, default: ["ios", "android"])
- `description`: Project description (optional)

**Variable Types:**

- `string`: Text values
- `list`: Array of values
- `boolean`: True/false values

#### Creating Custom Templates

**Step 1: Create Template Directory**

```bash
mkdir -p templates/my_template/__brick__
```

**Step 2: Create Template Metadata**

Create `templates/my_template/template.yaml`:

```yaml
name: my_template
version: 1.0.0
description: Custom template description
min_flutter_sdk: "3.10.0"
min_dart_sdk: "3.0.0"

variables:
  project_name:
    type: string
    required: true
    description: "Name of the project"
  organization:
    type: string
    required: true
    default: "com.example"
    description: "Organization identifier"
  platforms:
    type: list
    required: true
    default: [ "ios", "android" ]
    choices: [ "ios", "android", "web", "macos", "windows", "linux" ]
    description: "Target platforms"

features:
  - custom_feature

packages:
  - flutter
  # Add custom dependencies
```

**Step 3: Create Template Files**

Create files in `templates/my_template/__brick__/` using Mason variable syntax:

`{{project_name}}/lib/main.dart`:

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const {{project_name | pascalCase}}App());
}

class {{project_name|pascalCase}}App extends StatelessWidget {
const {{project_name|pascalCase}}App({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
title: '{{project_name}}',
theme: ThemeData(
colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
useMaterial3: true,
),
home: const {{project_name|pascalCase}}HomePage(),
);
}
}
```

### 6.3 Code Generation Process

#### Template Processing Flow

1. **Validation**: Validate template metadata and variables
2. **Resolution**: Resolve template variables from user input
3. **Generation**: Process template files with variable substitution
4. **Validation**: Validate generated code structure
5. **Security Scan**: Run security validation on generated code

#### Pre/Post Generation Hooks

Templates can include custom hooks:

**Pre-generation Hooks**:

- Validate platform availability
- Check package dependencies
- Verify SDK versions

**Post-generation Hooks**:

- Format generated code
- Run analysis
- Initialize git repository

### 6.4 Template Validation

#### Security Scanning

All templates are scanned for:

- Potential security vulnerabilities
- Dependency vulnerabilities
- Code injection risks
- Malicious code patterns

#### Structure Validation

Template structure is validated for:

- Required files (pubspec.yaml, main.dart)
- Directory structure consistency
- File naming conventions

---

## 7. AI Integration and Machine-Readable Interfaces

### 7.1 JSON Output Format

All commands support machine-readable JSON output via the `--output=json` flag.

#### Success Response Format

```json
{
  "success": true,
  "command": "command_name",
  "message": "Human-readable message",
  "data": {
    // Command-specific data
  },
  "next_steps": [
    {
      "command": "next_command",
      "description": "What to do next"
    }
  ]
}
```

#### Error Response Format

```json
{
  "success": false,
  "command": "command_name",
  "error": "Error message",
  "suggestion": "Suggested resolution",
  "code": "ERROR_CODE"
}
```

### 7.2 Declarative Manifests

#### Manifest Format

Create projects declaratively using `fly_project.yaml`:

```yaml
project:
  name: my_app
  organization: com.mycompany
  template: riverpod
  platforms:
    - ios
    - android
    - web

features:
  - authentication
  - data_persistence
  - analytics

dependencies:
  - firebase_auth
  - shared_preferences
  - firebase_analytics

configuration:
  min_sdk: 21
  target_sdk: 33
  compile_sdk: 33
```

#### Creating from Manifest

```bash
fly create my_app --from-manifest=fly_project.yaml
```

### 7.3 Schema Export

#### Export CLI Schema

```bash
fly schema export --file=schema.json
```

**Schema Contents:**

```json
{
  "cli_info": {
    "name": "fly",
    "version": "0.1.0",
    "description": "AI-native Flutter CLI tool",
    "homepage": "https://github.com/fly-cli/fly"
  },
  "commands": [
    {
      "name": "create",
      "description": "Create a new Flutter project",
      "arguments": [
        {
          "name": "project_name",
          "type": "string",
          "required": true,
          "description": "Name of the project"
        }
      ],
      "options": [
        {
          "name": "template",
          "short": "t",
          "type": "string",
          "default": "riverpod",
          "allowed": [
            "minimal",
            "riverpod"
          ],
          "description": "Project template to use"
        }
      ],
      "examples": [
        "fly create my_app",
        "fly create my_app --template=minimal"
      ]
    }
  ]
}
```

### 7.4 Context Export

#### Export Project Context

```bash
fly context-export --file=context.json --include-code --include-dependencies
```

**Context Contents:**

```json
{
  "project": {
    "name": "my_app",
    "type": "flutter",
    "template": "riverpod",
    "organization": "com.mycompany",
    "platforms": [
      "ios",
      "android",
      "web"
    ]
  },
  "structure": {
    "directories": [
      "lib/",
      "test/"
    ],
    "files": [
      "pubspec.yaml",
      "README.md"
    ]
  },
  "configuration": {
    "flutter_version": "3.10.0",
    "dart_version": "3.0.0",
    "min_sdk": 21,
    "target_sdk": 33
  },
  "dependencies": [
    {
      "name": "flutter",
      "version": "^3.10.0",
      "type": "sdk"
    }
  ],
  "code": {
    // Source code if --include-code is used
  }
}
```

### 7.5 AI Agent Scripts

#### Cursor Integration

Create `.cursor/rules/fly_cli.md`:

```markdown
# Fly CLI Integration

Use Fly CLI for Flutter project operations:

1. Create projects: `fly create <name> --template=riverpod --output=json`
2. Export context: `fly context-export --include-code --include-dependencies`
3. Check schema: `fly schema export`

Always use `--output=json` for machine-readable responses.
```

#### GitHub Copilot Integration

```python
# fly_agent.py
import subprocess
import json

def create_project(name, template='riverpod'):
    """Create a new Flutter project using Fly CLI"""
    result = subprocess.run(
        ['fly', 'create', name, '--template', template, '--output', 'json'],
        capture_output=True,
        text=True
    )
    return json.loads(result.stdout)

def export_context(include_code=False):
    """Export current project context"""
    args = ['fly', 'context-export']
    if include_code:
        args.append('--include-code')
    result = subprocess.run(args, capture_output=True, text=True)
    return json.loads(result.stdout)
```

#### ChatGPT Code Interpreter

```javascript
// fly_agent.js
const { execSync } = require('child_process');

function createProject(name, options = {}) {
  const cmd = [
    'fly', 'create', name,
    '--template', options.template || 'riverpod',
    '--output', 'json'
  ].join(' ');
  
  const output = execSync(cmd).toString();
  return JSON.parse(output);
}

function exportSchema() {
  const output = execSync('fly schema export').toString();
  return JSON.parse(output);
}

module.exports = { createProject, exportSchema };
```

### 7.6 Dry-Run Capabilities

Preview operations before execution:

```bash
# Preview project creation (if implemented)
fly create my_app --dry-run

# Preview component addition
fly add screen home --dry-run
```

---

## 8. Development Workflow and Best Practices

### 8.1 Local Development Process

#### Daily Workflow

```bash
# 1. Start development session
cd fly
melos bootstrap

# 2. Make changes to code

# 3. Run tests for changed packages
melos run test:changed

# 4. Run analysis
melos run analyze

# 5. Format code
melos run format

# 6. Commit changes
git add .
git commit -m "feat: description"
```

#### Pre-Commit Checklist

- [ ] All tests pass: `melos run test`
- [ ] Analysis passes: `melos run analyze`
- [ ] Code formatted: `melos run format`
- [ ] No linter errors
- [ ] Documentation updated
- [ ] Changelog updated (if needed)

### 8.2 Code Quality Standards

#### Analysis Configuration

`analysis_options.yaml` (root level):

```yaml
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/build/**"

  errors:
    invalid_annotation_target: ignore

linter:
  rules:
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - avoid_unnecessary_containers
    - sized_box_for_whitespace
```

#### Very Good Analysis Rules

Fly CLI uses Very Good Analysis for strict linting with additional rules for:

- **Prefer const constructors**: Reduces runtime object creation
- **Prefer const literals**: Immutable data structures for better performance
- **Avoid unnecessary containers**: Minimal widget tree depth
- **Sized box for whitespace**: Performance-optimized layout widgets

### 8.3 Testing Strategy

#### Test Categories

**Unit Tests**: Individual package functionality

```bash
# Run unit tests for a specific package
cd packages/fly_cli
dart test test/
```

**Integration Tests**: CLI command execution

```bash
# Run integration tests
dart test test/integration/
```

**E2E Tests**: Complete project creation workflows

```bash
# Run E2E tests
dart test test/e2e/integration_test.dart
```

**Performance Tests**: Creation speed and resource usage

```bash
# Run performance tests
dart test test/performance/performance_test.dart
```

**Memory Tests**: Leak detection and resource management

```bash
# Run memory tests
dart test test/memory/memory_test.dart
```

**Security Tests**: Template validation and sandboxing

```bash
# Run security tests
dart test test/security/security_test.dart
```

#### Test Execution

```bash
# Run all tests with coverage
melos run test --coverage

# Run tests for changed packages only
melos run test:changed

# Run specific test categories
dart test test/e2e/
dart test test/performance/
dart test test/security/

# Run with coverage report
melos run test && genhtml coverage/lcov.info -o coverage/html
```

### 8.4 Continuous Integration

#### GitHub Actions Workflow

```yaml
name: CI

on: [ push, pull_request ]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        os: [ ubuntu-latest, windows-latest, macos-latest ]
        sdk: [ '3.0.0' ]
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'
          channel: 'stable'
      - name: Install dependencies
        run: |
          dart pub global activate melos
          melos bootstrap
      - name: Run tests
        run: melos run test
      - name: Run analysis
        run: melos run analyze
      - name: Check formatting
        run: melos run format:check
```

---

## 9. Package Management and Dependencies

### 9.1 Monorepo Management

#### Melos Configuration

The `melos.yaml` file manages the monorepo structure and scripts:

```yaml
name: fly
repository: https://github.com/fly-cli/fly.git
packages:
  - packages/**
  - templates/**

command:
  bootstrap:
    runPubGetInParallel: true

scripts:
  bootstrap:
    run: melos bootstrap
  test:
    run: melos exec -- flutter test
  analyze:
    run: melos exec -- flutter analyze
  format:
    run: melos exec -- dart format --set-exit-if-changed .
```

#### Managing Dependencies

```bash
# Bootstrap all packages
melos bootstrap

# Get dependencies for all packages
melos run get

# Check for outdated dependencies
melos run outdated

# Clean all packages
melos run clean

# Run code generation
melos run build_runner
```

### 9.2 Version Constraints

#### Dependency Management

All packages specify compatible Dart and Flutter versions:

```yaml
environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.10.0"
```

#### Version Resolution Strategy

- **Exact versions** for critical dependencies (security, stability)
- **Range constraints** for minor updates (compatibility)
- **Compatible versions** across monorepo packages

### 9.3 License Compliance

#### License Checking

```bash
# Check license compatibility
melos run license:check

# Run license checker tool
dart run tools/license_checker.dart
```

#### MIT Compatibility Requirements

All dependencies must be MIT-compatible:

1. Review license files in each package
2. Check transitive dependencies for conflicts
3. Maintain attribution requirements
4. Document any exceptions

---

## 10. Testing and Quality Assurance

### 10.1 Test Categories and Execution

#### Unit Tests

Test individual functions and classes in isolation:

```dart
// test/fly_core_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlyCore', () {
    test('should create instance with default values', () {
      final core = FlyCore();
      expect(core.isInitialized, isFalse);
    });

    test('should initialize properly', () {
      final core = FlyCore();
      core.initialize();
      expect(core.isInitialized, isTrue);
    });
  });
}
```

#### Integration Tests

Test CLI command execution and interaction:

```dart
// test/integration/cli_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:process/process.dart';

void main() {
  group('CLI Integration', () {
    test('create command executes successfully', () async {
      final processManager = LocalProcessManager();
      final result = await processManager.run([
        'dart',
        'run',
        'packages/fly_cli/bin/fly.dart',
        'create',
        'test_project',
        '--output=json'
      ]);

      expect(result.exitCode, equals(0));
      expect(result.stdout, isNotEmpty);

      final output = json.decode(result.stdout as String);
      expect(output['success'], isTrue);
    });
  });
}
```

#### E2E Tests

Test complete project creation workflows:

```dart
// test/e2e/integration_test.dart
void main() {
  group('Project Creation E2E', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fly_e2e_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('creates minimal project successfully', () async {
      final projectPath = path.join(tempDir.path, 'minimal_project');

      // Execute creation command
      final result = await processManager.run([
        'dart',
        'run',
        'packages/fly_cli/bin/fly.dart',
        'create',
        projectPath,
        '--template=minimal',
        '--output=json'
      ], workingDirectory: tempDir.path);

      expect(result.exitCode, equals(0));

      // Verify project structure
      expect(Directory(projectPath).existsSync(), isTrue);
      expect(File(path.join(projectPath, 'pubspec.yaml')).existsSync(), isTrue);
      expect(File(path.join(projectPath, 'lib', 'main.dart')).existsSync(), isTrue);
    });
  });
}
```

### 10.2 Test Execution and Coverage

```bash
# Run all tests with coverage
melos run test --coverage

# Run tests for changed packages
melos run test:changed

# Run specific test suite
dart test test/e2e/integration_test.dart

# Run with verbose output
dart test --verbose

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

### 10.3 Performance Testing

#### Creation Speed Benchmarks

```dart
// test/performance/performance_test.dart
void main() {
  group('Performance Tests', () {
    test('project creation completes in < 30s', () async {
      final stopwatch = Stopwatch()
        ..start();

      await processManager.run([
        'dart',
        'run',
        'packages/fly_cli/bin/fly.dart',
        'create',
        'perf_test_project',
        '--template=minimal'
      ]);

      stopwatch.stop();

      expect(
          stopwatch.elapsedMilliseconds,
          lessThan(30000),
          reason: 'Project creation should complete in under 30 seconds'
      );
    });
  });
}
```

#### Memory Leak Detection

```dart
// test/memory/memory_test.dart
void main() {
  group('Memory Tests', () {
    test('no memory leaks in created projects', () async {
      // Create and analyze projects for memory leaks
      // Use Dart DevTools for memory profiling
    });
  });
}
```

---

## 11. Build and Deployment Process

### 11.1 Local Build Process

```bash
# Clean all packages
melos run clean

# Get dependencies
melos run get

# Run code generation
melos run build_runner

# Build examples
melos run build:examples

# Run analysis
melos run analyze
```

### 11.2 CI/CD Pipeline

#### GitHub Actions Workflow

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ ubuntu-latest, windows-latest, macos-latest ]
        sdk: [ '3.0.0' ]
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'
      - name: Install Melos
        run: dart pub global activate melos
      - name: Bootstrap packages
        run: melos bootstrap
      - name: Run tests
        run: melos run test
      - name: Run analysis
        run: melos run analyze
      - name: Check formatting
        run: melos run format:check

  publish:
    needs: test
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - name: Install Melos
        run: dart pub global activate melos
      - name: Bootstrap packages
        run: melos bootstrap
      - name: Publish packages
        run: melos publish
        env:
          CREDENTIAL_JSON: ${{ secrets.CREDENTIAL_JSON }}
```

### 11.3 Package Publishing Process

```bash
# Version bump
melos version

# Dry-run publish
melos publish:dry-run

# Publish packages (requires credentials)
melos publish
```

### 11.4 Documentation Generation

```bash
# Generate API documentation
dart doc

# View documentation
open doc/api/index.html
```

---

## 12. Troubleshooting and Common Issues

### 12.1 Installation Issues

#### Dependency Conflicts

**Problem**: Package dependency conflicts during installation

**Solution**:

```bash
# Clean all packages
melos run clean

# Remove pub cache
rm -rf ~/.pub-cache

# Reinstall dependencies
melos bootstrap
```

#### Platform-Specific Installation Problems

**macOS**: Xcode Command Line Tools

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Verify Flutter installation
flutter doctor -v
```

**Linux**: Required dependencies

```bash
# Install required packages (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y libc6-dev libgconf-2-4

# Verify installation
flutter doctor -v
```

**Windows**: Visual Studio Build Tools

```bash
# Install Visual Studio Build Tools
# Download from: https://visualstudio.microsoft.com/

# Verify installation
flutter doctor -v
```

### 12.2 Template Generation Errors

#### File Permission Issues

**Problem**: Cannot write to template directory

**Solution**:

```bash
# Check permissions
ls -la templates/

# Fix permissions
chmod -R 755 templates/
```

#### Template Validation Failures

**Problem**: Template validation fails during generation

**Solution**:

```bash
# Run security scan
melos run security:scan

# Check template syntax
yaml lint templates/*/template.yaml

# Validate template structure
fly validate template_name
```

### 12.3 AI Integration Problems

#### JSON Parsing Errors

**Problem**: Invalid JSON output from commands

**Solution**:

```bash
# Test JSON output
fly create test_project --output=json | jq .

# Check for verbose errors
fly create test_project --output=json --verbose
```

#### Schema Compatibility Issues

**Problem**: AI tool cannot parse schema

**Solution**:

```bash
# Export fresh schema
fly schema export --file=schema.json

# Verify schema structure
jq . schema.json

# Include examples in export
fly schema export --include-examples
```

### 12.4 Performance Issues

#### Slow Project Creation

**Problem**: Project creation takes too long (> 30s)

**Solutions**:

- Check network connectivity for template downloads
- Clear template cache: `fly cache clear`
- Reduce template size and complexity
- Optimize file I/O operations
- Use offline mode: `fly create --offline`

#### Memory Usage Problems

**Problem**: High memory usage during creation

**Solutions**:

- Monitor with Flutter DevTools
- Check for memory leaks in tests
- Optimize template file sizes
- Limit concurrent operations
- Use streaming for large file operations

### 12.5 Debugging Techniques

#### Verbose Logging

```bash
# Enable verbose output
fly create project_name --verbose

# Save logs to file
fly create project_name --verbose --log-file=debug.log
```

#### Dry-Run Mode

```bash
# Preview operations without executing
fly create project_name --dry-run

# Check what would be created
fly create project_name --dry-run --output=json
```

#### Error Reporting

```bash
# Collect diagnostic information
fly doctor --output=json > diagnostics.json

# Include version info
fly version --verbose
```

---

## 13. Advanced Features and Customization

### 13.1 Custom Template Development

#### Creating a New Template

1. **Create template directory structure**:

```bash
mkdir -p templates/my_template/__brick__/{lib,test}
```

2. **Define template metadata** (`template.yaml`):

```yaml
name: my_template
version: 1.0.0
description: Custom template for specific needs
min_flutter_sdk: "3.10.0"
min_dart_sdk: "3.0.0"

variables:
  project_name:
    type: string
    required: true
    description: "Project name"

features:
  - my_custom_feature

packages:
  - flutter
  - my_custom_package
```

3. **Create template files** using Mason variable syntax:

```dart
// {{project_name}}/lib/main.dart
import 'package:flutter/material.dart';

void main() {
  runApp(const {{project_name | pascalCase}}App());
}

class {{project_name|pascalCase}}App extends StatelessWidget {
const {{project_name|pascalCase}}App({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
title: '{{project_name}}',
theme: ThemeData(useMaterial3: true),
home: const {{project_name|pascalCase}}HomePage(),
);
}
}
```

4. **Test the template**:

```bash
# Generate test project
fly create test_project --template=my_template

# Verify output
cd test_project && flutter analyze
```

### 13.2 Plugin System

#### Creating Custom Commands

Create a custom command plugin:

```dart
// plugins/custom_command.dart
import 'package:fly_cli/src/commands/fly_command.dart';

class CustomCommand extends FlyCommand {
  @override
  String get name => 'custom';

  @override
  String get description => 'Custom command for specific functionality';

  @override
  Future<CommandResult> execute() async {
    logger.info('Executing custom command...');

    // Custom command logic

    return CommandResult.success(
      command: 'custom',
      message: 'Custom command executed successfully',
      data: {'result': 'success'},
    );
  }
}
```

#### Registering Custom Commands

```dart
// Add to command runner
class FlyCommandRunner extends CommandRunner<void> {
  FlyCommandRunner() : super('fly', 'AI-native Flutter CLI') {
    addCommand(CustomCommand());
  }
}
```

### 13.3 Offline Mode

#### Template Caching

```bash
# Cache templates locally
fly cache templates

# List cached templates
fly cache list

# Clear cache
fly cache clear

# Check cache status
fly cache status
```

#### Network Resilience

```bash
# Use offline mode
fly create project_name --offline

# Fallback to cached templates
fly create project_name --offline --cache-fallback
```

---

## 14. Security and Compliance

### 14.1 Template Validation

#### Security Scanning

All templates are automatically scanned for:

- **Code injection vulnerabilities**: SQL injection, command injection
- **Dependency vulnerabilities**: Known CVEs in dependencies
- **Malicious patterns**: Suspicious code patterns
- **Hardcoded secrets**: API keys, passwords, tokens

```bash
# Run security validation
melos run security:scan

# Scan specific template
fly security scan template_name
```

#### Template Structure Validation

Templates are validated for:

- Required files present (pubspec.yaml, main.dart)
- Directory structure consistency
- File naming conventions
- YAML syntax correctness
- Variable type validation

### 14.2 Dependency Security

#### Vulnerability Assessment

```bash
# Check for known vulnerabilities
dart pub outdated

# Audit dependencies
dart pub global activate pana
pana --json
```

#### Dependency Updates

```bash
# Check outdated dependencies
melos run outdated

# Update dependencies
melos exec -- flutter pub upgrade

# Verify after update
melos run test
```

### 14.3 License Compliance

#### License Checking

```bash
# Check all package licenses
melos run license:check

# View detailed license report
dart run tools/license_checker.dart --detailed

# Export license summary
dart run tools/license_checker.dart --output=licenses.txt
```

#### MIT Compatibility

All dependencies must be MIT-compatible:

- **Allowed**: MIT, Apache 2.0, BSD variants, ISC
- **Restricted**: GPL, LGPL, proprietary licenses
- **Documentation**: All license exceptions documented

### 14.4 Sandboxing

#### Safe Template Execution

Templates are executed in a sandboxed environment:

- **File system isolation**: Limited write access
- **Network restrictions**: Controlled network access
- **Resource limits**: Memory and CPU constraints
- **Process isolation**: Separate execution context

---

## 15. Performance Optimization

### 15.1 Creation Speed

#### Optimization Techniques

1. **Template Pre-compilation**: Pre-compile templates to reduce generation time
2. **Parallel Processing**: Generate multiple files concurrently
3. **Caching Strategy**: Cache frequently used template components
4. **File System Optimization**: Use efficient file I/O operations
5. **Resource Pooling**: Reuse resources across generations

#### Benchmarking

```bash
# Run performance benchmarks
dart test test/performance/performance_test.dart

# Profile creation process
flutter --profile create_project

# Measure specific operations
fly create benchmark_test --timing
```

### 15.2 Memory Management

#### Efficient Resource Usage

- **Stream-based I/O**: Process large files in streams
- **Memory pooling**: Reuse memory buffers
- **Lazy loading**: Load resources on-demand
- **Garbage collection tuning**: Optimize GC for creation workloads

#### Leak Detection

```dart
// test/memory/memory_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no memory leaks in repeated project creation', () async {
    // Create multiple projects and check for leaks
    for (int i = 0; i < 10; i++) {
      await createProject('test_$i');
    }

    // Force garbage collection
    // Verify memory doesn't grow unbounded
  });
}
```

### 15.3 Caching Strategy

#### Template Caching

```bash
# Cache templates locally
fly cache templates

# View cache statistics
fly cache stats

# Invalidate cache
fly cache invalidate

# Pre-populate cache
fly cache preload
```

#### Dependency Caching

- **Pub cache**: Leverage Dart's pub cache
- **Template dependency cache**: Cache resolved dependencies
- **Network cache**: Cache network downloads

---

## 16. Integration with Development Tools

### 16.1 IDE Integration

#### VS Code

**Setup**:

1. Install Dart and Flutter extensions
2. Configure analysis server
3. Enable IntelliSense

**Configuration** (`.vscode/settings.json`):

```json
{
  "dart.analysisExcludedFolders": [
    "build/**",
    "**/*.g.dart",
    "**/*.freezed.dart"
  ],
  "dart.enableSnippets": true,
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "Dart-Code.dart-code"
}
```

#### Cursor

**AI Integration Configuration** (`.cursor/rules/fly_cli.md`):

```markdown
# Fly CLI Integration

Use Fly CLI for Flutter project operations:

## Commands

- Create project: `fly create <name> --template=riverpod --output=json`
- Export context: `fly context-export --include-code --include-dependencies`
- Export schema: `fly schema export`
- Check diagnostics: `fly doctor`

## Best Practices

- Always use `--output=json` for machine-readable responses
- Export context before making significant changes
- Run `fly doctor` when troubleshooting issues
```

#### IntelliJ IDEA / Android Studio

- Flutter plugin provides full IDE support
- Integrated debugging and testing
- Built-in code analysis and refactoring
- Hot reload support

### 16.2 Version Control Integration

#### Git Hooks

**Pre-commit Hook** (`.git/hooks/pre-commit`):

```bash
#!/bin/bash
# Run analysis before commit
melos run analyze
if [ $? -ne 0 ]; then
  echo "Analysis failed. Please fix issues before committing."
  exit 1
fi

# Format code
melos run format

# Run tests
melos run test:changed
```

**Setup**:

```bash
chmod +x .git/hooks/pre-commit
```

#### Git Workflow

```bash
# Create feature branch
git checkout -b feature/your-feature

# Make changes and commit
git add .
git commit -m "feat: add your feature"

# Push and create PR
git push origin feature/your-feature
```

### 16.3 CI/CD Integration

#### GitHub Actions

See [CI/CD Pipeline](#11-2-cicd-pipeline) for complete workflow.

#### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - test
  - build
  - deploy

test:
  stage: test
  image: cirrusci/flutter:stable
  script:
    - dart pub global activate melos
    - melos bootstrap
    - melos run test
    - melos run analyze

build:
  stage: build
  image: cirrusci/flutter:stable
  script:
    - melos run build:examples
  only:
    - tags

deploy:
  stage: deploy
  script:
    - melos publish
  only:
    - main
```

### 16.4 Monitoring and Analytics

#### Usage Tracking

```bash
# Enable usage tracking
fly config set analytics.enabled true

# View usage statistics
fly stats

# Export analytics data
fly stats export --format=json
```

#### Performance Monitoring

- Track creation times
- Monitor resource usage
- Alert on performance degradation
- Analyze bottleneck operations

---

## 17. Community and Contribution Guidelines

### 17.1 Contributing Process

#### Getting Started

1. **Fork the repository**: Create your own fork on GitHub
2. **Clone locally**: `git clone https://github.com/YOUR_USERNAME/fly.git`
3. **Set up upstream**: `git remote add upstream https://github.com/fly-cli/fly.git`
4. **Create branch**: `git checkout -b feature/your-feature`

#### Development Workflow

```bash
# Keep your fork updated
git fetch upstream
git checkout main
git merge upstream/main

# Create feature branch
git checkout -b feature/your-feature

# Make changes and test
melos run test
melos run analyze

# Commit changes
git add .
git commit -m "feat: add your feature"

# Push and create PR
git push origin feature/your-feature
```

#### Pull Request Process

1. **Create descriptive PR**: Clear title and description
2. **Link issues**: Reference related issues
3. **Add tests**: Include tests for new features
4. **Update docs**: Keep documentation current
5. **Get reviews**: Address reviewer feedback
6. **Merge**: Squash and merge when approved

### 17.2 Code Standards

#### Style Guide

- Follow [Very Good Analysis rules](#8-2-code-quality-standards)
- Use [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Maintain consistent formatting with `dart format`
- Write self-documenting code with clear names

#### Code Review Checklist

- [ ] Code follows style guide
- [ ] Tests added and passing
- [ ] Documentation updated
- [ ] No linter errors
- [ ] Security considerations addressed
- [ ] Performance implications considered

### 17.3 Documentation Standards

#### Writing Guidelines

- Use clear, concise language
- Include code examples
- Provide context and rationale
- Link to related documentation
- Keep examples up-to-date

#### Documentation Structure

```
docs/
├── guide/              # User guides
├── technical/          # Technical documentation
├── ai/                 # AI integration docs
├── reference/          # API reference
└── planning/           # Roadmaps and plans
```

### 17.4 Release Process

#### Version Management

1. **Update version**: Bump version in `pubspec.yaml`
2. **Update CHANGELOG**: Document changes
3. **Create release notes**: Summarize features and fixes
4. **Tag release**: Create git tag
5. **Publish packages**: Publish to pub.dev
6. **Announce release**: Notify community

#### Semantic Versioning

- **Major** (1.0.0): Breaking changes
- **Minor** (0.1.0): New features, backwards compatible
- **Patch** (0.0.1): Bug fixes, backwards compatible

### 17.5 Community Support

#### Getting Help

- **Documentation**: Check docs first
- **GitHub Issues**: Report bugs and request features
- **Discussions**: Ask questions and share ideas
- **Discord**: Real-time community chat

#### Reporting Issues

Include:

- Fly CLI version
- Operating system
- Steps to reproduce
- Expected vs actual behavior
- Error messages/logs

---

## 18. Future Roadmap and Extensibility

### 18.1 Phase 1 MVP

#### Planned Features (Q1 2024)

- **Additional Templates**: MVVM, Clean Architecture, BLoC patterns
- **Enhanced AI Integration**: Improved schema, context capabilities
- **Plugin System**: Extensible command architecture
- **Enterprise Features**: Team templates, custom configurations
- **Offline Mode**: Full offline capability
- **Performance**: < 20s project creation

### 18.2 Long-term Vision

#### Advanced AI Capabilities (2024)

- Natural language project specification
- Intelligent code suggestions
- Automated refactoring recommendations
- AI-powered debugging assistance

#### Cloud Integration (2025)

- Template marketplace
- Cloud-based project templates
- Collaborative development features
- Remote project management

#### Enterprise Features (2025+)

- Team collaboration tools
- Centralized configuration management
- Advanced security features
- Audit and compliance reporting

### 18.3 Extension Points

#### Plugin Architecture

- **Command Plugins**: Custom commands
- **Template Plugins**: Community templates
- **Validation Plugins**: Custom validation rules
- **Integration Plugins**: External tool integration

#### API Evolution

- Backward compatibility guarantees
- Versioned APIs
- Migration guides
- Deprecation policies

#### Template Marketplace

- Community-contributed templates
- Template ratings and reviews
- Template monetization
- Template curation

### 18.4 Migration Strategy

#### From Other CLI Tools

- **Very Good CLI**: Migration guide and tools
- **Flutter CLI**: Command mapping and migration
- **GetX CLI**: Template conversion utilities

#### Version Upgrades

- Automated migration tools
- Changelog-based upgrades
- Breaking change notifications
- Rollback capabilities

---

## Appendix

### A. Command Reference

Complete alphabetical command reference with all options and examples.

### B. Template Reference

Complete template specification, variable reference, and customization guide.

### C. API Reference

Code-level documentation for all packages (fly_cli, fly_core, fly_networking, fly_state).

### D. Troubleshooting Guide

Comprehensive troubleshooting guide with solutions for common issues.

### E. Migration Guides

Step-by-step guides for migrating from other CLI tools.

### F. Glossary

Definitions of key terms and concepts used throughout the documentation.

---

## Document Information

**Version**: 1.0.0  
**Last Updated**: December 2024  
**Status**: Phase 0 - Critical Foundation  
**Next Update**: After Phase 0 completion

---

**End of Technical Lifecycle Documentation**
