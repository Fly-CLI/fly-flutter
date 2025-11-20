/// Custom exception for planning errors
class PlanningException implements Exception {
  final String message;

  const PlanningException(this.message);

  @override
  String toString() => 'PlanningException: $message';
}

