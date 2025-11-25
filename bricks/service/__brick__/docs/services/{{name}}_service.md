# {{name.pascalCase()}}Service

This document describes the {{name.pascalCase()}}Service implementation.

## Overview

The {{name.pascalCase()}}Service is a {{#is_api_service}}API{{/is_api_service}}{{#is_local_service}}local{{/is_local_service}}{{#is_cache_service}}cache{{/is_cache_service}}{{#is_analytics_service}}analytics{{/is_analytics_service}}{{#is_storage_service}}storage{{/is_storage_service}} service that provides data access functionality.

## Service Type

{{#is_api_service}}
This is an **API service** that communicates with remote endpoints.
{{#api_base_url}}
- Base URL: `{{api_base_url}}`
{{/api_base_url}}
{{/is_api_service}}
{{#is_local_service}}
This is a **local service** that handles local data operations.
{{/is_local_service}}
{{#is_cache_service}}
This is a **cache service** that manages cached data.
{{/is_cache_service}}
{{#is_analytics_service}}
This is an **analytics service** that tracks application events.
{{/is_analytics_service}}
{{#is_storage_service}}
This is a **storage service** that manages persistent storage.
{{/is_storage_service}}

## Capabilities

{{#supports_retry}}
- **Retry Logic**: Enabled - Automatic retry on failures
{{/supports_retry}}
{{#supports_caching}}
- **Caching**: Enabled - Response caching for improved performance
{{/supports_caching}}
{{#supports_interceptors}}
- **Interceptors**: Enabled - Request/response interception chain
{{/supports_interceptors}}
{{#generate_mocks}}
- **Mock Generation**: Enabled - Mock service available for testing
{{/generate_mocks}}

## Methods

### `fetchSummary()`

Fetches summary data from the service.

Returns: `AppResult<Map<String, dynamic>>`

## Testing

{{#with_tests}}
Tests are available in `test/core/services/{{feature}}/{{name}}_service_test.dart`.
{{/with_tests}}
{{#generate_mocks}}
Mock implementation is available in `test/core/services/{{feature}}/mocks/{{name}}_service_mock.dart`.
{{/generate_mocks}}

