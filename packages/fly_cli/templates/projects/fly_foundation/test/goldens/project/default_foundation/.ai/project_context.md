# AcmeApp Project Context

This document provides context about the AcmeApp project for AI-assisted development.

## Project Overview

**Name**: AcmeApp
**Description**: Default Fly foundation project
**Organization**: com.example

## Platform Support








## Architecture

### Foundation

- **MVVM Pattern**: BaseScreen/BaseViewModel from `fly_mvvm`
- **State Management**: Configured via preset
- **Navigation**: Enum-backed routing with `FeatureScreen`

### Fly Packages


- `fly_core`

- `fly_mvvm`

- `fly_state`

- `fly_navigation`

- `fly_flow_guard`

- `fly_logger`

- `fly_events`

- `fly_networking`


## Code Generation



## Features



## Development Guidelines

1. Follow the MVVM pattern with BaseScreen/BaseViewModel
2. Use Riverpod for state management (when enabled)
3. Maintain accessibility with Semantics widgets
4. Follow the established navigation patterns
5. Write tests for all new features (when tests are enabled)

