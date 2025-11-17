import 'package:fly_flow_guard/fly_flow_guard.dart';

{{> modes/service/common/services/interceptors_types.dart }}
{{> modes/service/common/services/interceptors_run.dart }}

class {{component_name.pascalCase()}}Service {
  {{component_name.pascalCase()}}Service({
{{#is_api_service}}
    this.baseUrl = '{{api_base_url}}',
{{/is_api_service}}
{{#supports_retry}}
    RetryConfig retryConfig = const RetryConfig.standard(),
{{/supports_retry}}
{{#supports_interceptors}}
    List<ServiceInterceptor<Map<String, dynamic>>> interceptors = const [],
{{/supports_interceptors}}
  }){{#is_api_service}}{{#supports_retry}}
      : _retryConfig = retryConfig{{#supports_interceptors}},{{/supports_interceptors}}{{/supports_retry}}{{#supports_interceptors}}{{^supports_retry}}:{{/supports_retry}} _interceptors = interceptors{{/supports_interceptors}}{{/is_api_service}}{{^is_api_service}}{{#supports_retry}}
      : _retryConfig = retryConfig{{#supports_interceptors}},{{/supports_interceptors}}{{/supports_retry}}{{#supports_interceptors}}{{^supports_retry}}:{{/supports_retry}} _interceptors = interceptors{{/supports_interceptors}}{{/is_api_service}};

{{#is_api_service}}
  final String baseUrl;
{{/is_api_service}}
{{#supports_retry}}
  final RetryConfig _retryConfig;
{{/supports_retry}}
{{#supports_interceptors}}
  final List<ServiceInterceptor<Map<String, dynamic>>> _interceptors;
{{/supports_interceptors}}
{{> modes/service/common/services/caching_field.dart }}

  /// Example endpoint demonstrating {{#is_api_service}}API{{/is_api_service}}{{#is_local_service}}local{{/is_local_service}}{{#is_cache_service}}cache{{/is_cache_service}}{{#is_analytics_service}}analytics{{/is_analytics_service}}{{#is_storage_service}}storage{{/is_storage_service}} service scaffolding.
  Future<AppResult<Map<String, dynamic>>> fetchSummary() async {
{{> modes/service/common/services/caching_get.dart }}

    Future<AppResult<Map<String, dynamic>>> action() async {
      try {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return AppResult.success({
          'feature': '{{feature}}',
          'service': '{{component_name}}',
{{#is_api_service}}
          'endpoint': '$baseUrl/{{component_name.snakeCase()}}/summary',
{{/is_api_service}}
{{^is_api_service}}
          'type': '{{#is_local_service}}local{{/is_local_service}}{{#is_cache_service}}cache{{/is_cache_service}}{{#is_analytics_service}}analytics{{/is_analytics_service}}{{#is_storage_service}}storage{{/is_storage_service}}',
{{/is_api_service}}
        });
      } catch (error) {
        return AppResult.failure('Failed to fetch {{component_name}} summary', error);
      }
    }

{{#supports_interceptors}}
    final result = await _execute(
      action: () => runInterceptors(_interceptors, action),
    );
{{/supports_interceptors}}
{{^supports_interceptors}}
    final result = await _execute(action: action);
{{/supports_interceptors}}

{{> modes/service/common/services/caching_set.dart }}
    return result;
  }

  Future<AppResult<Map<String, dynamic>>> _execute({
    required Future<AppResult<Map<String, dynamic>>> Function() action,
  }) async {
{{> modes/service/common/services/retry_execute.dart }}
  }
}

