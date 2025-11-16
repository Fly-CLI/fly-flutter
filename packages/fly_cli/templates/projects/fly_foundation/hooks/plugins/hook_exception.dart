/// Custom exception for hook errors
class HookException implements Exception {
  final String message;

  const HookException(this.message);

  @override
  String toString() => 'HookException: $message';
}

