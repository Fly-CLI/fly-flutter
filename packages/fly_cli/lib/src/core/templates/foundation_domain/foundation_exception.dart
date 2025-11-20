/// Exception for foundation domain errors.
class FoundationDomainException implements Exception {
  const FoundationDomainException(this.message);

  final String message;

  @override
  String toString() => 'FoundationDomainException: $message';
}


