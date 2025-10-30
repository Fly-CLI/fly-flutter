/// Result of compatibility checking
sealed class CompatibilityResult {
  const CompatibilityResult();
  
  const factory CompatibilityResult.compatible({
    List<String> warnings,
  }) = Compatible;
  
  const factory CompatibilityResult.incompatible({
    required List<String> errors,
    List<String> warnings,
  }) = Incompatible;

  /// Check if the result indicates compatibility
  bool get isCompatible => this is Compatible;

  /// Check if the result indicates incompatibility
  bool get isIncompatible => this is Incompatible;

  /// Get all errors (empty if compatible)
  List<String> get errors;

  /// Get all warnings
  List<String> get warnings;
}

/// Indicates that the template is compatible
class Compatible extends CompatibilityResult {
  const Compatible({this.warnings = const []});

  @override
  List<String> get errors => const [];

  @override
  final List<String> warnings;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Compatible &&
          runtimeType == other.runtimeType &&
          warnings == other.warnings;

  @override
  int get hashCode => warnings.hashCode;

  @override
  String toString() => 'Compatible(warnings: ${warnings.length})';
}

/// Indicates that the template is incompatible
class Incompatible extends CompatibilityResult {
  const Incompatible({
    required this.errors,
    this.warnings = const [],
  });

  @override
  final List<String> errors;

  @override
  final List<String> warnings;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Incompatible &&
          runtimeType == other.runtimeType &&
          errors == other.errors &&
          warnings == other.warnings;

  @override
  int get hashCode => Object.hash(errors, warnings);

  @override
  String toString() =>
      'Incompatible(errors: ${errors.length}, warnings: ${warnings.length})';
}


