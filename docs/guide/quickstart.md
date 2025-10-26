# Quickstart

Get up and running with Fly CLI in under 5 minutes. This guide will walk you through creating your first Flutter project with AI-native features.

## Prerequisites

- Fly CLI [installed](/guide/installation)
- Flutter SDK 3.10.0+
- Dart SDK 3.0.0+

## Create Your First Project

### 1. Choose a Template

Fly CLI offers two production-ready templates:

- **`minimal`**: Clean, simple structure for learning and prototyping
- **`riverpod`**: Production-ready with state management, routing, and networking

### 2. Create the Project

```bash
# Create a minimal project
fly create my_app --template=minimal

# Or create a Riverpod project
fly create my_app --template=riverpod
```

### 3. Navigate and Run

```bash
# Navigate to your project
cd my_app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## Add Components

### Add a New Screen

```bash
# Add a screen to the home feature
fly add screen profile --feature=home

# Add a screen with ViewModel and tests
fly add screen settings --feature=home --with-viewmodel=true --with-tests=true
```

### Add a New Service

```bash
# Add an API service
fly add service user_api --feature=core --type=api --base-url=https://api.example.com

# Add a service with tests and mocks
fly add service auth_service --feature=auth --type=api --with-tests=true --with-mocks=true
```

## AI Integration

### Export Project Context

Generate a project context file for AI coding assistants:

```bash
# Export basic context
fly context export

# Export with all details
fly context export --include-dependencies=true --include-structure=true --include-conventions=true
```

This creates `.ai/project_context.md` with:
- Project structure overview
- Available commands and patterns
- Architecture conventions
- Dependency information

### Use JSON Output

All commands support machine-readable JSON output:

```bash
# Get JSON output for project creation
fly create my_app --template=riverpod --output=json

# Get JSON output for adding components
fly add screen home --feature=auth --output=json
```

### Plan Mode

Preview what will be created without actually creating files:

```bash
# Preview project creation
fly create my_app --template=riverpod --plan

# Preview component addition
fly add screen home --feature=auth --plan
```

## Explore Your Project

### Minimal Template Structure

```
my_app/
├── lib/
│   ├── main.dart
│   └── widgets/
├── test/
│   └── widget_test.dart
├── pubspec.yaml
└── README.md
```

### Riverpod Template Structure

```
my_app/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── router/
│   │   └── theme/
│   ├── features/
│   │   ├── home/
│   │   │   ├── presentation/
│   │   │   └── providers/
│   │   └── profile/
│   │       ├── presentation/
│   │       └── providers/
│   └── shared/
├── test/
├── pubspec.yaml
└── README.md
```

## Next Steps

### 1. Explore Templates

Learn more about the available templates:
- **[Minimal Template](/guide/templates#minimal)** - Simple structure
- **[Riverpod Template](/guide/templates#riverpod)** - Production-ready

### 2. Master Commands

Discover all available commands:
- **[Commands Reference](/guide/commands)** - Complete command documentation

### 3. AI Integration

Set up AI coding assistant integration:
- **[AI Integration Guide](/ai-integration/overview)** - Complete AI setup
- **[JSON Schemas](/ai-integration/json-schemas)** - Machine-readable output
- **[AI Agents](/ai-integration/agents)** - Integration scripts

### 4. Migration

Migrate from other CLI tools:
- **[From Very Good CLI](/migration/very-good-cli)**
- **[From Stacked CLI](/migration/stacked-cli)**
- **[From Vanilla Flutter](/migration/vanilla-flutter)**

## Troubleshooting

### Common Issues

**Project creation fails:**
```bash
# Check Flutter installation
flutter doctor

# Verify Fly CLI installation
fly doctor
```

**Dependencies not found:**
```bash
# Clean and get dependencies
flutter clean
flutter pub get
```

**AI context not generated:**
```bash
# Check if .ai directory exists
ls -la .ai/

# Regenerate context
fly context export --output=.ai/project_context.md
```

### Get Help

- **GitHub Issues**: [Report bugs](https://github.com/fly-cli/fly/issues)
- **Discord**: [Join community](https://discord.gg/fly-cli)
- **Documentation**: [Browse docs](/)

## What's Next?

Now that you've created your first project, explore the advanced features:

1. **[AI Integration](/ai-integration/overview)** - Set up AI coding assistants
2. **[Templates](/guide/templates)** - Learn about template customization
3. **[Commands](/guide/commands)** - Master all CLI commands
4. **[Examples](/examples/minimal-example)** - See real-world examples
