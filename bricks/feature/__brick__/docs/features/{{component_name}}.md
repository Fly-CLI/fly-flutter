# {{component_name.pascalCase()}} Feature

This document describes the {{component_name.pascalCase()}} feature module.

## Overview

The {{component_name.pascalCase()}} feature is a {{#is_list_screen}}list{{/is_list_screen}}{{#is_detail_screen}}detail{{/is_detail_screen}}{{#is_form_screen}}form{{/is_form_screen}} screen implementation.

## Components

### Screen

- **{{component_name.pascalCase()}}Screen**: {{#is_list_screen}}List{{/is_list_screen}}{{#is_detail_screen}}Detail{{/is_detail_screen}}{{#is_form_screen}}Form{{/is_form_screen}} screen implementation
{{#with_viewmodel}}
  - Extends `BaseScreen` for consistent behavior
  - Uses `{{component_name.pascalCase()}}ViewModel` for state management
{{/with_viewmodel}}
{{^with_viewmodel}}
  - Standalone screen without view model
{{/with_viewmodel}}

{{#with_viewmodel}}
### View Model

- **{{component_name.pascalCase()}}ViewModel**: State management for {{component_name.pascalCase()}} screen
  - Extends `BaseViewModel`
  - Manages loading, error, and data states
{{/with_viewmodel}}

## State Management

{{#use_riverpod}}
This feature uses **Riverpod** for state management with `NotifierProvider`.
{{/use_riverpod}}
{{#use_bloc}}
This feature uses **BLoC** for state management.
{{/use_bloc}}
{{#use_cubit}}
This feature uses **Cubit** for state management.
{{/use_cubit}}

## Validation

{{#requires_validation}}
This feature includes form validation logic.
{{/requires_validation}}
{{^requires_validation}}
Form validation is not enabled for this feature.
{{/requires_validation}}

## Navigation

{{#with_navigation}}
Navigation support is enabled for this feature.
{{/with_navigation}}
{{^with_navigation}}
Navigation support is disabled for this feature.
{{/with_navigation}}

