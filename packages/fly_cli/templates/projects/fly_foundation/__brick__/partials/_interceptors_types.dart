{{#supports_interceptors}}
typedef ServiceInterceptor<T> = Future<AppResult<T>> Function(
  Future<AppResult<T>> Function(),
);
{{/supports_interceptors}}

