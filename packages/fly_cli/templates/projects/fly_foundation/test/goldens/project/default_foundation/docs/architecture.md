# AcmeApp Architecture

This document describes the architecture of the AcmeApp application generated using the Fly Foundation template.

## Overview

Default Fly foundation project

## Platform Support






## Core Architecture

### Foundation Layer

The application is built on the Fly Foundation, which provides:

- **BaseScreen/BaseViewModel**: MVVM pattern implementation
- **Navigation**: Enum-backed routing with `FeatureScreen` and `AppRouteConfig`
- **State Management**: State management configured via preset
- **Services**: Service layer with support for retry, caching, and interceptors

### Fly Packages

The following Fly packages are included:


- `fly_core`: Core Fly Foundation package

- `fly_mvvm`: Core Fly Foundation package

- `fly_state`: Core Fly Foundation package

- `fly_navigation`: Core Fly Foundation package

- `fly_flow_guard`: Core Fly Foundation package

- `fly_logger`: Core Fly Foundation package

- `fly_events`: Core Fly Foundation package

- `fly_networking`: Core Fly Foundation package


## Project Structure

```
lib/
├── core/
│   ├── foundation/     # BaseScreen, BaseViewModel
│   └── services/       # Service layer implementations
├── features/           # Feature modules
│   └── home/
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



Code generation is disabled in this preset.


## Testing



Tests are disabled in this preset.


## AI Integration



AI integration is disabled in this preset.


## MCP Integration



MCP integration is disabled in this preset.


