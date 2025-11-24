# {{project_name.pascalCase()}} Architecture

This document describes the architecture of the {{project_name.pascalCase()}} application generated using the Fly Foundation template.

## Overview

{{description}}

## Platform Support

{{#supports_ios}}
- **iOS**: Fully supported
{{/supports_ios}}
{{#supports_android}}
- **Android**: Fully supported
{{/supports_android}}
{{#supports_web}}
- **Web**: Fully supported
{{/supports_web}}
{{#supports_desktop}}
- **Desktop** (macOS, Windows, Linux): Supported
{{/supports_desktop}}

## Core Architecture

### Foundation Layer

The application is built on the Fly Foundation, which provides:

- **BaseScreen/BaseViewModel**: MVVM pattern implementation
- **Navigation**: Enum-backed routing with `FeatureScreen` and `AppRouteConfig`
- **State Management**: {{#use_riverpod}}Riverpod 3 with `NotifierProvider`{{/use_riverpod}}{{^use_riverpod}}State management configured via preset{{/use_riverpod}}
- **Services**: Service layer with support for retry, caching, and interceptors

### Fly Packages

The following Fly packages are included:

{{#fly_packages}}
- `{{.}}`: Core Fly Foundation package
{{/fly_packages}}

## Project Structure

```
lib/
├── core/
│   ├── foundation/     # BaseScreen, BaseViewModel
│   └── services/       # Service layer implementations
├── features/           # Feature modules
│   └── {{feature}}/
│       └── presentation/
│           ├── models/
│           ├── screen/
│           └── widgets/
├── l10n/              # Localization files
└── shared/
    ├── navigation/    # AppRouter, AppNavigator
    └── themes/        # AppTheme
```

## Code Generation

{{#code_generation}}
Code generation is enabled with the following builders:

- `riverpod_generator`: Riverpod code generation
- `drift_dev`: Database code generation
- `auto_mappr`: Mapping code generation
- `json_serializable`: JSON serialization

Run code generation with:
```bash
dart run build_runner build --delete-conflicting-outputs
```
{{/code_generation}}
{{^code_generation}}
Code generation is disabled in this preset.
{{/code_generation}}

## Testing

{{#with_tests}}
Tests are included and can be run with:
```bash
flutter test
```
{{/with_tests}}
{{^with_tests}}
Tests are disabled in this preset.
{{/with_tests}}

## AI Integration

{{#ai_integration}}
AI integration is enabled. See `.ai/project_context.md` for project context.
{{/ai_integration}}
{{^ai_integration}}
AI integration is disabled in this preset.
{{/ai_integration}}

## MCP Integration

{{#with_mcp}}
MCP (Model Context Protocol) integration is enabled. See `.mcp/` directory for configuration.
{{/with_mcp}}
{{^with_mcp}}
MCP integration is disabled in this preset.
{{/with_mcp}}

