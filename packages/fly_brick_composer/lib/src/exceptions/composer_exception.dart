/// Custom exception for composer errors
class ComposerException implements Exception {
  final String message;

  const ComposerException(this.message);

  @override
  String toString() => 'ComposerException: $message';
}

