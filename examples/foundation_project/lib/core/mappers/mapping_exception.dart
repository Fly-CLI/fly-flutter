/// Exception thrown when mapping operations fail
class MappingException implements Exception {
  final String message;
  final Object? originalError;

  const MappingException(this.message, [this.originalError]);

  @override
  String toString() => 'MappingException: $message';
}

