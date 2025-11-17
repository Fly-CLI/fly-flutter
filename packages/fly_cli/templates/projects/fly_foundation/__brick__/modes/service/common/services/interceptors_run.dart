{{#supports_interceptors}}
Future<AppResult<Map<String, dynamic>>> runInterceptors(
  List<ServiceInterceptor<Map<String, dynamic>>> interceptors,
  Future<AppResult<Map<String, dynamic>>> Function() action,
) {
  Future<AppResult<Map<String, dynamic>>> next(int index) {
    if (index >= interceptors.length) {
      return action();
    }
    final interceptor = interceptors[index];
    return interceptor(() => next(index + 1));
  }
  return next(0);
}
{{/supports_interceptors}}


