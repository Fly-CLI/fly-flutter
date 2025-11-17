{{#supports_retry}}
var attempt = 0;
while (true) {
  final result = await action();
  if (!result.isFailure || attempt >= _retryConfig.maxAttempts) {
    return result;
  }
  final delay = _retryConfig.calculateDelay(attempt);
  await Future<void>.delayed(delay);
  attempt++;
}
{{/supports_retry}}
{{^supports_retry}}
return action();
{{/supports_retry}}

