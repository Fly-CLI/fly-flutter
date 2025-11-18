# Home Feature

This document describes the Home feature module.

## Overview

The Home feature provides the main screen and functionality for the application.

## Components

### Screen

- **HomeScreen**: Main screen implementation
  - Extends `BaseScreen` for consistent behavior
  - Uses `HomeViewModel` for state management

### View Model

- **HomeViewModel**: State management for Home screen
  - Extends `BaseViewModel`
  - Manages loading, error, and data states

## State Management



State management is configured via preset.


## Navigation

The feature is accessible via the route `/home` and is registered in `AppRouteConfig`.

